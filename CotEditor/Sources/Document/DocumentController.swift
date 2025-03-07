//
//  DocumentController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by nakamuxu on 2004-12-14.
//
//  ---------------------------------------------------------------------------
//
//  © 2004-2007 nakamuxu
//  © 2014-2025 1024jp
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
import Combine
import SwiftUI
import UniformTypeIdentifiers
import Defaults

protocol AdditionalDocumentPreparing: NSDocument {
    
    func didMakeDocumentForExistingFile(url: URL)
}


struct OpenOptions {
    
    var encoding: String.Encoding?
    var isReadOnly = false
}


final class DocumentController: NSDocumentController {
    
    // MARK: Public Properties
    
    @Published private(set) var currentSyntaxName: String?
    private(set) var openOptions: OpenOptions?
    
    
    // MARK: Private Properties
    
    private let transientDocumentLock = NSLock()
    private var deferredDocuments: [NSDocument] = []
    
    private var mainWindowObserver: AnyCancellable?
    private var syntaxObserver: AnyCancellable?
    
    
    // MARK: Lifecycle
    
    override init() {
        
        super.init()
        
        self.autosavingDelay = 5.0
        
        // observe the frontmost syntax change
        self.mainWindowObserver = NSApp.publisher(for: \.mainWindow)
            .debounce(for: .seconds(0.1), scheduler: RunLoop.main)
            .map { $0?.windowController as? DocumentWindowController }
            .map { $0?.fileDocument as? Document }
            .sink { [unowned self] in
                self.currentSyntaxName = $0?.syntaxParser.name
                self.syntaxObserver = $0?.didChangeSyntax
                    .sink { self.currentSyntaxName = $0 }
            }
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: Document Controller Methods
    
    override func openDocument(withContentsOf url: URL, display displayDocument: Bool) async throws -> (NSDocument, Bool) {
        
        // do nothing for DirectoryDocument
        if url.hasDirectoryPath {
            return try await super.openDocument(withContentsOf: url, display: displayDocument)
        }
        
        // obtain transient document if exists
        let transientDocument: Document? = self.transientDocumentLock.withLock { [unowned self] in
            guard
                let document = self.transientDocument,
                document.windowForSheet?.attachedSheet == nil
            else { return nil }
            
            document.isTransient = false
            self.deferredDocuments.removeAll()
            return document
        }
        
        let (document, documentWasAlreadyOpen) = try await super.openDocument(withContentsOf: url, display: false)
        
        // invalidate encoding that was set in the open panel
        self.openOptions = nil
        
        if let transientDocument, let document = document as? Document {
            self.replaceTransientDocument(transientDocument, with: document)
            if displayDocument {
                document.makeWindowControllers()
                document.showWindows()
            }
            
            // display all deferred documents since the transient document has been replaced
            for deferredDocument in self.deferredDocuments {
                deferredDocument.makeWindowControllers()
                deferredDocument.showWindows()
            }
            self.deferredDocuments.removeAll()
            
        } else if displayDocument {
            if self.deferredDocuments.isEmpty {
                // display the document immediately, because the transient document has been replaced
                document.makeWindowControllers()
                document.showWindows()
            } else {
                // defer displaying this document, because the transient document has not yet been replaced
                self.deferredDocuments.append(document)
            }
        }
        
        return (document, documentWasAlreadyOpen)
    }
    
    
    override func openUntitledDocumentAndDisplay(_ displayDocument: Bool) throws -> NSDocument {
        
        let document = try super.openUntitledDocumentAndDisplay(displayDocument)
        
        // make document transient when it is an open or reopen event
        if self.documents.count == 1, NSAppleEventManager.shared().isOpenEvent {
            (document as? Document)?.isTransient = true
        }
        
        return document
    }
    
    
    override func makeDocument(withContentsOf url: URL, ofType typeName: String) throws -> NSDocument {
        
        // [caution] This method may be called from a background thread due to concurrent-opening.
        
        do {
            try self.checkOpeningSafetyOfDocument(at: url, type: typeName)
        } catch {
            // ask user for opening file
            try DispatchQueue.syncOnMain {
                guard self.presentError(error) else { throw CocoaError(.userCancelled) }
            }
        }
        
        let document = try super.makeDocument(withContentsOf: url, ofType: typeName)
        
        (document as? any AdditionalDocumentPreparing)?.didMakeDocumentForExistingFile(url: url)
        
        return document
    }
    
    
    override func addDocument(_ document: NSDocument) {
        
        // clear the first document's transient status when a second document is added
        // -> This happens when the user selects "New" when a transient document already exists.
        self.transientDocument?.isTransient = false
        
        super.addDocument(document)
    }
    
    
    override func beginOpenPanel(_ openPanel: NSOpenPanel, forTypes inTypes: [String]?) async -> Int {
        
        let model = OpenPanelModel(fileEncodings: EncodingManager.shared.fileEncodings)
        let accessory = OpenPanelAccessory(model: model, openPanel: openPanel)
        let accessoryView = NSHostingView(rootView: accessory)
        accessoryView.sizingOptions = .intrinsicContentSize
        
        openPanel.delegate = model
        openPanel.canChooseDirectories = true
        openPanel.accessoryView = accessoryView
        openPanel.isAccessoryViewDisclosed = true
        
        let result = await super.beginOpenPanel(openPanel, forTypes: inTypes)
        
        if result == NSApplication.ModalResponse.OK.rawValue {
            self.openOptions = model.options
        }
        
        return result
    }
    
    
    override func closeAllDocuments(withDelegate delegate: Any?, didCloseAllSelector: Selector?, contextInfo: UnsafeMutableRawPointer?) {
        
        guard (NSApp.delegate as? AppDelegate)?.needsRelaunch == true else {
            return super.closeAllDocuments(withDelegate: delegate, didCloseAllSelector: didCloseAllSelector, contextInfo: contextInfo)
        }
        
        let context = DelegateContext(delegate: delegate, selector: didCloseAllSelector, contextInfo: contextInfo)
        
        super.closeAllDocuments(withDelegate: self, didCloseAllSelector: #selector(documentController(_:didCloseAll:contextInfo:)), contextInfo: bridgeWrapped(context))
    }
    
    
    override func openDocument(_ sender: Any?) {
        
        // be called on the open event when iCloud Drive is enabled (2024-05, macOS 14).
        // -> Otherwise, AppDelegate.applicationShouldOpenUntitledFile(_:) is called on launch.
        
        if NSAppleEventManager.shared().isOpenEvent {
            return self.performOnLaunchAction()
        }
        
        super.openDocument(sender)
    }
    
    
    override func noteNewRecentDocument(_ document: NSDocument) {
        
        guard !(document is PreviewDocument) else { return }
        
        super.noteNewRecentDocument(document)
    }
    
    
    override func validateUserInterfaceItem(_ item: any NSValidatedUserInterfaceItem) -> Bool {
        
        switch item.action {
            case #selector(newDocumentAsTab):
                return self.currentDocument is Document
            default:
                break
        }
        
        return super.validateUserInterfaceItem(item)
    }
    
    
    // MARK: Public Methods
    
    /// The current `Document`.
    var currentPlainTextDocument: Document? {
        
        switch self.currentDocument {
            case let document as Document:
                document
            case let document as DirectoryDocument:
                document.currentDocument as? Document
            default:
                nil
        }
    }
    
    
    /// Opens an untitled document with the given contents or recycles the transient document if available.
    ///
    /// - Parameters:
    ///   - contents: The text contents to fill in the created document.
    ///   - title: The document title to display in the window, or `nil` to leave it as untitled.
    ///   - displayDocument: `true` if the user interface for the document should be shown, otherwise `false`.
    /// - Returns: Returns the new Document object.
    @discardableResult
    func openUntitledDocument(contents: String, title: String? = nil, display displayDocument: Bool) throws -> Document {
        
        let document = try self.transientDocument ?? (try self.openUntitledDocumentAndDisplay(false) as! Document)
        
        document.textStorage.replaceContent(with: contents)
        document.updateChangeCount(.changeDone)
        
        if displayDocument {
            document.makeWindowControllers()
            document.showWindows()
        }
        
        if let title {
            document.displayName = title
            document.windowControllers
                .forEach { $0.synchronizeWindowTitleWithDocumentName() }
        }
        
        return document
    }
    
    
    /// Performs the user-defined action on the open/reopen event.
    ///
    /// - Parameter isReopen: Flag to tell whether the event is the reopen event (not affected to the behavior).
    func performOnLaunchAction(isReopen: Bool = false) {
        
        switch UserDefaults.standard[.noDocumentOnLaunchOption] {
            case .untitledDocument:
                self.newDocument(nil)
            case .openPanel:
                // invoke super to avoid infinite loop
                super.openDocument(nil)
            case .none:
                break
        }
    }
    
    
    // MARK: Action Messages
    
    /// Opens a new document as a new window.
    @IBAction func newDocumentAsWindow(_ sender: Any?) {
        
        DocumentWindow.tabbingPreference = .manual
        self.newDocument(sender)
        DocumentWindow.tabbingPreference = nil
    }
    
    
    /// Opens a new document as a tab in the existing frontmost window.
    @IBAction func newDocumentAsTab(_ sender: Any?) {
        
        DocumentWindow.tabbingPreference = .always
        self.newDocument(sender)
        DocumentWindow.tabbingPreference = nil
    }
    
    
    // MARK: Private Methods
    
    /// Transient document to be replaced or `nil`.
    private var transientDocument: Document? {
        
        guard
            self.documents.count == 1,
            let document = self.documents.first as? Document,
            document.isTransient
        else { return nil }
        
        assert(document.textStorage.length == 0)
        
        return document
    }
    
    
    /// Replaces window controllers in documents.
    ///
    /// - Parameters:
    ///   - transientDocument: The transient document to be replaced.
    ///   - document: The new document to replace.
    private func replaceTransientDocument(_ transientDocument: Document, with document: Document) {
        
        for controller in transientDocument.windowControllers {
            document.addWindowController(controller)
            transientDocument.removeWindowController(controller)
        }
        transientDocument.close()
        
        // notify accessibility clients about the value replacement of the transient document with opened document
        document.textStorage.layoutManagers
            .flatMap(\.textContainers)
            .compactMap(\.textView)
            .forEach { NSAccessibility.post(element: $0, notification: .valueChanged) }
    }
    
    
    /// Checks file before creating a new document instance.
    ///
    /// - Parameters:
    ///   - url: The location of the new document object.
    ///   - typeName: The type of the document.
    private nonisolated func checkOpeningSafetyOfDocument(at url: URL, type typeName: String) throws(DocumentOpeningError) {
        
        // check if the file is possible binary
        if SyntaxManager.shared.settingName(documentName: url.lastPathComponent) == nil,
           let type = UTType(typeName),
           !type.isPlainText,
           [.image, .audiovisualContent, .archive].contains(where: type.conforms(to:))
        {
            throw DocumentOpeningError(.binaryFile(type: type), url: url)
        }
        
        // check if the file is enormously large
        let fileSizeThreshold = UserDefaults.standard[.largeFileAlertThreshold]
        if fileSizeThreshold > 0,
           let fileSize = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize,
           fileSize > fileSizeThreshold
        {
            throw DocumentOpeningError(.tooLarge(size: Int64(fileSize)), url: url)
        }
    }
    
    
    /// Callback from document after calling `closeAllDocuments(withDelegate:didCloseAllSelector:contextInfo)`.
    ///
    /// - Parameters:
    ///   - documentController: The sender.
    ///   - didCloseAll: The flag if the sender close all documents.
    ///   - contextInfo: The context info.
    @objc private func documentController(_ documentController: NSDocumentController, didCloseAll: Bool, contextInfo: UnsafeMutableRawPointer) {
        
        // cancel relaunching
        if !didCloseAll {
            (NSApp.delegate as? AppDelegate)?.needsRelaunch = false
        }
        
        // manually invoke the original delegate method
        guard let context: DelegateContext = bridgeUnwrapped(contextInfo) else { return assertionFailure() }
        
        context.perform(from: self, flag: didCloseAll)
    }
}


// MARK: - Error

private struct DocumentOpeningError: LocalizedError, RecoverableError {
    
    enum Code {
        
        case binaryFile(type: UTType)
        case tooLarge(size: Int64)
    }
    
    var code: Code
    var url: URL
    
    
    init(_ code: Code, url: URL) {
        
        self.code = code
        self.url = url
    }
    
    
    var errorDescription: String? {
        
        switch self.code {
            case .binaryFile:
                String(localized: "DocumentOpeningError.binaryFile.description",
                       defaultValue: "The file “\(self.url.lastPathComponent)” doesn’t appear to be text data.")
                
            case .tooLarge(let size):
                String(localized: "DocumentOpeningError.tooLarge.description",
                       defaultValue: "The file “\(self.url.lastPathComponent)” has a size of \(size, format: .byteCount(style: .file)).")
        }
    }
    
    
    var recoverySuggestion: String? {
        
        switch self.code {
            case .binaryFile(let type):
                let localizedTypeName = type.localizedDescription ?? String(
                    localized: "DocumentOpeningError.binaryFile.recoverySuggestion.unknownFileType",
                    defaultValue: "an unknown type",
                    comment: "string that is inserted as the variable (%@) in the binary file alert when the type of file cannot be determined"
                )
                return String(localized: "DocumentOpeningError.binaryFile.recoverySuggestion",
                              defaultValue: "The file appears to be \(localizedTypeName).\n\nDo you really want to open the file?",
                              comment: "%@ is a file type")
                
            case .tooLarge:
                return String(localized: "DocumentOpeningError.tooLarge.recoverySuggestion",
                              defaultValue: "Opening such a large file can make the application slow or unresponsive.\n\nDo you really want to open the file?")
        }
    }
    
    
    var recoveryOptions: [String] {
        
        [String(localized: "DocumentOpeningError.recoveryOption.open", defaultValue: "Open", comment: "button label"),
         String(localized: "Cancel")]
    }
    
    
    func attemptRecovery(optionIndex recoveryOptionIndex: Int) -> Bool {
        
        (recoveryOptionIndex == 0)
    }
}
