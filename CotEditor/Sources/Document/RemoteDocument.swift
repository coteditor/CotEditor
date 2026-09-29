//
//  RemoteDocument.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-09-28.
//
//  ---------------------------------------------------------------------------
//
//  © 2026 1024jp
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  https://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import AppKit
import Synchronization
import OSLog
import UniformTypeIdentifiers
import Defaults
import RMate

/// A text document associated with an `rmate` connection.
@Observable final class RemoteDocument: Document {
    
    // MARK: Enums
    
    private enum SerializationKey {
        
        static let remoteMetadata = "remoteMetadata"
    }
    
    
    // MARK: Public Properties
    
    var remoteState: RemoteDocumentState? {
        
        didSet {
            self.hasRemoteState.withLock { $0 = self.remoteState != nil }
            self.remoteState?.document = self
            self.invalidateRestorableState()
            if oldValue != nil, self.remoteState == nil {
                self.windowController?.window?.subtitle = ""
            }
            self.windowController?.synchronizeWindowTitleWithDocumentName()
        }
    }
    
    
    // MARK: Private Properties
    
    private let hasRemoteState: Mutex<Bool> = .init(false)  // presence check for background save callbacks
    private var pendingCloseContexts: [DelegateContext] = []
    
    
    // MARK: Lifecycle
    
    override init() {
        
        super.init()
        
        NotificationCenter.default.addObserver(self, selector: #selector(prepareForTermination),
                                               name: NSApplication.willTerminateNotification, object: nil)
    }
    
    
    /// Restores a remote document from its working copy or autosaved contents.
    ///
    /// - Parameters:
    ///   - url: The original working copy URL.
    ///   - contentsURL: The URL containing the document content to restore.
    ///   - typeName: The document type.
    /// - Throws: An error if reading the document or its metadata fails.
    convenience init(restoring url: URL, withContentsOf contentsURL: URL, ofType typeName: String) throws {
        
        // [caution] This method may be called from a background thread during restoration.
        
        let metadata = try RemoteEditingController.fileStore.metadata(for: url)
        
        try self.init(for: url, withContentsOf: contentsURL, ofType: typeName)
        
        // read(from:ofType:) receives the contents URL before AppKit sets the original file URL.
        if let metadata {
            DispatchQueue.syncOnMain {
                self.remoteState = RemoteDocumentState(file: RMateFile(metadata: metadata))
            }
        }
    }
    
    
    // MARK: Document Methods
    
    override static var readableTypes: [String] {
        
        // use the types registered for Document in Info.plist
        Document.readableTypes
    }
    
    
    override static var writableTypes: [String] {
        
        Document.writableTypes
    }
    
    
    override static func isNativeType(_ type: String) -> Bool {
        
        Document.isNativeType(type)
    }
    
    
    override func encodeRestorableState(with coder: NSCoder, backgroundQueue queue: OperationQueue) {
        
        super.encodeRestorableState(with: coder, backgroundQueue: queue)
        
        if let remoteState, let data = try? JSONEncoder().encode(remoteState.file.metadata) {
            coder.encode(data, forKey: SerializationKey.remoteMetadata)
        }
    }
    
    
    override func restoreState(with coder: NSCoder) {
        
        super.restoreState(with: coder)
        
        if let data = coder.decodeObject(of: NSData.self, forKey: SerializationKey.remoteMetadata) as? Data,
           let metadata = try? JSONDecoder().decode(RMateFile.Metadata.self, from: data)
        {
            self.remoteState = RemoteDocumentState(file: RMateFile(metadata: metadata))
        }
    }
    
    
    override var displayName: String! {
        
        get { self.remoteState?.file.metadata.displayName ?? super.displayName }
        set { super.displayName = newValue }
    }
    
    
    override func copyPath(_ sender: Any?) {
        
        guard let remoteState else { return super.copyPath(sender) }
        
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(remoteState.file.metadata.path, forType: .string)
    }
    
    
    override nonisolated func read(from url: URL, ofType typeName: String) throws {
        
        let metadata = try RemoteEditingController.fileStore.metadata(for: self.fileURL ?? url)
        
        try super.read(from: url, ofType: typeName)
        
        if let metadata {
            DispatchQueue.syncOnMain {
                if self.remoteState == nil {
                    self.remoteState = RemoteDocumentState(file: RMateFile(metadata: metadata))
                }
            }
        }
    }
    
    
    override func autosave(withImplicitCancellability autosavingIsImplicitlyCancellable: Bool, completionHandler: @escaping (any Error?) -> Void) {
        
        // keep a recovery copy without clearing unsent changes after disconnection
        if let remoteState, !remoteState.file.isConnected {
            if self.isDocumentEdited {
                remoteState.presentDisconnectAlert()
            }
            
            guard self.hasUnautosavedChanges, let fileURL, let fileType else {
                return completionHandler(nil)
            }
            
            self.save(to: self.autosavedContentsFileURL ?? fileURL, ofType: fileType,
                      for: .autosaveElsewhereOperation, completionHandler: completionHandler)
            return
        }
        
        super.autosave(withImplicitCancellability: autosavingIsImplicitlyCancellable, completionHandler: completionHandler)
    }
    
    
    override func save(to url: URL, ofType typeName: String, for saveOperation: NSDocument.SaveOperationType, completionHandler: @escaping (any Error?) -> Void) {
        
        // check whether the remote file can receive changes
        guard self.remoteState?.isSaving != true else { return completionHandler(CocoaError(.userCancelled)) }
        
        let remoteState = saveOperation.sendsToRemoteFile ? self.remoteState : nil
        if let remoteState, !remoteState.file.isConnected {
            remoteState.presentDisconnectAlert(explicitly: saveOperation == .saveOperation)
            return completionHandler(CocoaError(.userCancelled))
        }
        
        let previousBackingFileURL = self.remoteState != nil && saveOperation == .saveAsOperation ? self.fileURL : nil
        
        super.save(to: url, ofType: typeName, for: saveOperation) { [self] error in
            if error == nil, saveOperation == .saveAsOperation {
                let removesWorkingCopy = previousBackingFileURL?.standardizedFileURL != self.fileURL?.standardizedFileURL
                self.detachRemoteFile(removingBackingFileAt: removesWorkingCopy ? previousBackingFileURL : nil)
            }
            completionHandler(error)
            
            // resume closing only after AppKit has completed its save activity
            let contexts = self.pendingCloseContexts
            self.pendingCloseContexts.removeAll()
            for context in contexts {
                if error != nil {
                    context.perform(from: self, flag: false)
                } else if let delegate = context.delegate {
                    self.canClose(withDelegate: delegate, shouldClose: context.selector, contextInfo: context.contextInfo)
                }
            }
        }
    }
    
    
    override func saveFile(to url: URL, ofType typeName: String, for saveOperation: NSDocument.SaveOperationType, completionHandler: @escaping (any Error?) -> Void) {
        
        let remoteState = saveOperation.sendsToRemoteFile ? self.remoteState : nil
        remoteState?.beginSaving()
        
        // use Save To for the recovery copy and register it as an autosave after writing
        // -> AppKit fails to preserve the previous version of a new elsewhere-autosave file with autosavesInPlace.
        let isRemoteBackup = self.remoteState != nil && saveOperation == .autosaveElsewhereOperation
        let backupChangeToken = isRemoteBackup ? self.changeCountToken(for: .autosaveElsewhereOperation) : nil
        
        super.saveFile(to: url, ofType: typeName, for: isRemoteBackup ? .saveToOperation : saveOperation) { [self] error in
            if error != nil {
                remoteState?.cancelSaving()
                return completionHandler(error)
            }
            if let backupChangeToken {
                self.autosavedContentsFileURL = url
                self.updateChangeCount(withToken: backupChangeToken, for: .autosaveElsewhereOperation)
                self.invalidateRestorableState()
            }
            completionHandler(nil)
        }
    }
    
    
    override func finishSaving(data: Data?, for operation: NSDocument.SaveOperationType, completionHandler: @escaping (any Error?) -> Void) {
        
        guard operation.sendsToRemoteFile, let remoteState, let data else {
            return super.finishSaving(data: data, for: operation, completionHandler: completionHandler)
        }
        
        Task {
            do {
                try await remoteState.send(data, for: operation)
                super.finishSaving(data: data, for: operation, completionHandler: completionHandler)
            } catch {
                completionHandler(error)
            }
        }
    }
    
    
    override func runModalSavePanel(for saveOperation: NSDocument.SaveOperationType, delegate: Any?, didSave didSaveSelector: Selector?, contextInfo: UnsafeMutableRawPointer?) {
        
        // the standard Save As panel can try saving to the disconnected remote file first
        if self.remoteState != nil, saveOperation == .saveAsOperation {
            let context = DelegateContext(delegate: delegate, selector: didSaveSelector, contextInfo: contextInfo)
            self.runRemoteSavePanel { succeeded in
                context.perform(from: self, flag: succeeded)
            }
            return
        }
        
        super.runModalSavePanel(for: saveOperation, delegate: delegate, didSave: didSaveSelector, contextInfo: contextInfo)
    }
    
    
    override func canClose(withDelegate delegate: Any, shouldClose shouldCloseSelector: Selector?, contextInfo: UnsafeMutableRawPointer?) {
        
        // AppKit's synchronous save wait would block the MainActor task that sends the remote content.
        if self.remoteState?.isSaving == true {
            self.pendingCloseContexts.append(DelegateContext(delegate: delegate, selector: shouldCloseSelector, contextInfo: contextInfo))
            return
        }
        
        if let remoteState, !remoteState.file.isConnected, self.isDocumentEdited {
            return self.canCloseRemoteDocument(context: DelegateContext(delegate: delegate, selector: shouldCloseSelector, contextInfo: contextInfo))
        }
        
        super.canClose(withDelegate: delegate, shouldClose: shouldCloseSelector, contextInfo: contextInfo)
    }
    
    
    override func close() {
        
        // AppKit can close documents before posting the termination notification.
        let keepsWorkingCopy = self.restoresAfterTermination
        
        NotificationCenter.default.removeObserver(self, name: NSApplication.willTerminateNotification, object: nil)
        
        super.close()
        
        self.detachRemoteFile(removingBackingFileAt: keepsWorkingCopy ? nil : self.fileURL)
    }
    
    
    override var printingDocumentInfo: PrintTextView.DocumentInfo {
        
        var info = super.printingDocumentInfo
        if let remoteState {
            info.filePath = remoteState.file.metadata.path
            info.lastModifiedDate = nil
        }
        return info
    }
    
    
    override func updateChangeCount(withToken changeCountToken: Any, for saveOperation: NSDocument.SaveOperationType) {
        
        // [caution] AppKit can call this method from a background thread in async-saving.
        
        // keep the document edited until the matching snapshot has been sent
        if saveOperation.sendsToRemoteFile,
           self.hasRemoteState.withLock(\.self),
           DispatchQueue.syncOnMain(execute: {
               self.remoteState?.deferChangeCountUpdate(withToken: changeCountToken) == true
           })
        {
            return
        }
        
        super.updateChangeCount(withToken: changeCountToken, for: saveOperation)
    }
    
    
    override func validateUserInterfaceItem(_ item: any NSValidatedUserInterfaceItem) -> Bool {
        
        if self.remoteState != nil {
            switch item.action {
                case #selector(move(_:)),
                     #selector(rename(_:)),
                     #selector(browseVersions(_:)),
                     #selector(revertToSaved(_:)),
                     #selector(showInFinder(_:)):
                    return false
                default: break
            }
        }
        
        return super.validateUserInterfaceItem(item)
    }
    
    
    // MARK: Private Methods
    
    /// Excludes remote documents without unsent disconnected changes from restoration after normal termination.
    ///
    /// - Parameter notification: The application termination notification.
    @objc private func prepareForTermination(_ notification: Notification) {
        
        guard self.remoteState != nil, !self.restoresAfterTermination else { return }
        
        for controller in self.windowControllers {
            controller.window?.isRestorable = false
        }
        self.close()
    }
    
    
    /// Whether unsent changes should remain available after normal termination.
    private var restoresAfterTermination: Bool {
        
        UserDefaults.standard[.quitAlwaysKeepsWindows] &&
            self.remoteState?.file.isConnected == false && self.isDocumentEdited
    }
    
    
    /// Detaches the remote file and removes its working copy unless it is still needed.
    ///
    /// - Parameter url: The working copy to remove, or `nil` to keep it for restoration or local editing.
    private func detachRemoteFile(removingBackingFileAt url: URL?) {
        
        guard let remoteState else { return }
        
        remoteState.file.close()
        // clear the state because AppKit can reenter close() while closing the last window
        self.remoteState = nil
        
        guard let url else { return }
        
        do {
            try RemoteEditingController.fileStore.removeBackingFile(at: url)
        } catch {
            Logger.app.error("Failed deleting remote working copy: \(error)")
        }
    }
    
    
    /// Presents a Save As panel for a remote document.
    ///
    /// - Parameter completionHandler: The handler called with whether saving succeeded.
    private func runRemoteSavePanel(completionHandler: @escaping (Bool) -> Void) {
        
        let finish: (Bool) -> Void = { succeeded in
            self.invalidateSaveOptions()
            completionHandler(succeeded)
        }
        
        guard let remoteState, let window = self.windowForSheet, let fileType else { return finish(false) }
        
        let panel = NSSavePanel()
        panel.nameFieldStringValue = (remoteState.file.metadata.path as NSString).lastPathComponent
        panel.allowedContentTypes = [UTType(fileType) ?? .plainText]
        
        guard self.prepareSavePanel(panel) else { return finish(false) }
        
        panel.beginSheetModal(for: window) { response in
            guard response == .OK, let url = panel.url else { return finish(false) }
            
            self.save(to: url, ofType: fileType, for: .saveAsOperation) { error in
                if let error {
                    self.presentErrorAsSheet(error)
                }
                finish(error == nil)
            }
        }
    }
    
    
    /// Asks whether to save unsent changes before closing the document.
    ///
    /// - Parameter context: The document close callback.
    private func canCloseRemoteDocument(context: DelegateContext) {
        
        guard let window = self.windowForSheet else { return context.perform(from: self, flag: false) }
        
        let alert = NSAlert()
        alert.messageText = String(localized: "RemoteDocumentClosingAlert.messageText",
                                   defaultValue: "Save the changes to “\(self.displayName!)” on this Mac?")
        alert.informativeText = String(localized: "RemoteDocumentClosingAlert.informativeText",
                                       defaultValue: "The remote connection is disconnected. Your changes have not been sent.")
        alert.addButton(withTitle: String(localized: "Action.saveAs.label",
                                          defaultValue: "Save As…"))
        alert.addButton(withTitle: String(localized: .cancel))
        alert.addButton(withTitle: String(localized: "RemoteDocumentClosingAlert.button.dontSave",
                                          defaultValue: "Don’t Save",
                                          comment: "verb; button; Refer the same expression in AppKit.framework by Apple."))
        alert.buttons[2].hasDestructiveAction = true
        
        alert.beginSheetModal(for: window) { response in
            switch response {
                case .alertFirstButtonReturn:
                    self.runRemoteSavePanel { succeeded in
                        context.perform(from: self, flag: succeeded && self.remoteState == nil)
                    }
                    
                case .alertThirdButtonReturn:
                    self.updateChangeCount(.changeCleared)
                    context.perform(from: self, flag: true)
                    
                default:
                    context.perform(from: self, flag: false)
            }
        }
    }
}


private extension NSDocument.SaveOperationType {
    
    /// Whether the save operation sends changes to the associated remote file.
    var sendsToRemoteFile: Bool {
        
        switch self {
            case .saveOperation, .autosaveInPlaceOperation:
                true
            default:
                false
        }
    }
}
