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
//  © 2014-2024 1024jp
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
import OSLog

final class Document: NSDocument, AdditionalDocumentPreparing, EncodingChanging {
    
    // MARK: Enums
    
    private enum SerializationKey {
        
        static let allowsLossySaving = "allowsLossySaving"
        static let isTransient = "isTransient"
        static let isVerticalText = "isVerticalText"
        static let suppressesInconsistentLineEndingAlert = "suppressesInconsistentLineEndingAlert"
        static let syntax = "syntax"
        static let originalContentString = "originalContentString"
    }
    
    
    // MARK: Public Properties
    
    var isTransient = false  // untitled & empty document that was created automatically
    var isVerticalText = false
    
    
    // MARK: Readonly Properties
    
    let textStorage = NSTextStorage()
    let syntaxParser: SyntaxParser
    @Published private(set) var fileEncoding: FileEncoding
    @Published private(set) var lineEnding: LineEnding
    @Published private(set) var fileAttributes: DocumentFile.Attributes?
    
    let lineEndingScanner: LineEndingScanner
    private(set) lazy var analyzer = DocumentAnalyzer(document: self)
    private(set) lazy var selection = TextSelection(document: self)
    
    let didChangeSyntax = PassthroughSubject<String, Never>()
    
    
    // MARK: Private Properties
    
    private lazy var printPanelAccessoryController: PrintPanelAccessoryController = NSStoryboard(name: "PrintPanelAccessory", bundle: nil).instantiateInitialController()!
    
    private var readingEncoding: String.Encoding?  // encoding to read document file
    private var fileData: Data?
    private var shouldSaveEncodingXattr = true
    private var isExecutable = false
    private let saveOptions = SaveOptions()
    private var suppressesInconsistentLineEndingAlert = false
    private var isExternalUpdateAlertShown = false
    private var allowsLossySaving = false
    
    private lazy var urlDetector = URLDetector(textStorage: self.textStorage)
    
    private var syntaxUpdateObserver: AnyCancellable?
    private var textStorageObserver: AnyCancellable?
    private var defaultObservers: Set<AnyCancellable> = []
    
    private var lastSavedData: Data?  // temporal data used only within saving process
    
    
    
    // MARK: Lifecycle
    
    override init() {
        
        // [caution] This method may be called from a background thread due to concurrent-opening.
        
        let lineEnding = LineEnding.allCases[safe: UserDefaults.standard[.lineEndCharCode]] ?? .lf
        self.lineEnding = lineEnding
        
        var syntaxName = UserDefaults.standard[.syntax]
        let syntax = SyntaxManager.shared.setting(name: syntaxName)
        syntaxName = (syntax == nil) ? SyntaxName.none : syntaxName
        self.syntaxParser = SyntaxParser(textStorage: self.textStorage, syntax: syntax ?? Syntax.none, name: syntaxName)
        
        // use the encoding selected by the user in the open panel, if exists
        self.fileEncoding = EncodingManager.shared.defaultEncoding
        self.readingEncoding = (DocumentController.shared as! DocumentController).accessorySelectedEncoding
        
        // observe for inconsistent line endings
        self.lineEndingScanner = .init(textStorage: self.textStorage, lineEnding: lineEnding)
        
        super.init()
        
        self.lineEndingScanner.observe(lineEnding: self.$lineEnding)
        
        // auto-link URLs in the content
        if UserDefaults.standard[.autoLinkDetection] {
            self.urlDetector.isEnabled = true
        }
        self.defaultObservers = [
            UserDefaults.standard.publisher(for: .autoLinkDetection)
                .sink { [weak self] in self?.urlDetector.isEnabled = $0 }
        ]
        
        // observe syntax update
        self.syntaxUpdateObserver = SyntaxManager.shared.didUpdateSetting
            .filter { [weak self] change in change.old == self?.syntaxParser.name }
            .sink { [weak self] change in self?.setSyntax(name: change.new ?? SyntaxName.none) }
    }
    
    
    deinit {
        self.syntaxParser.cancel()
        self.analyzer.cancel()
        self.urlDetector.cancel()
    }
    
    
    override func encodeRestorableState(with coder: NSCoder, backgroundQueue queue: OperationQueue) {
        
        super.encodeRestorableState(with: coder, backgroundQueue: queue)
        
        coder.encode(self.allowsLossySaving, forKey: SerializationKey.allowsLossySaving)
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
    
    override class var autosavesInPlace: Bool {
        
        // avoid changing the value while the application is running
        struct InitialValue { static let autosavesInPlace = UserDefaults.standard[.enablesAutosaveInPlace] }
        
        return InitialValue.autosavesInPlace
    }
    
    
    override class var usesUbiquitousStorage: Bool {
        
        // pretend as if iCloud storage is disabled to let the system give up opening the open panel on launch (2018-02 macOS 10.13)
        if UserDefaults.standard[.noDocumentOnLaunchOption] != .openPanel,
           NSDocumentController.shared.documents.isEmpty
        {
            return false
        }
        
        return super.usesUbiquitousStorage
    }
    
    
    override class func canConcurrentlyReadDocuments(ofType: String) -> Bool {
        
        true
    }
    
    
    override func canAsynchronouslyWrite(to url: URL, ofType typeName: String, for saveOperation: NSDocument.SaveOperationType) -> Bool {
        
        true
    }
    
    
    override var autosavedContentsFileURL: URL? {  // nonisolated
        
        get {
            // modify place to create backup file to save backup file always in `~/Library/Autosaved Information/` directory.
            // -> The default backup URL is the same directory as the fileURL
            //    and it doesn't work with the modern Sandboxing system.
            if !Self.autosavesInPlace,
               self.hasUnautosavedChanges,
               super.autosavedContentsFileURL == nil,
               let fileURL = self.fileURL
            {
                // store directory URL to avoid finding Autosaved Information directory every time
                struct AutosaveDirectory {
                    
                    static let url = try! URL(for: .autosavedInformationDirectory, in: .userDomainMask, create: true)
                }
                
                let baseFileName = fileURL.deletingPathExtension().lastPathComponent
                    .replacing(/^\./, with: "", maxReplacements: 1)  // avoid file to be hidden
                
                // append an unique string to avoid overwriting another backup file with the same filename.
                let maxIdentifierLength = Int(NAME_MAX) - (baseFileName + " ()." + fileURL.pathExtension).length
                let fileName = baseFileName + " (" + UUID().uuidString.prefix(maxIdentifierLength) + ")"
                
                super.autosavedContentsFileURL =  AutosaveDirectory.url
                    .appending(component: fileName)
                    .appendingPathExtension(fileURL.pathExtension)
            }
            
            return super.autosavedContentsFileURL
        }
        
        set {
            super.autosavedContentsFileURL = newValue
        }
    }
    
    
    override func makeWindowControllers() {
        
        if self.windowControllers.isEmpty {  // -> A transient document already has one.
            let windowController = DocumentWindowController(document: self)
            self.addWindowController(windowController)
            
            // avoid showing "edited" indicator in the close button when the content is empty
            if !Self.autosavesInPlace {
                self.textStorageObserver = NotificationCenter.default
                    .publisher(for: NSTextStorage.didProcessEditingNotification, object: self.textStorage)
                    .map { $0.object as! NSTextStorage }
                    .map(\.string.isEmpty)
                    .removeDuplicates()
                    .receive(on: RunLoop.main)
                    .assign(to: \.isWhitePaper, on: windowController)
            }
        }
        
        self.applyContentToWindow()
    }
    
    
    override nonisolated func fileNameExtension(forType typeName: String, saveOperation: NSDocument.SaveOperationType) -> String? {
        
        if !self.isDraft, let pathExtension = self.fileURL?.pathExtension {
            return pathExtension
        }
        
        return self.syntaxParser.syntax.extensions.first
    }
    
    
    override func revert(toContentsOf url: URL, ofType typeName: String) throws {
        
        // once force-close all sheets
        // -> Presented errors will be displayed again after the revert automatically. (since OS X 10.10)
        self.windowForSheet?.sheets.forEach { $0.close() }
        
        let selection = self.textStorage.editorSelection
        
        try super.revert(toContentsOf: url, ofType: typeName)
        
        // do nothing if already no textView exists
        guard let selection else { return }
        
        self.applyContentToWindow()
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
    
    
    override func read(from url: URL, ofType typeName: String) throws {  // nonisolated
        
        // [caution] This method may be called from a background thread due to concurrent-opening.
        
        let strategy: DocumentFile.EncodingStrategy = {
            if let encoding = self.readingEncoding {
                return .specific(encoding)
            }
            
            var encodingPriority = EncodingManager.shared.fileEncodings.compactMap { $0?.encoding }
            let isInitialOpen = (self.fileData == nil) && (self.textStorage.length == 0)
            if !isInitialOpen {  // prioritize the current encoding
                encodingPriority.insert(self.fileEncoding.encoding, at: 0)
            }
            
            return .automatic(priority: encodingPriority, refersToTag: UserDefaults.standard[.referToEncodingTag])
        }()
        
        // .readingEncoding is only valid once
        self.readingEncoding = nil
        
        let file = try DocumentFile(fileURL: url, encodingStrategy: strategy)  // FILE_ACCESS
        
        // store file data in order to check the file content identity in `presentedItemDidChange()`
        self.fileData = file.data
        
        // use file attributes only if `fileURL` exists
        // -> The passed-in `url` in this method can point to a file that isn't the real document file,
        //    for example on resuming an unsaved document.
        if self.fileURL != nil {
            self.fileAttributes = file.attributes
            self.isExecutable = file.attributes.permissions.user.contains(.execute)
        }
        
        // do not save `com.apple.TextEncoding` extended attribute if it doesn't exists
        self.shouldSaveEncodingXattr = (file.xattrEncoding != nil)
        
        // set text orientation state
        // -> Ignore if no metadata found to avoid restoring to the horizontal layout while editing unwontedly.
        if UserDefaults.standard[.savesTextOrientation], file.isVerticalText {
            self.isVerticalText = true
        }
        
        if file.allowsInconsistentLineEndings {
            self.suppressesInconsistentLineEndingAlert = true
        }
        
        // update textStorage
        self.textStorage.replaceContent(with: file.string)
        
        // set read values
        self.fileEncoding = file.fileEncoding
        self.allowsLossySaving = false
        self.lineEnding = self.lineEndingScanner.majorLineEnding ?? self.lineEnding  // keep default if no line endings are found
        
        // determine syntax (only on the first file open)
        if self.windowForSheet == nil {
            let syntaxName = SyntaxManager.shared.settingName(documentName: url.lastPathComponent, content: file.string) ?? SyntaxName.none
            self.setSyntax(name: syntaxName, isInitial: true)
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
        
        // break undo grouping
        let textViews = self.textStorage.layoutManagers.compactMap(\.textViewForBeginningOfSelection)
        for textView in textViews {
            textView.breakUndoCoalescing()
        }
        
        // trim trailing whitespace if needed
        if !saveOperation.isAutosave, UserDefaults.standard[.autoTrimsTrailingWhitespace] {
            textViews.first?.trimTrailingWhitespace(ignoresEmptyLines: !UserDefaults.standard[.trimsWhitespaceOnlyLines])
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
               let syntaxName = SyntaxManager.shared.settingName(documentName: url.lastPathComponent, content: self.textStorage.string)
            {
                // -> Due to the async-saving, self.textStorage can be changed from the actual saved contents.
                //    But we don't care about that.
                self.setSyntax(name: syntaxName)
            }
            
            if !saveOperation.isAutosave {
                ScriptManager.shared.dispatch(event: .documentSaved, document: self.objectSpecifier)
            }
        }
    }
    
    
    override func writeSafely(to url: URL, ofType typeName: String, for saveOperation: NSDocument.SaveOperationType) throws {  // nonisolated
        
        // check if the content can be saved with the current text encoding.
        guard saveOperation.isAutosaveElsewhere || self.allowsLossySaving || self.canBeConverted() else {
            throw DocumentSavingError(.lossyEncoding(self.fileEncoding), attempter: self)
        }
        
        try super.writeSafely(to: url, ofType: typeName, for: saveOperation)
        
        if saveOperation != .autosaveElsewhereOperation {
            // get the latest file attributes
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: url.path)  // FILE_ACCESS
                self.fileAttributes = DocumentFile.Attributes(dictionary: attributes)
            } catch {
                assertionFailure(error.localizedDescription)
            }
            
            // store file data in order to check the file content identity in `presentedItemDidChange()`
            assert(self.lastSavedData != nil)
            self.fileData = self.lastSavedData
        }
        self.lastSavedData = nil
    }
    
    
    override func fileAttributesToWrite(to url: URL, ofType typeName: String, for saveOperation: NSDocument.SaveOperationType, originalContentsURL absoluteOriginalContentsURL: URL?) throws -> [String: Any] {  // nonisolated
        
        var attributes = try super.fileAttributesToWrite(to: url, ofType: typeName, for: saveOperation, originalContentsURL: absoluteOriginalContentsURL)
        
        // give the execute permission if user requested
        if self.saveOptions.isExecutable, !saveOperation.isAutosave {
            var permissions = self.fileAttributes?.permissions ?? FilePermissions(mask: 0o644)  // ???: Is the default permission really always 644?
            permissions.user.insert(.execute)
            attributes[FileAttributeKey.posixPermissions] = permissions.mask
        }
        
        // save document state to the extended file attributes
        var xattrs: [String: Data] = [:]
        if self.shouldSaveEncodingXattr {
            xattrs[FileExtendedAttributeName.encoding] = self.fileEncoding.encoding.xattrEncodingData
        }
        if self.suppressesInconsistentLineEndingAlert {
            xattrs[FileExtendedAttributeName.allowLineEndingInconsistency] = Data([1])
        }
        if UserDefaults.standard[.savesTextOrientation] {
            xattrs[FileExtendedAttributeName.verticalText] = self.isVerticalText ? Data([1]) : nil
        }
        if !xattrs.isEmpty {
            attributes[FileAttributeKey.extendedAttributes.rawValue] = xattrs
        }
        
        return attributes
    }
    
    
    override func runModalSavePanel(for saveOperation: NSDocument.SaveOperationType, delegate: Any?, didSave didSaveSelector: Selector?, contextInfo: UnsafeMutableRawPointer?) {
        
        self.saveOptions.isExecutable = self.isExecutable
        
        let context = DelegateContext(delegate: delegate, selector: didSaveSelector, contextInfo: contextInfo)
        super.runModalSavePanel(for: saveOperation, delegate: self, didSave: #selector(document(_:didSave:contextInfo:)), contextInfo: bridgeWrapped(context))
    }
    
    
    override var shouldRunSavePanelWithAccessoryView: Bool {
        
        false
    }
    
    
    override func prepareSavePanel(_ savePanel: NSSavePanel) -> Bool {
        
        savePanel.allowsOtherFileTypes = true
        savePanel.allowedContentTypes = self.fileType
            .flatMap { self.fileNameExtension(forType: $0, saveOperation: .saveOperation) }
            .flatMap { UTType(filenameExtension: $0) }
            .flatMap { [$0] } ?? []
        
        // set accessory view
        let accessory = SavePanelAccessory(options: self.saveOptions)
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
        
        // suppress save dialog if content is empty and not saved explicitly
        suppression: if (self.isDraft || self.fileURL == nil), self.textStorage.string.isEmpty {
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
        
        self.textStorageObserver?.cancel()
        
        super.close()
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
        let printView = PrintTextView(info: info)
        
        printView.setLayoutOrientation(viewController.verticalLayoutOrientation ? .vertical : .horizontal)
        printView.baseWritingDirection = viewController.writingDirection
        printView.ligature = self.textView?.ligature ?? .standard
        printView.font = viewController.font?.withSize(UserDefaults.standard[.printFontSize])
        
        // [caution] need to set string after setting other properties
        printView.string = self.textStorage.string
        if let selectedRanges = self.textView?.selectedRanges {
            printView.selectedRanges = selectedRanges
        }
        
        if let highlights = self.textStorage.layoutManagers.first?.syntaxHighlights(), !highlights.isEmpty {
            printView.layoutManager?.apply(highlights: highlights, range: printView.string.range)
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
                self.showWarningInspector()
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
    
    override func presentedItemDidChange() {  // nonisolated
        
        // [caution] DO NOT invoke `super.presentedItemDidChange()` that reverts document automatically if autosavesInPlace is enabled.
//        super.presentedItemDidChange()
        
        guard
            UserDefaults.standard[.documentConflictOption] != .ignore,
            !self.isExternalUpdateAlertShown,  // don't check twice if already notified
            var fileURL = self.fileURL
        else { return }
        
        // check if the file content was changed from the stored file data
        var didChange = false
        var modificationDate: Date?
        var error: NSError?
        NSFileCoordinator(filePresenter: self).coordinate(readingItemAt: fileURL, options: .withoutChanges, error: &error) { newURL in  // FILE_ACCESS
            do {
                // ignore if file's modificationDate is the same as document's modificationDate
                fileURL.removeCachedResourceValue(forKey: .contentModificationDateKey)
                modificationDate = try fileURL.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
                guard modificationDate != self.fileModificationDate else { return }
                
                // check if file contents was changed from the stored file data
                let data = try Data(contentsOf: newURL)
                didChange = data != self.fileData
            } catch {
                assertionFailure(error.localizedDescription)
            }
        }
        if let error {
            assertionFailure(error.localizedDescription)
        }
        
        guard didChange else {
            // update the document's fileModificationDate for a workaround (2014-03 by 1024jp)
            // -> If not, an alert shows up when user saves the file.
            guard let modificationDate else { return }
            DispatchQueue.main.async { [weak self] in
                if self?.fileModificationDate?.compare(modificationDate) == .orderedAscending {
                    self?.fileModificationDate = modificationDate
                }
            }
            return
        }
        
        // notify about external file update
        Task {
            switch UserDefaults.standard[.documentConflictOption] {
                case .ignore:
                    assertionFailure()
                case .notify:
                    await self.showUpdatedByExternalProcessAlert()
                case .revert:
                    await self.revertWithoutAsking()
            }
        }
    }
    
    
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        
        switch menuItem.action {
            case #selector(changeEncoding(_:)):
                menuItem.state = (menuItem.representedObject as? FileEncoding == self.fileEncoding) ? .on : .off
                
            case #selector(changeLineEnding(_:)):
                menuItem.state = (menuItem.tag == self.lineEnding.index) ? .on : .off
                
            case #selector(changeSyntax(_:)):
                menuItem.state = (menuItem.representedObject as? String == self.syntaxParser.name) ? .on : .off
                
            default: break
        }
        
        return super.validateMenuItem(menuItem)
    }
    
    
    /// Opens an existing document file (alternative methods for `init(contentsOf:ofType:)`).
    nonisolated func didMakeDocumentForExistingFile(url: URL) {
        
        // [caution] This method may be called from a background thread due to concurrent-opening.
        // -> This method won't be invoked on Resume. (2015-01-26)
        
        Task {
            ScriptManager.shared.dispatch(event: .documentOpened, document: await self.objectSpecifier)
        }
    }
    
    
    
    // MARK: Public Methods
    
    /// The view controller represents document.
    var viewController: DocumentViewController? {
        
        (self.windowControllers.first?.contentViewController as? WindowContentViewController)?.documentViewController
    }
    
    
    /// The text view currently focused.
    var textView: NSTextView? {
        
        self.viewController?.focusedTextView
    }
    
    
    /// Checks if the content can be converted in the given encoding without loss of information.
    ///
    /// - Parameter fileEncoding: The text encoding to test, or `nil` to test with the current file encoding.
    /// - Returns: `true` if the content can be encoded in encoding without loss of information; otherwise, `false`.
    func canBeConverted(to fileEncoding: FileEncoding? = nil) -> Bool {
        
        self.textStorage.string.canBeConverted(to: (fileEncoding ?? self.fileEncoding).encoding)
    }
    
    
    /// Reinterprets the document file with the desired encoding.
    ///
    /// - Parameter encoding: The text encoding to read.
    /// - Throws: `ReinterpretationError`
    func reinterpret(encoding: String.Encoding) throws {
        
        guard let fileURL = self.fileURL else {
            throw ReinterpretationError.noFile
        }
        
        // do nothing if given encoding is the same as current one
        if encoding == self.fileEncoding.encoding { return }
        
        // reinterpret
        self.readingEncoding = encoding
        do {
            try self.revert(toContentsOf: fileURL, ofType: self.fileType!)
            
        } catch {
            self.readingEncoding = nil
            
            throw ReinterpretationError.reinterpretationFailed(encoding)
        }
    }
    
    
    /// Changes the text encoding and registers the process to the undo manager.
    ///
    /// - Parameters:
    ///   - fileEncoding: The text encoding to change with.
    @MainActor func changeEncoding(to fileEncoding: FileEncoding) {
        
        assert(Thread.isMainThread)
        
        guard fileEncoding != self.fileEncoding else { return }
        
        // register undo
        if let undoManager = self.undoManager {
            undoManager.registerUndo(withTarget: self) { [currentFileEncoding = self.fileEncoding, shouldSaveEncodingXattr = self.shouldSaveEncodingXattr] target in
                target.fileEncoding = currentFileEncoding
                target.shouldSaveEncodingXattr = shouldSaveEncodingXattr
                target.allowsLossySaving = false
                
                // register redo
                target.undoManager?.registerUndo(withTarget: target) { $0.changeEncoding(to: fileEncoding) }
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
    @MainActor func changeLineEnding(to lineEnding: LineEnding) {
        
        assert(Thread.isMainThread)
        
        guard lineEnding != self.lineEnding ||
                !self.lineEndingScanner.inconsistentLineEndings.isEmpty
        else { return }
        
        // register undo
        if let undoManager = self.undoManager {
            let selectedRanges = self.textStorage.layoutManagers.compactMap(\.textViewForBeginningOfSelection).map(\.selectedRange)
            undoManager.registerUndo(withTarget: self) { [currentLineEnding = self.lineEnding, string = self.textStorage.string] target in
                target.textStorage.replaceContent(with: string)
                target.lineEnding = currentLineEnding
                for (textView, range) in zip(target.textStorage.layoutManagers.compactMap(\.textViewForBeginningOfSelection), selectedRanges) {
                    textView.selectedRange = range
                }
                
                // register redo
                target.undoManager?.registerUndo(withTarget: target) { $0.changeLineEnding(to: lineEnding) }
            }
            undoManager.setActionName(String(localized: "Line Endings to \(lineEnding.label)",
                                             table: "MainMenu", comment: "undo action name"))
        }
        
        // update line endings in text storage
        let string = self.textStorage.string.replacingLineEndings(with: lineEnding)
        self.textStorage.replaceContent(with: string, keepsSelection: true)
        
        // update line ending
        self.lineEnding = lineEnding
    }
    
    
    /// Changes the syntax to one with the given name.
    ///
    /// - Parameters:
    ///   - name: The name of the syntax to change with.
    ///   - isInitial: Whether the setting is initial.
    func setSyntax(name: String, isInitial: Bool = false) {
        
        guard
            let syntax = SyntaxManager.shared.setting(name: name),
            syntax != self.syntaxParser.syntax
        else { return }
        
        // update
        self.syntaxParser.update(syntax: syntax, name: name)
        
        // skip notification when initial syntax was set on file open
        // to avoid redundant highlight parse due to async notification.
        guard !isInitial else { return }
        
        self.didChangeSyntax.send(name)
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
    
    
    /// Shows the sharing picker interface.
    @IBAction func shareDocument(_ sender: Any?) {
        
        guard let contentView = self.viewController?.view else { return assertionFailure() }
        
        // -> Get titlebar view to mimic the behavior in iWork apps... (macOS 14 on 2023-12)
        let view = contentView.window?.standardWindowButton(.closeButton)?.superview ?? contentView
        
        NSSharingServicePicker(items: [self])
            .show(relativeTo: .zero, of: view, preferredEdge: .minY)
    }
    
    
    
    // MARK: Private Methods
    
    /// Callback from save panel after calling `runModalSavePanel(for:didSave:contextInfo)`.
    @objc private func document(_ document: NSDocument, didSave didSaveSuccessfully: Bool, contextInfo: UnsafeMutableRawPointer) {
        
        if didSaveSuccessfully {
            self.isExecutable = self.saveOptions.isExecutable
        }
        
        // manually invoke the original delegate method
        guard let context: DelegateContext = bridgeUnwrapped(contextInfo) else { return assertionFailure() }
        
        context.perform(from: self, flag: didSaveSuccessfully)
    }
    
    
    /// Transfers the file information to UI.
    private func applyContentToWindow() {
        
        guard let viewController = self.viewController else { return }
        
        // update view
        viewController.invalidateStyleInTextStorage()
        if self.isVerticalText {
            viewController.verticalLayoutOrientation = true
        }
        
        // show alert if line endings are inconsistent
        if !self.lineEndingScanner.inconsistentLineEndings.isEmpty, !self.isBrowsingVersions {
            self.showInconsistentLineEndingAlert()
        }
    }
    
    
    /// Changes the text encoding by asking options to the user.
    ///
    /// - Parameter fileEncoding: The text encoding to change.
    @MainActor func askChangingEncoding(to fileEncoding: FileEncoding) {
        
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
    @MainActor private func showInconsistentLineEndingAlert() {
        
        assert(Thread.isMainThread)
        
        guard
            !UserDefaults.standard[.suppressesInconsistentLineEndingAlert],
            !self.suppressesInconsistentLineEndingAlert
        else { return }
        
        guard let documentWindow = self.windowForSheet else { return assertionFailure() }
        
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = String(localized: "InconsistentLineEndingAlert.message",
                                   defaultValue: "The document has inconsistent line endings.")
        alert.informativeText = String(localized: "InconsistentLineEndingAlert.informativeText",
                                       defaultValue: "Do you want to convert all line endings to \(self.lineEnding.label), the most common line endings in this document?")
        alert.addButton(withTitle: String(localized: "InconsistentLineEndingAlert.button.convert",
                                          defaultValue: "Convert",
                                          comment: "button label"))
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
            
            switch returnCode {
                case .alertFirstButtonReturn:  // == Convert
                    self.changeLineEnding(to: self.lineEnding)
                case .alertSecondButtonReturn:  // == Review
                    self.showWarningInspector()
                case .alertThirdButtonReturn:  // == Ignore
                    break
                default:
                    fatalError()
            }
        }
    }
    
    
    /// Displays an alert about file modification by an external process.
    @MainActor private func showUpdatedByExternalProcessAlert() {
        
        // do nothing if alert is already shown
        guard !self.isExternalUpdateAlertShown else { return }
        
        self.performActivity(withSynchronousWaiting: true) { [unowned self] activityCompletionHandler in
            self.isExternalUpdateAlertShown = true
            
            guard let documentWindow = self.windowForSheet else {
                activityCompletionHandler()
                assertionFailure()
                return
            }
            
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
                    self.revertWithoutAsking()
                }
                
                self.isExternalUpdateAlertShown = false
                activityCompletionHandler()
            }
        }
    }
    
    
    /// Reverts the receiver with current document file without asking to the user in advance.
    @MainActor private func revertWithoutAsking() {
        
        guard
            let fileURL = self.fileURL,
            let fileType = self.fileType
        else { return }
        
        do {
            try self.revert(toContentsOf: fileURL, ofType: fileType)
        } catch {
            self.presentErrorAsSheet(error)
        }
    }
    
    
    /// Shows the warning inspector in the document window.
    @MainActor private func showWarningInspector() {
        
        (self.windowControllers.first?.contentViewController as? WindowContentViewController)?.showInspector(pane: .warnings)
    }
}



// MARK: - Errors

private enum ReinterpretationError: LocalizedError {
    
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
