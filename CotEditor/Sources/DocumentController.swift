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
//  © 2014-2023 1024jp
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

protocol AdditionalDocumentPreparing: NSDocument {
    
    func didMakeDocumentForExistingFile(url: URL)
}


final class DocumentController: NSDocumentController {
    
    // MARK: Public Properties
    
    @Published private(set) var currentSyntaxName: String?
    private(set) var accessorySelectedEncoding: String.Encoding?
    
    
    // MARK: Private Properties
    
    private let transientDocumentLock = NSLock()
    private var deferredDocuments: [NSDocument] = []
    
    private var mainWindowObserver: AnyCancellable?
    private var syntaxObserver: AnyCancellable?
    
    
    // MARK: -
    // MARK: Lifecycle
    
    override init() {
        
        super.init()
        
        self.autosavingDelay = 5.0
        
        // observe the frontmost syntax change
        self.mainWindowObserver = NSApp.publisher(for: \.mainWindow)
            .map { $0?.windowController?.document as? Document }
            .sink { [unowned self] in
                self.currentSyntaxName = $0?.syntaxParser.syntax.name
                self.syntaxObserver = $0?.didChangeSyntax
                    .sink { self.currentSyntaxName = $0 }
            }
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    // MARK: Document Controller Methods
    
    override func openDocument(withContentsOf url: URL, display displayDocument: Bool) async throws -> (NSDocument, Bool) {
        
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
        self.accessorySelectedEncoding = nil
        
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
            let type = UTType(typeName)
            try self.checkOpeningSafetyOfDocument(at: url, type: type)
            
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
        
        let options = OpenOptions()
        let accessory = OpenPanelAccessory(options: options, openPanel: openPanel, encodings: EncodingManager.shared.encodings)
        let accessoryView = NSHostingView(rootView: accessory)
        accessoryView.sizingOptions = .intrinsicContentSize
        
        openPanel.accessoryView = accessoryView
        openPanel.isAccessoryViewDisclosed = true
        
        let result = await super.beginOpenPanel(openPanel, forTypes: inTypes)
        
        if result == NSApplication.ModalResponse.OK.rawValue {
            self.accessorySelectedEncoding = options.encoding
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
    
    
    override func validateUserInterfaceItem(_ item: any NSValidatedUserInterfaceItem) -> Bool {
        
        switch item.action {
            case #selector(newDocumentAsTab):
                return self.currentDocument != nil
            default:
                break
        }
        
        return super.validateUserInterfaceItem(item)
    }
    
    
    
    // MARK: Public Methods
    
    /// Opens an untitled document with the given content or recycles the transient document if available.
    ///
    /// - Parameters:
    ///   - content: The text content to fill in the created document.
    ///   - title: The document title to display in the window, or `nil` to leave it as untitled.
    ///   - displayDocument: `true` if the user interface for the document should be shown, otherwise `false`.
    /// - Returns: Returns the new Document object.
    @discardableResult
    func openUntitledDocument(content: String, title: String? = nil, display displayDocument: Bool) throws -> Document {
        
        let document = try self.transientDocument ?? (try self.openUntitledDocumentAndDisplay(false) as! Document)
        
        document.textStorage.replaceContent(with: content)
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
    @MainActor private func replaceTransientDocument(_ transientDocument: Document, with document: Document) {
        
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
    ///   - type: The type of the document.
    /// - Throws: `DocumentReadError`
    private func checkOpeningSafetyOfDocument(at url: URL, type: UTType?) throws {
        
        assert(type != nil)
        
        // check if the file is possible binary
        let binaryTypes: [UTType] = [.image, .audiovisualContent, .archive]
        if let type,
           binaryTypes.contains(where: type.conforms(to:)),
           !type.conforms(to: .svg),  // SVG is plain-text (except SVGZ)
           url.pathExtension != "ts"  // "ts" extension conflicts between MPEG-2 streamclip file and TypeScript
        {
            throw DocumentReadError(kind: .binaryFile(type: type), url: url)
        }
        
        // check if the file is enormously large
        let fileSizeThreshold = UserDefaults.standard[.largeFileAlertThreshold]
        if fileSizeThreshold > 0,
           let fileSize = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize,
           fileSize > fileSizeThreshold
        {
            throw DocumentReadError(kind: .tooLarge(size: fileSize), url: url)
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

private struct DocumentReadError: LocalizedError, RecoverableError {
    
    enum ErrorKind {
        case binaryFile(type: UTType)
        case tooLarge(size: Int)
    }
    
    
    let kind: ErrorKind
    let url: URL
    
    
    var errorDescription: String? {
        
        switch self.kind {
            case .binaryFile:
                return String(localized: "The file “\(self.url.lastPathComponent)” doesn’t appear to be text data.")
                
            case .tooLarge(let size):
                let byteSize = size.formatted(.byteCount(style: .file))
                return String(localized: "The file “\(self.url.lastPathComponent)” has a size of \(byteSize).")
        }
    }
    
    
    var recoverySuggestion: String? {
        
        switch self.kind {
            case .binaryFile(let type):
                let localizedTypeName = type.localizedDescription ?? "unknown file type"
                return String(localized: "The file appears to be \(localizedTypeName).\n\nDo you really want to open the file?")
                
            case .tooLarge:
                return String(localized: "Opening such a large file can make the application slow or unresponsive.\n\nDo you really want to open the file?")
        }
    }
    
    
    var recoveryOptions: [String] {
        
        [String(localized: "Open"),
         String(localized: "Cancel")]
    }
    
    
    func attemptRecovery(optionIndex recoveryOptionIndex: Int) -> Bool {
        
        (recoveryOptionIndex == 0)
    }
}
