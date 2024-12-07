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
    
    private enum SerializationKey {
        
        static let documents = "documents"
    }
    
    
    // MARK: Public Properties
    
    private(set) var fileNode: FileNode?
    private(set) weak var currentDocument: DataDocument?
    
    weak var fileBrowserViewController: FileBrowserViewController?
    
    
    // MARK: Private Properties
    
    private var documents: [DataDocument] = []
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
        
        // restore opened documents
        if let fileURL, let fileData = coder.decodeArrayOfObjects(ofClass: NSData.self, forKey: SerializationKey.documents) as? [Data] {
            let urls = fileData
                .compactMap {
                    var isStale = false
                    return try? URL(resolvingBookmarkData: $0, options: .withSecurityScope, bookmarkDataIsStale: &isStale)
                }
                .filter(fileURL.isAncestor(of:))
                .filter(\.isReachable)
            
            if !urls.isEmpty {
                Task {
                    for url in urls {
                        await self.openDocument(at: url)
                    }
                    self.fileBrowserViewController?.selectCurrentDocument()
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
        self.notifyNodeUpdate(at: self.fileNode)
    }
    
    
    override func revert(toContentsOf url: URL, ofType typeName: String) throws {
        
        try super.revert(toContentsOf: url, ofType: typeName)
        
        self.notifyNodeUpdate(at: self.fileNode)
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
            guard let node = self.fileNode?.invalidateChildren(at: url) else { return }
            
            self.notifyNodeUpdate(at: node)
        }
    }
    
    
    override nonisolated func presentedItemDidMove(to newURL: URL) {
        
        super.presentedItemDidMove(to: newURL)
        
        // remake fileURLs with the new location
        Task { @MainActor in
            self.fileNode?.move(to: newURL)
            self.notifyNodeUpdate(at: self.fileNode)
        }
    }
    
    
    
    // MARK: Action Messages
    
    @IBAction func openDocumentAsPlainText(_ sender: NSMenuItem) {
        
        guard let fileURL = sender.representedObject as? URL else { return }
        
        Task {
            await self.openDocument(at: fileURL, asPlainText: true)
        }
    }
    
    
    
    // MARK: Public Methods
    
    /// Returns the opened document at the given file node.
    ///
    /// - Parameter node: The file node to find.
    /// - Returns: A Document if found.
    func openedDocument(at node: FileNode) -> DataDocument? {
        
        self.documents.first { $0.fileURL == node.fileURL }
    }
    
    
    /// Opens a document as a member.
    ///
    /// - Parameters:
    ///   - fileURL: The file URL of the document to open.
    ///   - asPlainText: If `true`, the document is forcibly opened as a plain text file.
    /// - Returns: Return `true` if the document of the given file did successfully open.
    @discardableResult func openDocument(at fileURL: URL, asPlainText: Bool = false) async -> Bool {
        
        assert(!fileURL.hasDirectoryPath)
        
        if let currentDocument,
           fileURL == currentDocument.fileURL,
           !asPlainText || currentDocument is Document
        {
            return true  // already open
        }
        
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
        
        let contentType = (try? fileURL.resourceValues(forKeys: [.contentTypeKey]).contentType) ?? .data
        
        // make document
        let document: NSDocument
        do {
            document = (asPlainText || Self.shouldOpen(url: fileURL, ofType: contentType))
                ? try NSDocumentController.shared.makeDocument(withContentsOf: fileURL, ofType: contentType.identifier)
                : try PreviewDocument(contentsOf: fileURL, ofType: contentType.identifier)
        } catch {
            self.presentErrorAsSheet(error)
            return false
        }
        
        guard let document = document as? DataDocument else { return false }
        
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
        
        let name = String(localized: "Untitled", comment: "default filename for new creation")
        let pathExtension = (try? SyntaxManager.shared.setting(name: UserDefaults.standard[.syntax]))?.extensions.first
        let fileURL = parentNode.fileURL.appending(component: name).appendingPathExtension(pathExtension ?? "").appendingUniqueNumber()
        
        var coordinationError: NSError?
        var writingError: (any Error)?
        NSFileCoordinator(filePresenter: self).coordinate(writingItemAt: fileURL, error: &coordinationError) { newURL in
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
        NSFileCoordinator(filePresenter: self).coordinate(writingItemAt: folderURL, error: &coordinationError) { newURL in
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
    ///   - name: The new filename.
    func renameItem(at node: FileNode, with name: String) throws {
        
        // validate new name
        guard name.utf16.count <= Int(NAME_MAX) else {
            throw InvalidNameError.tooLong
        }
        guard !name.isEmpty else {
            throw InvalidNameError.empty
        }
        guard !name.contains("/") else {
            throw InvalidNameError.invalidCharacter("/")
        }
        guard !name.contains(":") else {
            throw InvalidNameError.invalidCharacter(":")
        }
        guard !name.contains(where: \.isNewline) else {
            throw InvalidNameError.newLine
        }
        
        let isCurrentDocument = self.currentDocument?.fileURL == node.fileURL
        let newURL = node.fileURL.deletingLastPathComponent().appending(component: name)
        
        do {
            try self.moveFile(from: node.fileURL, to: newURL)
        } catch let error as CocoaError where error.errorCode == CocoaError.fileWriteFileExists.rawValue {
            throw InvalidNameError.duplicated(name: name)
        } catch {
            throw error
        }
        
        if isCurrentDocument, let document = self.currentDocument as? Document {
            // -> At this point, the document hasn’t updated its fileURL yet.
            document.invalidateSyntax(filename: name)
        }
        
        node.rename(with: name)
    }
    
    
    /// Moves the file node to another file node.
    ///
    /// - Parameters:
    ///   - node: The node to move.
    ///   - destinationNode: The new parent node.
    func moveItem(at node: FileNode, to destinationNode: FileNode) throws {
        
        assert(destinationNode.isDirectory)
        
        let destinationURL = destinationNode.fileURL.appending(component: node.name)
            .appendingUniqueNumber()
        try self.moveFile(from: node.fileURL, to: destinationURL)
        
        node.move(to: destinationNode)
    }
    
    
    /// Copies the file at the given `fileURL` to the given node.
    ///
    /// - Parameters:
    ///   - fileURL: The URL of the source file.
    ///   - destinationNode: The destination parent node.
    /// - Returns: The file node created.
    func copyItem(at fileURL: URL, to destinationNode: FileNode) throws -> FileNode {
        
        assert(destinationNode.isDirectory)
        
        let destinationURL = destinationNode.fileURL.appending(component: fileURL.lastPathComponent)
            .appendingUniqueNumber()
        
        var coordinationError: NSError?
        var copyingError: (any Error)?
        NSFileCoordinator(filePresenter: self).coordinate(readingItemAt: fileURL, options: .withoutChanges, writingItemAt: destinationURL, error: &coordinationError) { (newSourceURL, newDestinationURL) in
            do {
                try FileManager.default.copyItem(at: newSourceURL, to: newDestinationURL)
            } catch {
                copyingError = error
            }
        }
        
        if let error = coordinationError ?? copyingError {
            throw error
        }
        
        let node = try FileNode(at: destinationURL, parent: destinationNode)
        destinationNode.addNode(node)
        
        return node
    }
    
    
    /// Duplicates the file/folder at the given `fileURL`.
    ///
    /// - Parameters:
    ///   - node: The file node to duplicate.
    /// - Returns: The file node created.
    func duplicateItem(at node: FileNode) throws -> FileNode {
        
        let duplicatedURL = node.fileURL.appendingUniqueNumber(suffix: String(localized: "copy", comment: "suffix for copied setting file"))
        
        var coordinationError: NSError?
        var copyError: (any Error)?
        NSFileCoordinator(filePresenter: self).coordinate(readingItemAt: node.fileURL, options: .withoutChanges, writingItemAt: duplicatedURL, error: &coordinationError) { (newSourceURL, newDestinationURL) in
            do {
                try FileManager.default.copyItem(at: newSourceURL, to: newDestinationURL)
            } catch {
                copyError = error
            }
        }
        
        if let error = coordinationError ?? copyError {
            throw error
        }
        
        let duplicatedNode = try FileNode(at: duplicatedURL, parent: node.parent)
        node.parent?.addNode(duplicatedNode)
        
        return duplicatedNode
    }
    
    
    /// Properly moves the item to the trash.
    ///
    /// - Parameters:
    ///   - node: The file node to move to the Trash.
    func trashItem(_ node: FileNode) throws {
        
        // close if the item to the Trash is opened as a document
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
    /// - Parameter node: The file node to open.
    func openInWindow(at node: FileNode) {
        
        let fileURL: URL
        do {
            fileURL = try node.resolvedFileURL
        } catch {
            self.presentError(error)
            return
        }
        
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
    
    /// Returns whether the receiver should open a file tat the given URL as a text-plain file.
    ///
    /// - Parameters:
    ///   - url: The file URL.
    ///   - type: The file's content type.
    /// - Returns: `true` if the file should be opened as a plain-text.
    private static func shouldOpen(url: URL, ofType type: UTType) -> Bool {
        
        if type.conforms(to: .text) { return true }
        
        // symbolic link and alias file
        if type.conforms(to: .resolvable) { return false }
        
        if type.conforms(to: .propertyList) {
            guard let data = try? Data(contentsOf: url) else { return true }
            
            var format: PropertyListSerialization.PropertyListFormat = .xml
            _ = try? PropertyListSerialization.propertyList(from: data, format: &format)
            
            return format != .binary
        }
        
        // check the default app for the file is CotEditor
        if let appURL = NSWorkspace.shared.urlForApplication(toOpen: url),
           let bundleIdentifier = Bundle(url: appURL)?.bundleIdentifier,
           bundleIdentifier == Bundle.main.bundleIdentifier
        {
            return true
        }
        
        if SyntaxManager.shared.settingName(documentName: url.lastPathComponent) != nil { return true }
        
        return url.pathExtension.isEmpty
    }
    
    
    /// Notifies file node update to the UI.
    ///
    /// - Parameter node: The node whose children were changed.
    private func notifyNodeUpdate(at node: FileNode?) {
        
        guard let node else { return }
        
        self.fileBrowserViewController?.didUpdateNode(at: node)
    }
    
    
    /// Changes the frontmost document.
    ///
    /// - Parameter document: The document to bring frontmost.
    private func changeFrontmostDocument(to document: DataDocument) {
        
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
    
    
    /// Moves the file to a new destination inside the directory.
    ///
    /// - Note: This method doesn't update the file node.
    ///
    /// - Parameters:
    ///   - sourceURL: The current file URL.
    ///   - destinationURL: The destination.
    private func moveFile(from sourceURL: URL, to destinationURL: URL) throws {
        
        var coordinationError: NSError?
        var movingError: (any Error)?
        NSFileCoordinator(filePresenter: self).coordinate(writingItemAt: sourceURL, options: .forMoving, writingItemAt: destinationURL, options: .forMoving, error: &coordinationError) { (newSourceURL, newDestinationURL) in
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
}


private enum DirectoryDocumentError: LocalizedError {
    
    case alreadyOpen(URL)
    
    
    var errorDescription: String? {
        
        switch self {
            case .alreadyOpen(let fileURL):
                String(localized: "DirectoryDocumentError.alreadyOpen.description",
                       defaultValue: "The file “\(fileURL.lastPathComponent)” is already open in another window.")
                
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
