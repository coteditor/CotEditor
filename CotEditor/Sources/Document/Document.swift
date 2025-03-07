//
//  Document.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by nakamuxu on 2004-12-08.
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
import Observation
import Combine
import SwiftUI
import UniformTypeIdentifiers
import OSLog
import ControlUI
import Defaults
import FileEncoding
import FilePermissions
import LineEnding
import Syntax
import URLUtils

extension Document: EditorSource {
    
    var string: String? { self.textView?.string }
    var selectedRanges: [NSRange] { self.textView?.selectedRanges.map(\.rangeValue) ?? [] }
}


@Observable final class Document: DataDocument, AdditionalDocumentPreparing, EncodingChanging {
    
    nonisolated static let didUpdateChange = Notification.Name("didUpdateChange")
    
    // MARK: Enums
    
    private enum SerializationKey {
        
        static let allowsLossySaving = "allowsLossySaving"
        static let isEditable = "isEditable"
        static let isTransient = "isTransient"
        static let isVerticalText = "isVerticalText"
        static let suppressesInconsistentLineEndingAlert = "suppressesInconsistentLineEndingAlert"
        static let syntax = "syntax"
        static let originalContentString = "originalContentString"
    }
    
    
    // MARK: Public Properties
    
    @ObservationIgnored @Published @objc var isEditable = true  { didSet { self.invalidateRestorableState() } }
    var isTransient = false  // untitled & empty document that was created automatically
    nonisolated(unsafe) var isVerticalText = false
    
    
    // MARK: Readonly Properties
    
    let textStorage = NSTextStorage()
    let syntaxParser: SyntaxParser
    private(set) nonisolated(unsafe) var fileEncoding: FileEncoding  { didSet { Task { @MainActor in self.didChangeFileEncoding.send(fileEncoding) } } }
    @ObservationIgnored @Published private(set) var lineEnding: LineEnding  { didSet { self.lineEndingScanner.baseLineEnding = lineEnding } }
    @ObservationIgnored @Published private(set) var mode: Mode
    
    let lineEndingScanner: LineEndingScanner
    let counter: EditorCounter
    @ObservationIgnored private(set) lazy var selection = TextSelection(document: self)
    
    let didChangeSyntax = PassthroughSubject<String, Never>()
    let didChangeFileEncoding = PassthroughSubject<FileEncoding, Never>()
    
    
    // MARK: Private Properties
    
    @ObservationIgnored private lazy var printPanelAccessoryController: PrintPanelAccessoryController = NSStoryboard(name: "PrintPanelAccessory", bundle: nil).instantiateInitialController()!
    
    private nonisolated(unsafe) var readingEncoding: String.Encoding?  // encoding to read document file
    private nonisolated(unsafe) var fileData: Data?
    private nonisolated(unsafe) var shouldSaveEncodingXattr = true
    private nonisolated(unsafe) var isExecutable = false
    private nonisolated(unsafe) var syntaxFileExtension: String?
    private nonisolated(unsafe) var suppressesInconsistentLineEndingAlert = false
    private nonisolated(unsafe) var isExternalUpdateAlertShown = false
    private nonisolated(unsafe) var allowsLossySaving = false
    private var isInitialized = false
    
    private nonisolated(unsafe) var lastSavedData: Data?  // temporal data used only within saving process
    private var saveOptions: SaveOptions?
    
    private var urlDetector: URLDetector?
    
    private var syntaxUpdateObserver: AnyCancellable?
    private var textStorageObserver: AnyCancellable?
    private var defaultObservers: Set<AnyCancellable> = []
    
    
    // MARK: Lifecycle
    
    override init() {
        
        // [caution] This method may be called from a background thread due to concurrent-opening.
        
        let openOptions = (DocumentController.shared as! DocumentController).openOptions
        
        self.isEditable = if let openOptions { !openOptions.isReadOnly } else { true }
        
        let lineEnding = LineEnding.allCases[safe: UserDefaults.standard[.lineEndCharCode]] ?? .lf
        self.lineEnding = lineEnding
        
        var syntaxName = UserDefaults.standard[.syntax]
        let syntax = try? SyntaxManager.shared.setting(name: syntaxName)
        syntaxName = (syntax == nil) ? SyntaxName.none : syntaxName
        self.syntaxParser = SyntaxParser(textStorage: self.textStorage, syntax: syntax ?? Syntax.none, name: syntaxName)
        self.syntaxFileExtension = syntax?.extensions.first
        
        // use the encoding selected by the user in the open panel, if exists
        self.fileEncoding = EncodingManager.shared.defaultEncoding
        self.readingEncoding = openOptions?.encoding
        
        // observe for inconsistent line endings
        self.lineEndingScanner = .init(textStorage: self.textStorage, lineEnding: lineEnding)
        
        self.counter = EditorCounter()
        
        self.mode = .kind(.general)
        
        super.init()
        
        self.counter.source = self
        
        self.defaultObservers = [
            UserDefaults.standard.publisher(for: .autoLinkDetection, initial: true)
                .removeDuplicates()
                .sink { [unowned self] enabled in
                    self.urlDetector?.cancel()
                    self.urlDetector = enabled ? URLDetector(textStorage: self.textStorage) : nil
                },
            UserDefaults.standard.publisher(for: .modes, initial: true)
                .sink { [weak self] _ in self?.invalidateMode() },
        ]
        
        // observe syntax update
        self.syntaxUpdateObserver = NotificationCenter.default.publisher(for: .didUpdateSettingNotification, object: SyntaxManager.shared)
            .map { $0.userInfo!["change"] as! SettingChange }
            .filter { [weak self] change in change.old == self?.syntaxParser.name }
            .sink { [weak self] change in self?.setSyntax(name: change.new ?? SyntaxName.none) }
    }
    
    
    override func encodeRestorableState(with coder: NSCoder, backgroundQueue queue: OperationQueue) {
        
        super.encodeRestorableState(with: coder, backgroundQueue: queue)
        
        coder.encode(self.allowsLossySaving, forKey: SerializationKey.allowsLossySaving)
        coder.encode(self.isEditable, forKey: SerializationKey.isEditable)
        coder.encode(self.isTransient, forKey: SerializationKey.isTransient)
        coder.encode(self.isVerticalText, forKey: SerializationKey.isVerticalText)
        coder.encode(self.suppressesInconsistentLineEndingAlert, forKey: SerializationKey.suppressesInconsistentLineEndingAlert)
        coder.encode(self.syntaxParser.name, forKey: SerializationKey.syntax)
        
        // store unencoded string but only when incompatible
        if !self.canBeConverted() {
            coder.encode(self.textStorage.string, forKey: SerializationKey.originalContentString)
        }
    }
    
    
    override func restoreState(with coder: NSCoder) {
        
        super.restoreState(with: coder)
        
        if coder.containsValue(forKey: SerializationKey.allowsLossySaving) {
            self.allowsLossySaving = coder.decodeBool(forKey: SerializationKey.allowsLossySaving)
        }
        if coder.containsValue(forKey: SerializationKey.isEditable) {
            self.isEditable = coder.decodeBool(forKey: SerializationKey.isEditable)
        }
        if coder.containsValue(forKey: SerializationKey.isTransient) {
            self.isTransient = coder.decodeBool(forKey: SerializationKey.isTransient)
        }
        if coder.containsValue(forKey: SerializationKey.isVerticalText) {
            self.isVerticalText = coder.decodeBool(forKey: SerializationKey.isVerticalText)
        }
        if coder.containsValue(forKey: SerializationKey.suppressesInconsistentLineEndingAlert) {
            self.suppressesInconsistentLineEndingAlert = coder.decodeBool(forKey: SerializationKey.suppressesInconsistentLineEndingAlert)
        }
        if let syntaxName = coder.decodeObject(of: NSString.self, forKey: SerializationKey.syntax) as? String {
            self.setSyntax(name: syntaxName)
        }
        
        if let string = coder.decodeObject(of: NSString.self, forKey: SerializationKey.originalContentString) as? String {
            self.textStorage.replaceContent(with: string)
        }
    }
    
    
    // MARK: Document Methods
    
    nonisolated override static var autosavesInPlace: Bool {
        
        // avoid changing the value while the application is running
        struct InitialValue { static let autosavesInPlace = UserDefaults.standard[.enablesAutosaveInPlace] }
        
        return InitialValue.autosavesInPlace
    }
    
    
    override static func canConcurrentlyReadDocuments(ofType: String) -> Bool {
        
        true
    }
    
    
    override func canAsynchronouslyWrite(to url: URL, ofType typeName: String, for saveOperation: NSDocument.SaveOperationType) -> Bool {
        
        true
    }
    
    
    @ObservationIgnored override nonisolated var fileURL: URL? {
        
        didSet {
            NotificationCenter.default.post(name: NSDocument.didChangeFileURLNotification, object: self)
        }
    }
    
    
    override func makeWindowControllers() {
        
        // -> The window controller already exists either when:
        //   - The window of a transient document was reused.
        //   - The document is a member of a DirectoryDocument.
        if self.windowController == nil {
            let windowController = DocumentWindowController(document: self)
            self.addWindowController(windowController)
            
            // avoid showing "edited" indicator in the close button when the contents are empty
            if !Self.autosavesInPlace {
                self.textStorageObserver = NotificationCenter.default
                    .publisher(for: NSTextStorage.didProcessEditingNotification, object: self.textStorage)
                    .map { $0.object as! NSTextStorage }
                    .map(\.string.isEmpty)
                    .removeDuplicates()
                    .receive(on: RunLoop.main)
                    .assign(to: \.isWhitePaper, on: windowController)
            }
            
            NotificationCenter.default.post(name: NSDocument.didMakeWindowNotification, object: self)
        }
        
        self.applyContentToWindow()
    }
    
    
    override func addWindowController(_ windowController: NSWindowController) {
        
        assert(windowController is DocumentWindowController)
        
        super.addWindowController(windowController)
        
        self.windowController = windowController as? DocumentWindowController
    }
    
    
    override func removeWindowController(_ windowController: NSWindowController) {
        
        super.removeWindowController(windowController)
        
        if windowController == self.windowController {
            self.windowController = nil
        }
    }
    
    
    override func showWindows() {
        
        super.showWindows()
        
        self.windowController?.showWindow(nil)
    }
    
    
    override var windowForSheet: NSWindow? {
        
        super.windowForSheet ?? self.windowController?.window
    }
    
    
    override nonisolated func fileNameExtension(forType typeName: String, saveOperation: NSDocument.SaveOperationType) -> String? {
        
        if !self.isDraft, let pathExtension = self.fileURL?.pathExtension {
            return pathExtension
        }
        
        return self.syntaxFileExtension
    }
    
    
    override func revert(toContentsOf url: URL, ofType typeName: String) throws {
        
        // once force-close all sheets
        // -> Presented errors will be displayed again after the revert automatically. (since OS X 10.10)
        self.windowForSheet?.sheets.forEach { $0.close() }
        
        let selection = self.textStorage.editorSelection
        
        try super.revert(toContentsOf: url, ofType: typeName)
        
        // do nothing if already no textView exists
        guard !selection.isEmpty else { return }
        
        self.textStorage.restoreEditorSelection(selection)
    }
    
    
    override func duplicate() throws -> NSDocument {
        
        let document = try super.duplicate() as! Document
        
        document.setSyntax(name: self.syntaxParser.name)
        document.lineEnding = self.lineEnding
        document.fileEncoding = self.fileEncoding
        document.isVerticalText = self.isVerticalText
        document.isExecutable = self.isExecutable
        
        return document
    }
    
    
    override nonisolated func read(from url: URL, ofType typeName: String) throws {
        
        // [caution] This method may be called from a background thread due to concurrent-opening.
        
        let data = try Data(contentsOf: url)  // FILE_READ
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path(percentEncoded: false))  // FILE_READ
        let extendedAttributes = ExtendedFileAttributes(dictionary: attributes)
        
        let strategy: String.DecodingStrategy = {
            if let encoding = self.readingEncoding {
                return .specific(encoding)
            }
            
            var encodingCandidates = EncodingManager.shared.fileEncodings.compactMap { $0?.encoding }
            let isInitialOpen = (self.fileData == nil) && (self.textStorage.length == 0)
            if !isInitialOpen {  // prioritize the current encoding
                encodingCandidates.insert(self.fileEncoding.encoding, at: 0)
            }
            
            return .automatic(.init(candidates: encodingCandidates,
                                    xattrEncoding: extendedAttributes.encoding,
                                    tagScanLength: UserDefaults.standard[.referToEncodingTag] ? 2000 : nil))
        }()
        
        // .readingEncoding is only valid once
        self.readingEncoding = nil
        
        let (string, fileEncoding) = try String.string(data: data, decodingStrategy: strategy)
        
        // store file data in order to check the file contents identity in `presentedItemDidChange()`
        self.fileData = data
        
        // use file attributes only if `fileURL` exists
        // -> The passed-in `url` in this method can point to a file that isn't the real document file,
        //    for example on resuming an unsaved document.
        if self.fileURL != nil {
            let fileAttributes = FileAttributes(dictionary: attributes)
            self.fileAttributes = fileAttributes
            self.isExecutable = fileAttributes.permissions.user.contains(.execute)
        }
        
        // do not save `com.apple.TextEncoding` extended attribute if it doesn't exists
        self.shouldSaveEncodingXattr = (extendedAttributes.encoding != nil)
        
        // set text orientation state
        // -> Ignore if no metadata found to avoid restoring to the horizontal layout while editing unwontedly.
        if UserDefaults.standard[.savesTextOrientation], extendedAttributes.isVerticalText {
            self.isVerticalText = true
        }
        
        if extendedAttributes.allowsInconsistentLineEndings {
            self.suppressesInconsistentLineEndingAlert = true
        }
        
        self.allowsLossySaving = false
        
        // set read values
        DispatchQueue.syncOnMain {
            self.textStorage.replaceContent(with: string)
            
            self.fileEncoding = fileEncoding
            self.lineEnding = self.lineEndingScanner.lineEndings.majorValue() ?? self.lineEnding  // keep default if no line endings are found
            
            // determine syntax (only on the first file open)
            if !self.isInitialized {
                let syntaxName = SyntaxManager.shared.settingName(documentName: url.lastPathComponent, contents: string)
                self.setSyntax(name: syntaxName ?? SyntaxName.none, isInitial: true)
            }
            self.isInitialized = true
            
            self.viewController?.invalidateStyleInTextStorage()
        }
    }
    
    
    override func data(ofType typeName: String) throws -> Data {
        
        // [caution] Despite lack of the `nonisolated` label, this method can be called from a background thread in async-saving.
        
        let fileEncoding = self.fileEncoding
        
        // get data from string to save
        // -> .data(using:allowLossyConversion:) never returns nil as long as allowLossyConversion is true.
        var data = self.textStorage.string
            .convertYenSign(for: fileEncoding.encoding)
            .data(using: fileEncoding.encoding, allowLossyConversion: true)!
        
        // reset `allowsLossySaving` flag if the compatibility issue is solved
        if self.allowsLossySaving, self.canBeConverted() {
            self.allowsLossySaving = false
        }
        
        self.unblockUserInteraction()
        
        // add UTF-8 BOM if needed
        if fileEncoding.withUTF8BOM {
            data.insert(contentsOf: Unicode.BOM.utf8.sequence, at: 0)
        }
        
        // keep to swap with `fileData` later, but only when succeed
        self.lastSavedData = data
        
        return data
    }
    
    
    override func save(to url: URL, ofType typeName: String, for saveOperation: NSDocument.SaveOperationType, completionHandler: @escaping ((any Error)?) -> Void) {
        
        // check if the contents can be saved with the current text encoding
        guard saveOperation.isAutosaveElsewhere || self.allowsLossySaving || self.canBeConverted() else {
            let error = DocumentSavingError(.lossyEncoding(self.fileEncoding), attempter: self)
            return completionHandler(error)
        }
        
        // break undo grouping
        let textViews = self.textStorage.layoutManagers.compactMap(\.textViewForBeginningOfSelection)
        for textView in textViews {
            textView.breakUndoCoalescing()
        }
        
        // trim trailing whitespace if needed
        if self.isEditable, !saveOperation.isAutosave, UserDefaults.standard[.autoTrimsTrailingWhitespace] {
            textViews.first?.trimTrailingWhitespace(ignoringEmptyLines: !UserDefaults.standard[.trimsWhitespaceOnlyLines])
        }
        
        // apply save panel options
        if let saveOptions {
            self.isExecutable = saveOptions.isExecutable
            self.saveOptions = nil
        }
        
        // modify place to create the elsewhere backup file to `~/Library/Autosaved Information/`
        var url = url
        if saveOperation == .autosaveElsewhereOperation, self.fileURL != nil, self.autosavedContentsFileURL == nil {
            url = Self.autosaveElsewhereURL(for: url)
        }
        
        // workaround the issue that invoking the async version super blocks the save process
        // with macOS 12-14 + Xcode 13-15 (2022 FB11203469).
        // To reproduce the issue:
        //     1. Make a document unsaved ("Edited" status in the window subtitle).
        //     2. Open the save panel once and cancel it.
        //     3. Quit the application.
        //     4. Then, the application hangs up.
        super.save(to: url, ofType: typeName, for: saveOperation) { error in
            defer {
                completionHandler(error)
            }
            if error != nil { return }
            
            // apply syntax that is inferred from the filename or the shebang
            if saveOperation == .saveAsOperation,
               let syntaxName = SyntaxManager.shared.settingName(documentName: url.lastPathComponent, contents: self.textStorage.string)
            {
                // -> Due to the async-saving, self.textStorage can be changed from the actual saved contents.
                //    But we don't care about that.
                self.setSyntax(name: syntaxName)
            }
            
            if !saveOperation.isAutosave {
                Task {
                    await ScriptManager.shared.dispatch(event: .documentSaved, document: self.objectSpecifier)
                }
            }
        }
    }
    
    
    override nonisolated func writeSafely(to url: URL, ofType typeName: String, for saveOperation: NSDocument.SaveOperationType) throws {
        
        try super.writeSafely(to: url, ofType: typeName, for: saveOperation)
        
        if saveOperation != .autosaveElsewhereOperation {
            // set/remove flag for vertical text orientation
            if UserDefaults.standard[.savesTextOrientation] {
                try? url.setExtendedAttribute(data: self.isVerticalText ? Data([1]) : nil, for: FileExtendedAttributeName.verticalText)
            }
            
            // get the latest file attributes
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: url.path(percentEncoded: false))  // FILE_ACCESS
                self.fileAttributes = FileAttributes(dictionary: attributes)
            } catch {
                assertionFailure(error.localizedDescription)
            }
            
            // store file data in order to check the file contents identity in `presentedItemDidChange()`
            assert(self.lastSavedData != nil)
            self.fileData = self.lastSavedData
        }
        self.lastSavedData = nil
    }
    
    
    override nonisolated func fileAttributesToWrite(to url: URL, ofType typeName: String, for saveOperation: NSDocument.SaveOperationType, originalContentsURL absoluteOriginalContentsURL: URL?) throws -> [String: Any] {
        
        var attributes = try super.fileAttributesToWrite(to: url, ofType: typeName, for: saveOperation, originalContentsURL: absoluteOriginalContentsURL)
        
        // give the execute permission if user requested
        if self.isExecutable, !saveOperation.isAutosave {
            var permissions = self.fileAttributes?.permissions ?? FilePermissions(mask: 0o644)  // ???: Is the default permission really always 644?
            permissions.user.insert(.execute)
            attributes[FileAttributeKey.posixPermissions] = permissions.mask
        }
        
        // save document state to the extended file attributes
        // -> Save FileExtendedAttributeName.verticalText at `super.writeSafely(to:ofType:for:)`
        //     since the xattr already set to the file cannot remove at this point. (2024-06-12)
        var xattrs: [String: Data] = [:]
        if self.shouldSaveEncodingXattr {
            xattrs[FileExtendedAttributeName.encoding] = self.fileEncoding.encoding.xattrEncodingData
        }
        if self.suppressesInconsistentLineEndingAlert {
            xattrs[FileExtendedAttributeName.allowLineEndingInconsistency] = Data([1])
        }
        if !xattrs.isEmpty {
            attributes[FileAttributeKey.extendedAttributes.rawValue] = xattrs
        }
        
        return attributes
    }
    
    
    override func prepareSavePanel(_ savePanel: NSSavePanel) -> Bool {
        
        savePanel.allowsOtherFileTypes = true
        savePanel.allowedContentTypes = self.fileType
            .flatMap { self.fileNameExtension(forType: $0, saveOperation: .saveOperation) }
            .flatMap { UTType(filenameExtension: $0) }
            .map { [$0] } ?? []
        
        // avoid the Hide Extension option removes actual filename extension (macOS 14, 2024-05)
        savePanel.canSelectHiddenExtension = false
        savePanel.isExtensionHidden = false
        
        // set accessory view
        let saveOptions = SaveOptions(isExecutable: self.isExecutable)
        self.saveOptions = saveOptions
        let accessory = SavePanelAccessory(options: saveOptions)
        let accessoryView = NSHostingView(rootView: accessory)
        accessoryView.sizingOptions = .intrinsicContentSize
        savePanel.accessoryView = accessoryView
        
        // let save panel accept any file extension
        // -> Otherwise, the file extension for `.allowedContentTypes` is automatically added
        //    even when the user specifies another one (macOS 14, 2023-09).
        DispatchQueue.main.async { [weak savePanel] in
            savePanel?.allowedContentTypes = []
        }
        
        return true
    }
    
    
    override func canClose(withDelegate delegate: Any, shouldClose shouldCloseSelector: Selector?, contextInfo: UnsafeMutableRawPointer?) {
        
        // suppress save dialog if contents are empty and not saved explicitly
        suppression: if self.isDraft || self.fileURL == nil, self.textStorage.string.isEmpty {
            // delete autosaved file if exists
            // -> An engineer at Apple told there is no need to wrap the file access here with NSFileCoordinator (2023-06).
            if let fileURL = self.fileURL {
                do {
                    try FileManager.default.removeItem(at: fileURL)  // FILE_ACCESS
                } catch {
                    Logger.app.error("Failed empty file deletion: \(error)")
                    break suppression
                }
            }
            
            // tell the document can be closed; then, no need to invoke super anymore
            DelegateContext(delegate: delegate, selector: shouldCloseSelector, contextInfo: contextInfo).perform(from: self, flag: true)
            return
        }
        
        super.canClose(withDelegate: delegate, shouldClose: shouldCloseSelector, contextInfo: contextInfo)
    }
    
    
    override func close() {
        
        super.close()
        
        self.syntaxUpdateObserver?.cancel()
        self.textStorageObserver?.cancel()
        self.counter.cancel()
        self.syntaxParser.cancel()
        self.urlDetector?.cancel()
        self.lineEndingScanner.cancel()
    }
    
    
    override func printOperation(withSettings printSettings: [NSPrintInfo.AttributeKey: Any]) throws -> NSPrintOperation {
        
        let viewController = self.viewController!
        
        self.printPanelAccessoryController.documentShowsInvisibles = viewController.showsInvisibles
        self.printPanelAccessoryController.documentShowsLineNumber = viewController.showsLineNumber
        
        // create printView
        // -> Because the last *edited* date is not recorded anywhere, use `.now` if the document was modified since the last save.
        let lastModifiedDate = self.hasUnautosavedChanges ? .now : self.fileModificationDate
        let info = PrintTextView.DocumentInfo(name: self.displayName,
                                              fileURL: self.fileURL,
                                              lastModifiedDate: lastModifiedDate,
                                              syntaxName: self.syntaxParser.name)
        let textStorage = NSTextStorage(string: self.textStorage.string)
        let printView = PrintTextView(textStorage: textStorage, lineEndingScanner: self.lineEndingScanner, info: info)
        if let selectedRanges = self.textView?.selectedRanges {
            printView.selectedRanges = selectedRanges
        }
        
        printView.setLayoutOrientation(viewController.verticalLayoutOrientation ? .vertical : .horizontal)
        printView.baseWritingDirection = viewController.writingDirection
        printView.ligature = self.textView?.ligature ?? .standard
        printView.font = viewController.font?.withSize(UserDefaults.standard[.printFontSize])
        
        if let highlights = self.textStorage.layoutManagers.first?.syntaxHighlights(), !highlights.isEmpty {
            printView.layoutManager?.apply(highlights: highlights, theme: nil, in: printView.string.range)
        }
        
        // detect URLs manually (2019-05 macOS 10.14).
        // -> TextView anyway links all URLs in the printed PDF even the auto URL detection is disabled,
        //    but then, multiline-URLs over a page break would be broken. (cf. #958)
        Task { try? await printView.textStorage?.linkURLs() }
        
        // create print operation
        let printInfo = self.printInfo
        printInfo.dictionary().addEntries(from: printSettings)
        let printOperation = NSPrintOperation(view: printView, printInfo: printInfo)
        printOperation.showsProgressPanel = true
        
        // setup print panel
        printOperation.printPanel.addAccessoryController(self.printPanelAccessoryController)
        printOperation.printPanel.options.formUnion([.showsPaperSize, .showsOrientation, .showsScaling])
        if printView.selectedRanges.count == 1, !printView.selectedRange.isEmpty {
            printOperation.printPanel.options.formUnion(.showsPrintSelection)
        }
        
        return printOperation
    }
    
    
    override var printInfo: NSPrintInfo {
        
        get {
            let printInfo = super.printInfo
            
            printInfo.horizontalPagination = .fit
            printInfo.isHorizontallyCentered = false
            printInfo.isVerticallyCentered = false
            printInfo.leftMargin = PrintTextView.margin.left
            printInfo.rightMargin = PrintTextView.margin.right
            printInfo.topMargin = PrintTextView.margin.top
            printInfo.bottomMargin = PrintTextView.margin.bottom
            printInfo.dictionary()[NSPrintInfo.AttributeKey.headerAndFooter] = true
            
            return printInfo
        }
        
        set {
            super.printInfo = newValue
        }
    }
    
    
    override func updateChangeCount(_ change: NSDocument.ChangeType) {
        
        self.isTransient = false
        
        super.updateChangeCount(change)
        
        NotificationCenter.default.post(name: Document.didUpdateChange, object: self)
    }
    
    
    override func updateChangeCount(withToken changeCountToken: Any, for saveOperation: NSDocument.SaveOperationType) {
        
        // This method updates the values in the .isDocumentEdited and .hasUnautosavedChanges properties.
        super.updateChangeCount(withToken: changeCountToken, for: saveOperation)
        
        NotificationCenter.default.post(name: Document.didUpdateChange, object: self)
    }
    
    
    override func updateUserActivityState(_ activity: NSUserActivity) {
        
        super.updateUserActivityState(activity)
        
        if let textView = self.textView {
            let selectedRanges = textView.selectedRanges
                .map(\.rangeValue)
                .map(NSStringFromRange)
            activity.addUserInfoEntries(from: [
                UserActivityInfo.selectedRanges.key: selectedRanges,
            ])
            activity.needsSave = true
        }
    }
    
    
    override func restoreUserActivityState(_ userActivity: NSUserActivity) {
        
        super.restoreUserActivityState(userActivity)
        
        if let textView = self.textView,
           let ranges = (userActivity.userInfo?[UserActivityInfo.selectedRanges.key] as? [String])?
            .map(NSRangeFromString),
           let upperBound = ranges.map(\.upperBound).max(),
           upperBound <= textView.string.length
        {
            textView.selectedRanges = ranges as [NSValue]
            textView.scrollRangeToVisible(textView.selectedRange)
        }
    }
    
    
    override func attemptRecovery(fromError error: any Error, optionIndex recoveryOptionIndex: Int, delegate: Any?, didRecoverSelector: Selector?, contextInfo: UnsafeMutableRawPointer?) {
        
        guard (error as NSError).domain == DocumentSavingError.errorDomain else {
            return super.attemptRecovery(fromError: error, optionIndex: recoveryOptionIndex, delegate: delegate, didRecoverSelector: didRecoverSelector, contextInfo: contextInfo)
        }
        
        switch recoveryOptionIndex {
            case 0:  // == Save
                self.allowsLossySaving = true
            case 1:  // == Show Incompatible Characters
                Task {
                    await self.showWarningInspector()
                }
            case 2:  // == Cancel
                break
            default:
                preconditionFailure()
        }
        
        let didRecover = (recoveryOptionIndex == 0)
        
        DelegateContext(delegate: delegate, selector: didRecoverSelector, contextInfo: contextInfo)
            .perform(flag: didRecover)
    }
    
    
    // MARK: Protocols
    
    override nonisolated func presentedItemDidChange() {
        
        // [caution] DO NOT invoke `super.presentedItemDidChange()` that reverts document automatically if autosavesInPlace is enabled.
//        super.presentedItemDidChange()
        
        let strategy = UserDefaults.standard[.documentConflictOption]
        
        guard strategy != .ignore, !self.isExternalUpdateAlertShown else { return }  // don't check twice if already notified
        
        // check if the file contents were changed from the stored file data
        let didChange: Bool
        let modificationDate: Date?
        do {
            (didChange, modificationDate) = try self.checkFileContentsDidChange()
        } catch {
            Logger.app.error("Error on checking document file change: \(error.localizedDescription)")
            return
        }
        
        guard didChange else {
            // update the document's fileModificationDate for a workaround (2014-03 by 1024jp)
            // -> Otherwise, an alert shows up when the user saves the file.
            if let modificationDate, self.fileModificationDate?.compare(modificationDate) == .orderedAscending {
                self.fileModificationDate = modificationDate
            }
            return
        }
        
        // notify about external file update
        switch strategy {
            case .ignore:
                assertionFailure()
            case .notify:
                Task { await self.showUpdatedByExternalProcessAlert() }
            case .revert:
                Task { await self.revert() }
        }
    }
    
    
    override func validateUserInterfaceItem(_ item: any NSValidatedUserInterfaceItem) -> Bool {
        
        switch item.action {
            case #selector(changeEncoding(_:)):
                if let item = item as? NSMenuItem {
                    item.state = (item.representedObject as? FileEncoding == self.fileEncoding) ? .on : .off
                }
                
            case #selector(changeLineEnding(_:)):
                if let item = item as? NSMenuItem {
                    item.state = (item.tag == self.lineEnding.index) ? .on : .off
                }
                return self.isEditable
                
            case #selector(changeSyntax(_:)):
                if let item = item as? NSMenuItem {
                    item.state = (item.representedObject as? String == self.syntaxParser.name) ? .on : .off
                }
                
            case #selector(toggleEditable):
                if let item = item as? NSMenuItem {
                    item.title = self.isEditable
                        ? String(localized: "Prevent Editing", table: "MainMenu")
                        : String(localized: "Allow Editing", table: "MainMenu")
                    
                } else if let item = item as? StatableToolbarItem {
                    item.toolTip = self.isEditable
                        ? String(localized: "Toolbar.editable.tooltip.off",
                                 defaultValue: "Prevent the document from being edited", table: "Document")
                        : String(localized: "Toolbar.editable.tooltip.on",
                                 defaultValue: "Allow editing the document", table: "Document")
                    item.state = self.isEditable ? .off : .on
                }
                
            default: break
        }
        
        return super.validateUserInterfaceItem(item)
    }
    
    
    /// Opens an existing document file (alternative method for `init(contentsOf:ofType:)`).
    /// 
    /// - Parameter url: The URL of the opening file.
    nonisolated func didMakeDocumentForExistingFile(url: URL) {
        
        // [caution] This method may be called from a background thread due to concurrent-opening.
        // -> This method won't be invoked on Resume. (2015-01-26)
        
        Task {
            await ScriptManager.shared.dispatch(event: .documentOpened, document: self.objectSpecifier)
        }
    }
    
    
    // MARK: Public Methods
    
    /// The view controller represents document.
    var viewController: DocumentViewController? {
        
        (self.windowController?.contentViewController as? WindowContentViewController)?.documentViewController
    }
    
    
    /// The text view currently focused.
    var textView: NSTextView? {
        
        self.viewController?.focusedTextView
    }
    
    
    /// Checks if the contents can be converted in the given encoding without loss of information.
    ///
    /// - Parameter fileEncoding: The text encoding to test, or `nil` to test with the current file encoding.
    /// - Returns: `true` if the contents can be encoded in encoding without loss of information; otherwise, `false`.
    func canBeConverted(to fileEncoding: FileEncoding? = nil) -> Bool {
        
        self.textStorage.string.canBeConverted(to: (fileEncoding ?? self.fileEncoding).encoding)
    }
    
    
    /// Reinterprets the document file with the desired encoding.
    ///
    /// - Parameter encoding: The text encoding to read.
    func reinterpret(encoding: String.Encoding) throws(ReinterpretationError) {
        
        // do nothing if given encoding is the same as current one
        if encoding == self.fileEncoding.encoding { return }
        
        guard let fileURL = self.fileURL else { throw .noFile }
        
        // reinterpret
        self.readingEncoding = encoding
        do {
            try self.revert(toContentsOf: fileURL, ofType: self.fileType!)
        } catch {
            self.readingEncoding = nil
            throw .reinterpretationFailed(encoding)
        }
    }
    
    
    /// Changes the text encoding and registers the process to the undo manager.
    ///
    /// - Parameters:
    ///   - fileEncoding: The text encoding to change with.
    func changeEncoding(to fileEncoding: FileEncoding) {
        
        assert(Thread.isMainThread)
        
        guard fileEncoding != self.fileEncoding else { return }
        
        guard self.isEditable else {
            return self.presentErrorAsSheet(DocumentError.notEditable)
        }
        
        // register undo
        if let undoManager = self.undoManager {
            undoManager.registerUndo(withTarget: self) { [currentFileEncoding = self.fileEncoding, shouldSaveEncodingXattr = self.shouldSaveEncodingXattr] target in
                MainActor.assumeIsolated {
                    target.fileEncoding = currentFileEncoding
                    target.shouldSaveEncodingXattr = shouldSaveEncodingXattr
                    target.allowsLossySaving = false
                    
                    // register redo
                    target.undoManager?.registerUndo(withTarget: target) { target in
                        MainActor.assumeIsolated {
                            target.changeEncoding(to: fileEncoding)
                        }
                    }
                }
            }
            undoManager.setActionName(String(localized: "Encoding to “\(fileEncoding.localizedName)”",
                                             table: "MainMenu", comment: "undo action name"))
        }
        
        // update encoding
        self.fileEncoding = fileEncoding
        self.shouldSaveEncodingXattr = true
        self.allowsLossySaving = false
    }
    
    
    /// Change line endings and register the process to the undo manager.
    ///
    /// - Parameter lineEnding: The line ending type to change with.
    func changeLineEnding(to lineEnding: LineEnding) {
        
        assert(Thread.isMainThread)
        assert(self.isEditable)
        
        guard
            self.isEditable,
            lineEnding != self.lineEnding || !self.lineEndingScanner.inconsistentLineEndings.isEmpty
        else { return }
        
        // register undo
        if let undoManager = self.undoManager {
            let selectedRanges = self.textStorage.layoutManagers.compactMap(\.textViewForBeginningOfSelection).map(\.selectedRange)
            undoManager.registerUndo(withTarget: self) { [currentLineEnding = self.lineEnding, string = self.textStorage.string] target in
                MainActor.assumeIsolated {
                    target.textStorage.replaceContent(with: string)
                    target.lineEnding = currentLineEnding
                    for (textView, range) in zip(target.textStorage.layoutManagers.compactMap(\.textViewForBeginningOfSelection), selectedRanges) {
                        textView.selectedRange = range
                    }
                    
                    // register redo
                    target.undoManager?.registerUndo(withTarget: target) { target in
                        MainActor.assumeIsolated {
                            target.changeLineEnding(to: lineEnding)
                        }
                    }
                }
            }
            undoManager.setActionName(String(localized: "Line Endings to \(lineEnding.label)",
                                             table: "MainMenu", comment: "undo action name"))
        }
        
        // update line ending
        self.lineEnding = lineEnding
        
        // update line endings in text storage
        let selection = self.textStorage.editorSelection
        let string = self.textStorage.string.replacingLineEndings(with: lineEnding)
        self.textStorage.replaceContent(with: string)
        self.textStorage.restoreEditorSelection(selection)
    }
    
    
    /// Changes the syntax to one with the given name.
    ///
    /// - Parameters:
    ///   - name: The name of the syntax to change with.
    ///   - isInitial: Whether the setting is initial.
    func setSyntax(name: String, isInitial: Bool = false) {
        
        let syntax: Syntax
        do {
            syntax = try SyntaxManager.shared.setting(name: name)
        } catch {
            // present error dialog if failed
            self.presentErrorAsSheet(error)
            return
        }
        
        guard syntax != self.syntaxParser.syntax else { return }
        
        SyntaxManager.shared.noteRecentSetting(name: name)
        
        // update
        self.syntaxFileExtension = syntax.extensions.first
        self.syntaxParser.update(syntax: syntax, name: name)
        self.invalidateMode()
        
        // skip notification when initial syntax was set on file open
        // to avoid redundant highlight parse due to async notification.
        guard !isInitial else { return }
        
        self.didChangeSyntax.send(name)
        self.invalidateRestorableState()
    }
    
    
    /// Updates syntax according to the given filename and shebang.
    ///
    /// - Parameters:
    ///   - filename: The new filename.
    func invalidateSyntax(filename: String) {
        
        guard
            let syntaxName = SyntaxManager.shared.settingName(documentName: filename, contents: self.textStorage.string),
            syntaxName != self.syntaxParser.name
        else { return }
        
        self.setSyntax(name: syntaxName)
    }
    
    
    // MARK: Action Messages
    
    /// Changes the document text encoding with sender's tag.
    @IBAction func changeEncoding(_ sender: NSMenuItem) {
        
        guard let fileEncoding = sender.representedObject as? FileEncoding else { return assertionFailure() }
        
        self.askChangingEncoding(to: fileEncoding)
    }
    
    
    /// Changes the line ending with sender's tag.
    @IBAction func changeLineEnding(_ sender: NSMenuItem) {
        
        guard let lineEnding = LineEnding.allCases[safe: sender.tag] else { return assertionFailure() }
        
        self.changeLineEnding(to: lineEnding)
    }
    
    
    /// Changes the syntax.
    @IBAction func changeSyntax(_ sender: NSMenuItem) {
        
        guard let name = sender.representedObject as? String else { return assertionFailure() }
        
        self.setSyntax(name: name)
    }
    
    
    /// Toggles the state of the read-only mode.
    @IBAction func toggleEditable(_ sender: Any?) {
        
        self.isEditable.toggle()
    }
    
    
    // MARK: Private Methods
    
    /// Creates a unique file URL for `autosavedContentsFileURL` to use in Autosave Elsewhere.
    ///
    /// Let the contents backup in `~/Library/Autosaved Information/` directory,
    /// since the default backup URL for the Save Elsewhere is the same directory as the fileURL,
    /// which doesn't work in a Sandbox environment.
    ///
    /// - Parameter url: The original saving URL.
    /// - Returns: A file URL.
    private nonisolated static func autosaveElsewhereURL(for url: URL) -> URL {
        
        let baseFileName = url.deletingPathExtension().lastPathComponent
            .replacing(/^\./, with: "", maxReplacements: 1)  // avoid file to be hidden
        
        // append a unique string to avoid overwriting another backup file with the same filename.
        let maxIdentifierLength = Int(NAME_MAX) - (baseFileName + " ()." + url.pathExtension).length
        let fileName = baseFileName + " (" + UUID().uuidString.prefix(maxIdentifierLength) + ")"
        
        return try! URL(for: .autosavedInformationDirectory, in: .userDomainMask, create: true)
            .appending(component: fileName)
            .appendingPathExtension(url.pathExtension)
    }
    
    
    /// Transfers the file information to UI.
    private func applyContentToWindow() {
        
        guard let viewController = self.viewController else { return }
        
        // update view
        if self.isVerticalText {
            viewController.verticalLayoutOrientation = true
        }
        
        // show alert if line endings are inconsistent
        if !self.lineEndingScanner.inconsistentLineEndings.isEmpty, !self.isBrowsingVersions {
            self.showInconsistentLineEndingAlert()
        }
    }
    
    
    /// Checks if the file contents did change since the last read.
    ///
    /// - Returns: A boolean whether the file did change and the content modification date if available.
    nonisolated private func checkFileContentsDidChange() throws -> (Bool, Date?) {
        
        guard var fileURL = self.fileURL else { throw CocoaError(.fileReadNoSuchFile) }
        
        fileURL.removeCachedResourceValue(forKey: .contentModificationDateKey)
        
        // check if the file contents were changed from the stored file data
        var didChange = false
        var modificationDate: Date?
        var coordinationError: NSError?
        var readingError: (any Error)?
        NSFileCoordinator(filePresenter: self).coordinate(readingItemAt: fileURL, options: .withoutChanges, error: &coordinationError) { newURL in  // FILE_ACCESS
            do {
                // ignore if file's modificationDate is the same as document's modificationDate
                modificationDate = try newURL.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
                guard modificationDate != self.fileModificationDate else { return }
                
                // check if file contents were changed from the stored file data
                let data = try Data(contentsOf: newURL)
                didChange = data != self.fileData
            } catch {
                readingError = error
            }
        }
        if let error = coordinationError ?? readingError {
            throw error
        }
        
        return (didChange, modificationDate)
    }
    
    
    /// Changes the text encoding by asking options to the user.
    ///
    /// - Parameter fileEncoding: The text encoding to change.
    func askChangingEncoding(to fileEncoding: FileEncoding) {
        
        assert(Thread.isMainThread)
        
        guard fileEncoding != self.fileEncoding else { return }
        
        // change encoding immediately if there is nothing to worry about
        if self.fileURL == nil || self.textStorage.string.isEmpty {
            return self.changeEncoding(to: fileEncoding)
        }
        
        // change encoding interactively
        self.performActivity(withSynchronousWaiting: true) { [unowned self] activityCompletionHandler in
            let completionHandler = { [weak self] didChange in
                if !didChange, let self {
                    // reset status bar selection for in case when the operation was invoked from the popup button in the status bar
                    self.fileEncoding = self.fileEncoding
                }
                activityCompletionHandler()
            }
            
            // ask whether just change the encoding or reinterpret document file
            let alert = NSAlert()
            alert.messageText = String(localized: "EncodingChangeAlert.message",
                                       defaultValue: "Text encoding change")
            alert.informativeText = String(localized: "EncodingChangeAlert.informativeText",
                                           defaultValue: "Do you want to convert or reinterpret this document using “\(fileEncoding.localizedName)”?")
            alert.addButton(withTitle: String(localized: "EncodingChangeAlert.button.convert",
                                              defaultValue: "Convert", comment: "button label"))
            alert.addButton(withTitle: String(localized: "EncodingChangeAlert.button.reinterpret",
                                              defaultValue: "Reinterpret", comment: "button label"))
            alert.addButton(withTitle: String(localized: "Cancel"))
            
            let documentWindow = self.windowForSheet!
            Task {
                let returnCode = await alert.beginSheetModal(for: documentWindow)
                switch returnCode {
                    case .alertFirstButtonReturn:  // = Convert
                        if !self.canBeConverted(to: fileEncoding) {
                            let error = LossyEncodingError(encoding: fileEncoding)
                            self.presentErrorAsSheet(error) { [unowned self] didRecover in
                                if didRecover {
                                    self.changeEncoding(to: fileEncoding)
                                    self.showWarningInspector()
                                }
                                completionHandler(didRecover)
                            }
                            return
                        }
                        self.changeEncoding(to: fileEncoding)
                        completionHandler(true)
                        
                    case .alertSecondButtonReturn:  // = Reinterpret
                        // ask whether discard unsaved changes
                        if self.isDocumentEdited {
                            let alert = NSAlert()
                            alert.messageText = String(localized: "UnsavedReinterpretationAlert.message",
                                                       defaultValue: "The document has unsaved changes.")
                            alert.informativeText = String(localized: "UnsavedReinterpretationAlert.informativeText",
                                                           defaultValue: "Are you sure you want to discard your changes and reopen the document using “\(fileEncoding.localizedName)”?", comment: "%@ is an encoding name")
                            alert.addButton(withTitle: String(localized: "Cancel"))
                            alert.addButton(withTitle: String(localized: "UnsavedReinterpretationAlert.button.discard",
                                                              defaultValue: "Discard Changes", comment: "button label"))
                            alert.buttons.last?.hasDestructiveAction = true
                            
                            let returnCode = await alert.beginSheetModal(for: documentWindow)
                            
                            guard returnCode == .alertSecondButtonReturn else {  // = Discard Changes
                                completionHandler(false)
                                return
                            }
                        }
                        
                        // reinterpret
                        do {
                            try self.reinterpret(encoding: fileEncoding.encoding)
                            completionHandler(true)
                        } catch {
                            NSSound.beep()
                            self.presentErrorAsSheet(error, recoveryHandler: completionHandler)
                        }
                        
                    case .alertThirdButtonReturn:  // = Cancel
                        completionHandler(false)
                        
                    default: preconditionFailure()
                }
            }
        }
    }
    
    
    /// Displays an alert about inconsistent line endings.
    private func showInconsistentLineEndingAlert() {
        
        guard
            !UserDefaults.standard[.suppressesInconsistentLineEndingAlert],
            !self.suppressesInconsistentLineEndingAlert
        else { return }
        
        self.performActivity(withSynchronousWaiting: true) { [unowned self] activityCompletionHandler in
            guard let documentWindow = self.windowForSheet else {
                activityCompletionHandler()
                assertionFailure()
                return
            }
            
            let isEditable = self.isEditable
            
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = String(localized: "InconsistentLineEndingAlert.message",
                                       defaultValue: "The document has inconsistent line endings.")
            alert.informativeText = isEditable
                ? String(localized: "InconsistentLineEndingAlert.informativeText",
                         defaultValue: "Do you want to convert all line endings to \(self.lineEnding.label), the most common line ending in this document?")
                : String(localized: "InconsistentLineEndingAlert.informativeText.notEditable",
                         defaultValue: "The most common line ending in this document is \(self.lineEnding.label).")
            if self.isEditable {
                alert.addButton(withTitle: String(localized: "InconsistentLineEndingAlert.button.convert",
                                                  defaultValue: "Convert",
                                                  comment: "button label"))
            }
            alert.addButton(withTitle: String(localized: "InconsistentLineEndingAlert.button.review",
                                              defaultValue: "Review",
                                              comment: "button label"))
            alert.addButton(withTitle: String(localized: "InconsistentLineEndingAlert.button.ignore",
                                              defaultValue: "Ignore",
                                              comment: "button label"))
            alert.showsSuppressionButton = true
            alert.suppressionButton?.title = String(localized: "InconsistentLineEndingAlert.suppressionButton",
                                                    defaultValue: "Don’t ask again for this document",
                                                    comment: "toggle button label")
            alert.showsHelp = true
            alert.helpAnchor = "inconsistent_line_endings"
            
            alert.beginSheetModal(for: documentWindow) { [unowned self] returnCode in
                if alert.suppressionButton?.state == .on {
                    self.suppressesInconsistentLineEndingAlert = true
                    self.invalidateRestorableState()
                    
                    // save xattr
                    if let fileURL = self.fileURL {
                        var error: NSError?
                        NSFileCoordinator(filePresenter: self).coordinate(writingItemAt: fileURL, options: .contentIndependentMetadataOnly, error: &error) { newURL in  // FILE_ACCESS
                            try? newURL.setExtendedAttribute(data: Data([1]), for: FileExtendedAttributeName.allowLineEndingInconsistency)
                        }
                    }
                }
                
                switch (returnCode, isEditable) {
                    case (.alertFirstButtonReturn, true):  // == Convert
                        self.changeLineEnding(to: self.lineEnding)
                    case (.alertSecondButtonReturn, true),
                         (.alertFirstButtonReturn, false):  // == Review
                        self.showWarningInspector()
                    case (.alertThirdButtonReturn, true),
                         (.alertSecondButtonReturn, false):  // == Ignore
                        break
                    default:
                        fatalError()
                }
                
                activityCompletionHandler()
            }
        }
    }
    
    
    /// Displays an alert about file modification by an external process.
    private func showUpdatedByExternalProcessAlert() {
        
        // do nothing if alert is already shown
        guard !self.isExternalUpdateAlertShown else { return }
        
        self.performActivity(withSynchronousWaiting: true) { [unowned self] activityCompletionHandler in
            guard let documentWindow = self.windowForSheet else {
                activityCompletionHandler()
                assertionFailure()
                return
            }
            
            self.isExternalUpdateAlertShown = true
            
            let alert = NSAlert()
            alert.messageText = self.isDocumentEdited
                ? String(localized: "UpdatedByExternalProcessAlert.message.edited",
                         defaultValue: "The file has been changed by another application. There are also unsaved changes in CotEditor.")
                : String(localized: "UpdatedByExternalProcessAlert.message",
                         defaultValue: "The file has been changed by another application.")
            alert.informativeText = String(localized: "UpdatedByExternalProcessAlert.informativeText",
                                           defaultValue: "Do you want to keep CotEditor’s edition or update it to the modified edition?")
            alert.addButton(withTitle: String(localized: "UpdatedByExternalProcessAlert.button.keep",
                                              defaultValue: "Keep CotEditor’s Edition",
                                              comment: "button label"))
            alert.addButton(withTitle: String(localized: "UpdatedByExternalProcessAlert.button.update",
                                              defaultValue: "Update",
                                              comment: "button label"))
            
            // mark the alert as critical in order to interrupt other sheets already attached
            if documentWindow.attachedSheet != nil {
                alert.alertStyle = .critical
            }
            
            alert.beginSheetModal(for: documentWindow) { [unowned self] returnCode in
                if returnCode == .alertSecondButtonReturn {  // == Revert
                    self.revert()
                }
                
                self.isExternalUpdateAlertShown = false
                activityCompletionHandler()
            }
        }
    }
    
    
    /// Updates the receiver's mode based on the current syntax.
    private func invalidateMode() {
        
        self.mode = ModeManager.shared.mode(for: self.syntaxParser.name)
    }
    
    
    /// Shows the warning inspector in the document window.
    private func showWarningInspector() {
        
        (self.windowController?.contentViewController as? WindowContentViewController)?.showInspector(pane: .warnings)
    }
}


// MARK: - Errors

private enum DocumentError: LocalizedError {
    
    case notEditable
    
    
    var errorDescription: String? {
        
        switch self {
            case .notEditable:
                String(localized: "DocumentError.notEditable.description",
                       defaultValue: "The document is not editable.")
        }
    }
    
    
    var recoverySuggestion: String? {
        
        switch self {
            case .notEditable:
                String(localized: "DocumentError.notEditable.recoverySuggestion",
                       defaultValue: "To make changes to the contents of the document, first allow editing it.")
        }
    }
    
    
    var helpAnchor: String? {
        
        switch self {
            case .notEditable:
                "howto_readonly"
        }
    }
}


enum ReinterpretationError: LocalizedError {
    
    case noFile
    case reinterpretationFailed(String.Encoding)
    
    
    var errorDescription: String? {
        
        switch self {
            case .noFile:
                String(localized: "ReinterpretationError.noFile.description",
                       defaultValue: "The document doesn’t have a file to reinterpret.")
                
            case .reinterpretationFailed(let encoding):
                String(localized: "ReinterpretationError.reinterpretationFailed.description",
                       defaultValue: "The document could not be reinterpreted using text encoding “\(String.localizedName(of: encoding)).”")
        }
    }
    
    
    var recoverySuggestion: String? {
        
        switch self {
            case .noFile:
                nil
                
            case .reinterpretationFailed:
                String(localized: "ReinterpretationError.reinterpretationFailed.recoverySuggestion",
                       defaultValue: "The document may have been saved using a different text encoding, or it may not be a text file.")
        }
    }
}


struct LossyEncodingError: LocalizedError, RecoverableError {
    
    var encoding: FileEncoding
    
    
    var errorDescription: String? {
        
        String(localized: "LossyEncodingError.description",
               defaultValue: "The document contains characters incompatible with “\(self.encoding.localizedName).”")
    }
    
    
    var recoverySuggestion: String? {
        
        String(localized: "LossyEncodingError.recoverySuggestion",
               defaultValue: "Incompatible characters are substituted or deleted in saving. Do you want to change the text encoding and review the incompatible characters?")
    }
    
    
    var recoveryOptions: [String] {
        
        [String(localized: "LossyEncodingError.recoveryOption.change", defaultValue: "Change Encoding", comment: "button label"),
         String(localized: "Cancel")]
    }
    
    
    func attemptRecovery(optionIndex recoveryOptionIndex: Int) -> Bool {
        
        (recoveryOptionIndex == 0)
    }
}


private struct DocumentSavingError: LocalizedError, CustomNSError {
    
    enum Code {
        
        case lossyEncoding(FileEncoding)
    }
    
    
    static let errorDomain: String = "CotEditor.DocumentSavingError"
    
    var code: Code
    var attempter: Document
    
    
    init(_ code: Code, attempter: Document) {
        
        self.code = code
        self.attempter = attempter
    }
    
    
    var errorDescription: String? {
        
        switch self.code {
            case .lossyEncoding(let fileEncoding):
                LossyEncodingError(encoding: fileEncoding).errorDescription
        }
    }
    
    
    var failureReason: String? {
        
        // shown when an autosave failed
        self.errorDescription
    }
    
    
    var recoverySuggestion: String? {
        
        String(localized: "DocumentSavingError.lossyEncoding.recoverySuggestion",
               defaultValue: "Incompatible characters are substituted or deleted in saving. Do you want to continue processing?")
    }
    
    
    var recoveryOptions: [String] {
        
        switch self.code {
            case .lossyEncoding:
                [String(localized: "DocumentSavingError.lossyEncoding.recoveryOption.save",
                        defaultValue: "Save Available Text", comment: "button label"),
                 String(localized: "DocumentSavingError.lossyEncoding.recoveryOption.review",
                        defaultValue: "Review Incompatible Characters", comment: "button label"),
                 String(localized: "Cancel")]
        }
    }
    
    
    var errorUserInfo: [String: Any] {
        
        [
            NSRecoveryAttempterErrorKey: self.attempter,
            NSLocalizedDescriptionKey: self.errorDescription!,
            NSLocalizedFailureErrorKey: self.failureReason!,
            NSLocalizedRecoverySuggestionErrorKey: self.recoverySuggestion!,
            NSLocalizedRecoveryOptionsErrorKey: self.recoveryOptions,
        ]
    }
}
