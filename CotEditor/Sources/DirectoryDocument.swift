//
//  DirectoryDocument.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-05-01.
//
//  ---------------------------------------------------------------------------
//
//  © 2024 1024jp
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
import UniformTypeIdentifiers
import OSLog
import URLUtils

final class DirectoryDocument: NSDocument {
    
    nonisolated static let didUpdateFileNodeNotification = Notification.Name("DirectoryDocument.didUpdateFileNodeNotification")
    
    
    private enum SerializationKey {
        
        static let documents = "documents"
    }
    
    
    // MARK: Public Properties
    
    private(set) var fileNode: FileNode?
    private(set) weak var currentDocument: Document?
    
    
    // MARK: Private Properties
    
    private var documents: [Document] = []
    private var windowController: DocumentWindowController?  { self.windowControllers.first as? DocumentWindowController }
    
    private var documentObserver: (any NSObjectProtocol)?
    
    
    
    // MARK: Document Methods
    
    override static var autosavesInPlace: Bool {
        
        true  // for moving location from the proxy icon
    }
    
    
    override func encodeRestorableState(with coder: NSCoder, backgroundQueue queue: OperationQueue) {
        
        super.encodeRestorableState(with: coder, backgroundQueue: queue)
        
        let fileData = self.documents
            .compactMap(\.fileURL)
            .compactMap { try? $0.bookmarkData(options: .withSecurityScope) }
        coder.encode(fileData, forKey: SerializationKey.documents)
    }
    
    
    override func restoreState(with coder: NSCoder) {
        
        super.restoreState(with: coder)
        
        if let fileURL, let fileData = coder.decodeArrayOfObjects(ofClass: NSData.self, forKey: SerializationKey.documents) as? [Data] {
            let urls = fileData.compactMap {
                var isStale = false
                return try? URL(resolvingBookmarkData: $0, options: .withSecurityScope, bookmarkDataIsStale: &isStale)
            }
            Task {
                for url in urls where url.isReachable && fileURL.isAncestor(of: url) {
                    await self.openDocument(at: url)
                }
            }
        }
    }
    
    
    override func makeWindowControllers() {
        
        self.addWindowController(DocumentWindowController(directoryDocument: self))
        
        // observe document updates for the edited marker in the close button
        if self.documentObserver == nil {
            self.documentObserver = NotificationCenter.default.addObserver(forName: Document.didUpdateChange, object: nil, queue: .main) { [unowned self] _ in
                MainActor.assumeIsolated {
                    let hasEditedDocuments = self.documents.contains { $0.isDocumentEdited }
                    self.windowController?.setDocumentEdited(hasEditedDocuments)
                }
            }
        }
    }
    
    
    override nonisolated func read(from url: URL, ofType typeName: String) throws {
        
        assert(url == self.fileURL)
        
        try MainActor.assumeIsolated {
            self.fileNode = try FileNode(at: url)
            self.windowController?.synchronizeWindowTitleWithDocumentName()
        }
    }
    
    
    override func data(ofType typeName: String) throws -> Data {
        
        fatalError("\(self.className) is readonly")
    }
    
    
    override func move(to url: URL) async throws {
        
        try await super.move(to: url)
        
        // remake node tree
        self.fileNode?.move(to: url)
        self.notifyNodeUpdate()
    }
    
    
    override func revert(toContentsOf url: URL, ofType typeName: String) throws {
        
        try super.revert(toContentsOf: url, ofType: typeName)
        
        self.notifyNodeUpdate()
    }
    
    
    override func shouldCloseWindowController(_ windowController: NSWindowController, delegate: Any?, shouldClose shouldCloseSelector: Selector?, contextInfo: UnsafeMutableRawPointer?) {
        
        Task {
            // save unsaved changes in the file documents before closing
            var canClose = true
            for document in self.documents where document.isDocumentEdited {
                // ask to the user one-by-one
                guard await document.canClose() else {
                    canClose = false
                    break
                }
            }
            
            DelegateContext(delegate: delegate, selector: shouldCloseSelector, contextInfo: contextInfo).perform(from: self, flag: canClose)
        }
    }
    
    
    override func close() {
        
        super.close()
        
        for document in self.documents {
            document.close()
        }
        
        if let documentObserver {
            NotificationCenter.default.removeObserver(documentObserver)
        }
    }
    
    
    // MARK: File Presenter Methods
    
    override nonisolated func presentedSubitemDidChange(at url: URL) {
        
        // the following APIs are not called correctly:
        // - subitem moved (presentedSubitem(at:didMoveTo:))
        // - new subitem added (presentedSubitemDidAppear(at:))
        
        // remake node tree if needed
        Task { @MainActor in
            guard self.fileNode?.invalidateChildren(at: url) == true else { return }
            
            self.notifyNodeUpdate()
        }
    }
    
    
    override nonisolated func presentedItemDidMove(to newURL: URL) {
        
        super.presentedItemDidMove(to: newURL)
        
        // remake fileURLs with the new location
        Task { @MainActor in
            self.fileNode?.move(to: newURL)
            self.notifyNodeUpdate()
        }
    }
    
    
    
    // MARK: Public Methods
    
    /// Opens a document as a member.
    ///
    /// - Parameter fileURL: The file URL of the document to open.
    /// - Returns: Return `true` if the document of the given file did successfully open.
    @discardableResult func openDocument(at fileURL: URL) async -> Bool {
        
        assert(!fileURL.hasDirectoryPath)
        
        guard fileURL != self.currentDocument?.fileURL else { return true }  // already open
        
        // existing document
        if let document = NSDocumentController.shared.document(for: fileURL) as? Document {
            if self.documents.contains(document) {
                self.changeFrontmostDocument(to: document)
                return true
                
            } else {
                return await withCheckedContinuation { continuation in
                    self.presentErrorAsSheet(DirectoryDocumentError.alreadyOpen(fileURL)) { _ in
                        document.showWindows()
                        continuation.resume(returning: false)
                    }
                }
            }
        }
        
        let contentType = try? fileURL.resourceValues(forKeys: [.contentTypeKey]).contentType
        
        // ignore (possibly) unsupported files
        guard contentType?.conforms(to: .text) == true || fileURL.pathExtension.isEmpty,
              fileURL.lastPathComponent != ".DS_Store"
        else { return true }
        
        // make document
        let document: NSDocument
        do {
            document = try NSDocumentController.shared.makeDocument(withContentsOf: fileURL, ofType: (contentType ?? .data).identifier)
        } catch {
            self.presentErrorAsSheet(error)
            return false
        }
        
        guard let document = document as? Document else { return false }
        
        self.documents.append(document)
        NSDocumentController.shared.addDocument(document)
        
        self.changeFrontmostDocument(to: document)
        
        return true
    }
    
    
    /// Creates a empty file in the given file node.
    ///
    /// - Parameter parentNode: The file node where creates a new file.
    /// - Returns: The file node created.
    @discardableResult func addFile(at parentNode: FileNode) throws -> FileNode {
        
        assert(parentNode.isDirectory)
        
        let name = String(localized: "Untitled", comment: "default file name for new creation")
        let pathExtension = (try? SyntaxManager.shared.setting(name: UserDefaults.standard[.syntax]))?.extensions.first
        let fileURL = parentNode.fileURL.appending(component: name).appendingPathExtension(pathExtension ?? "").appendingUniqueNumber()
        
        var coordinationError: NSError?
        var writingError: (any Error)?
        let coordinator = NSFileCoordinator(filePresenter: self)
        coordinator.coordinate(writingItemAt: fileURL, error: &coordinationError) { newURL in
            do {
                try Data().write(to: newURL, options: .withoutOverwriting)
            } catch {
                writingError = error
            }
        }
        
        if let error = coordinationError ?? writingError {
            throw error
        }
        
        let node = FileNode(at: fileURL, isDirectory: false, parent: parentNode)
        parentNode.addNode(node)
        
        return node
    }
    
    
    /// Creates a folder at the same level in the given file node.
    ///
    /// - Parameter parentNode: The file node where creates a new file.
    /// - Returns: The file node created.
    @discardableResult func addFolder(at parentNode: FileNode) throws -> FileNode {
        
        assert(parentNode.isDirectory)
        
        let name = String(localized: "untitled folder", comment: "default folder name for new creation")
        let folderURL = parentNode.fileURL.appending(component: name).appendingUniqueNumber()
        
        var coordinationError: NSError?
        var writingError: (any Error)?
        let coordinator = NSFileCoordinator(filePresenter: self)
        coordinator.coordinate(writingItemAt: folderURL, error: &coordinationError) { newURL in
            do {
                try FileManager.default.createDirectory(at: newURL, withIntermediateDirectories: true)
            } catch {
                writingError = error
            }
        }
        
        if let error = coordinationError ?? writingError {
            throw error
        }
        
        let node = FileNode(at: folderURL, isDirectory: true, parent: parentNode)
        parentNode.addNode(node)
        
        return node
    }
    
    
    /// Renames the file at the given `fileURL` with a new name.
    ///
    /// - Parameters:
    ///   - node: The file node to rename.
    ///   - name: The new file name.
    func renameItem(at node: FileNode, with name: String) throws {
        
        // validate new name
        guard !name.isEmpty else {
            throw InvalidNameError.empty
        }
        guard !name.contains("/") else {
            throw InvalidNameError.invalidCharacter("/")
        }
        guard !name.contains(":") else {
            throw InvalidNameError.invalidCharacter(":")
        }
        
        let newURL = node.fileURL.deletingLastPathComponent().appending(component: name)
        
        do {
            try self.moveItem(from: node.fileURL, to: newURL)
        } catch let error as CocoaError where error.errorCode == CocoaError.fileWriteFileExists.rawValue {
            throw InvalidNameError.duplicated(name: name)
        } catch {
            throw error
        }
        
        node.rename(with: name)
    }
    
    
    /// Move the file to a new destination inside the directory.
    ///
    /// - Note: This method doesn't update the file node.
    ///
    /// - Parameters:
    ///   - sourceURL: The current file URL.
    ///   - destinationURL: The destination.
    private func moveItem(from sourceURL: URL, to destinationURL: URL) throws {
        
        var coordinationError: NSError?
        var movingError: (any Error)?
        let coordinator = NSFileCoordinator(filePresenter: self)
        coordinator.coordinate(writingItemAt: sourceURL, options: .forMoving, writingItemAt: destinationURL, options: .forMoving, error: &coordinationError) { (newSourceURL, newDestinationURL) in
            do {
                try FileManager.default.moveItem(at: newSourceURL, to: newDestinationURL)
            } catch {
                movingError = error
            }
        }
        
        if let error = coordinationError ?? movingError {
            throw error
        }
    }
    
    
    /// Properly moves the item to the trash.
    ///
    /// - Parameters:
    ///   - node: The file node to move to trash.
    func trashItem(_ node: FileNode) throws {
        
        // close if the item to trash is opened as a document
        if let document = self.documents.first(where: { $0.fileURL == node.fileURL }) {
            if document == self.currentDocument {
                self.windowController?.fileDocument = nil
            }
            self.documents.removeFirst(document)
            document.close()
            self.invalidateRestorableState()
        }
        
        var trashedURL: NSURL?
        var coordinationError: NSError?
        var trashError: (any Error)?
        NSFileCoordinator(filePresenter: self).coordinate(writingItemAt: node.fileURL, options: .forDeleting, error: &coordinationError) { newURL in
            do {
                try FileManager.default.trashItem(at: newURL, resultingItemURL: &trashedURL)
            } catch {
                trashError = error
            }
        }
        
        if let error = coordinationError ?? trashError {
            throw error
        }
        
        guard trashedURL != nil else {
            assertionFailure("This guard should success.")
            throw CocoaError(.fileWriteUnknown)
        }
        
        node.delete()
    }
    
    
    /// Open the document at a given fileURL in a new window.
    ///
    /// - Parameter fileURL: The fileURL to open.
    func openInWindow(fileURL: URL) {
        
        if let document = self.currentDocument, fileURL == document.fileURL {
            // remove from the current window
            self.windowController?.fileDocument = nil
            self.documents.removeFirst(document)
            self.invalidateRestorableState()
            
            // create a new window for the document
            document.windowController = nil
            document.makeWindowControllers()
            document.showWindows()
            
        } else {
            NSDocumentController.shared.openDocument(withContentsOf: fileURL, display: true) { (_, _, error) in
                if let error {
                    return self.presentErrorAsSheet(error)
                }
            }
        }
    }
    
    
    
    // MARK: Private Methods
    
    /// Notifies file node update.
    private func notifyNodeUpdate() {
        
        NotificationCenter.default.post(name: Self.didUpdateFileNodeNotification, object: self)
    }
    
    
    /// Changes the frontmost document.
    ///
    /// - Parameter document: The document to bring frontmost.
    private func changeFrontmostDocument(to document: Document) {
        
        assert(self.documents.contains(document))
        
        // remove window controller from current document
        self.windowController?.fileDocument?.windowController = nil
        
        document.windowController = self.windowController
        self.windowController?.fileDocument = document
        self.currentDocument = document
        document.makeWindowControllers()
        
        // clean-up
        self.disposeUnusedDocuments()
    }
    
    
    /// Disposes unused documents.
    private func disposeUnusedDocuments() {
        
        // -> postpone closing opened document if edited
        for document in self.documents where !document.isDocumentEdited && document != self.currentDocument {
            document.close()
            self.documents.removeFirst(document)
        }
        self.invalidateRestorableState()
    }
}


private enum DirectoryDocumentError: LocalizedError {
    
    case alreadyOpen(URL)
    
    
    var errorDescription: String? {
        
        switch self {
            case .alreadyOpen(let fileURL):
                String(localized: "DirectoryDocumentError.alreadyOpen.description",
                       defaultValue: "The file “\(fileURL.lastPathComponent)” is already open in a different window.")
                
        }
    }
    
    
    var recoverySuggestion: String? {
        
        switch self {
            case .alreadyOpen:
                String(localized: "DirectoryDocumentError.alreadyOpen.recoverySuggestion",
                       defaultValue: "To open it in this window, close the existing window first.",
                       comment: "“it” is the file in description.")
        }
    }
}
