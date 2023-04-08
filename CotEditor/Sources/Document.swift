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

import Combine
import Cocoa
import UniformTypeIdentifiers
import SwiftUI

final class Document: NSDocument, AdditionalDocumentPreparing, EncodingHolder {
    
    // MARK: Enums
    
    private enum SerializationKey {
        
        static let isVerticalText = "isVerticalText"
        static let isTransient = "isTransient"
        static let suppressesInconsistentLineEndingAlert = "suppressesInconsistentLineEndingAlert"
        static let syntaxStyle = "syntaxStyle"
        static let originalContentString = "originalContentString"
    }
    
    
    // MARK: Public Properties
    
    var isVerticalText = false
    var isTransient = false  // untitled & empty document that was created automatically
    
    
    // MARK: Readonly Properties
    
    let textStorage = NSTextStorage()
    let syntaxParser: SyntaxParser
    @Published private(set) var fileEncoding: FileEncoding
    @Published private(set) var lineEnding: LineEnding
    @Published private(set) var fileAttributes: [FileAttributeKey: Any]?
    
    let lineEndingScanner: LineEndingScanner
    private(set) lazy var selection = TextSelection(document: self)
    private(set) lazy var analyzer = DocumentAnalyzer(document: self)
    private(set) lazy var incompatibleCharacterScanner = IncompatibleCharacterScanner(document: self)
    let urlDetector: URLDetector
    
    let didChangeSyntaxStyle = PassthroughSubject<String, Never>()
    
    
    // MARK: Private Properties
    
    private lazy var printPanelAccessoryController: PrintPanelAccessoryController = NSStoryboard(name: ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 13 ? "PrintPanelAccessoryVentura" : "PrintPanelAccessory").instantiateInitialController()!
    
    private var readingEncoding: String.Encoding?  // encoding to read document file
    private var suppressesInconsistentLineEndingAlert = false
    private var isExternalUpdateAlertShown = false
    private var fileData: Data?
    private var shouldSaveEncodingXattr = true
    private var isExecutable = false
    private let saveOptions = SaveOptions()
    
    private var syntaxUpdateObserver: AnyCancellable?
    private var textStorageObserver: AnyCancellable?
    private var windowObserver: AnyCancellable?
    private var defaultObservers: Set<AnyCancellable> = []
    
    private var lastSavedData: Data?  // temporal data used only within saving process
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    override init() {
        
        // [caution] This method may be called from a background thread due to concurrent-opening.
        
        let defaultEncoding = String.Encoding(rawValue: UserDefaults.standard[.encodingInNew])
        let encoding = String.availableStringEncodings.contains(defaultEncoding) ? defaultEncoding : .utf8
        self.fileEncoding = FileEncoding(encoding: encoding, withUTF8BOM: (encoding == .utf8) && UserDefaults.standard[.saveUTF8BOM])
        
        let lineEnding = LineEnding.allCases[safe: UserDefaults.standard[.lineEndCharCode]] ?? .lf
        self.lineEnding = lineEnding
        let style = SyntaxManager.shared.setting(name: UserDefaults.standard[.syntaxStyle]) ?? SyntaxStyle()
        self.syntaxParser = SyntaxParser(textStorage: self.textStorage, style: style)
        
        // use the encoding selected by the user in the open panel, if exists
        self.readingEncoding = (DocumentController.shared as! DocumentController).accessorySelectedEncoding
        
        // observe for inconsistent line endings
        self.lineEndingScanner = .init(textStorage: self.textStorage, lineEnding: lineEnding)
        
        // auto-link URLs in the content
        self.urlDetector = URLDetector(textStorage: self.textStorage)
        UserDefaults.standard.publisher(for: .autoLinkDetection, initial: true)
            .assign(to: \.isEnabled, on: self.urlDetector)
            .store(in: &self.defaultObservers)
        
        super.init()
        
        self.lineEndingScanner.observe(lineEnding: self.$lineEnding)
        
        // observe syntax style update
        self.syntaxUpdateObserver = SyntaxManager.shared.didUpdateSetting
            .filter { [weak self] (change) in change.old == self?.syntaxParser.style.name }
            .sink { [weak self] (change) in self?.setSyntaxStyle(name: change.new ?? BundledStyleName.none) }
    }
    
    
    override func encodeRestorableState(with coder: NSCoder, backgroundQueue queue: OperationQueue) {
        
        super.encodeRestorableState(with: coder, backgroundQueue: queue)
        
        coder.encode(self.isVerticalText, forKey: SerializationKey.isVerticalText)
        coder.encode(self.isTransient, forKey: SerializationKey.isTransient)
        coder.encode(self.suppressesInconsistentLineEndingAlert, forKey: SerializationKey.suppressesInconsistentLineEndingAlert)
        coder.encode(self.syntaxParser.style.name, forKey: SerializationKey.syntaxStyle)
        
        // store unencoded string but only when incompatible
        if !self.textStorage.string.canBeConverted(to: self.fileEncoding.encoding) {
            coder.encode(self.textStorage.string, forKey: SerializationKey.originalContentString)
        }
    }
    
    
    override func restoreState(with coder: NSCoder) {
        
        super.restoreState(with: coder)
        
        if coder.containsValue(forKey: SerializationKey.isVerticalText) {
            self.isVerticalText = coder.decodeBool(forKey: SerializationKey.isVerticalText)
        }
        if coder.containsValue(forKey: SerializationKey.isTransient) {
            self.isTransient = coder.decodeBool(forKey: SerializationKey.isTransient)
        }
        if coder.containsValue(forKey: SerializationKey.suppressesInconsistentLineEndingAlert) {
            self.suppressesInconsistentLineEndingAlert = coder.decodeBool(forKey: SerializationKey.suppressesInconsistentLineEndingAlert)
        }
        if let styleName = coder.decodeObject(of: NSString.self, forKey: SerializationKey.syntaxStyle) as? String,
           self.syntaxParser.style.name != styleName
        {
            self.setSyntaxStyle(name: styleName)
        }
        
        if let string = coder.decodeObject(of: NSString.self, forKey: SerializationKey.originalContentString) as? String {
            self.replaceContent(with: string)
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
        if UserDefaults.standard[.noDocumentOnLaunchBehavior] != .openPanel,
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
    
    
    /// backup file URL for autosaveElsewhere
    override var autosavedContentsFileURL: URL? {
        
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
                    
                    static let url = try! FileManager.default.url(for: .autosavedInformationDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                }
                
                let baseFileName = fileURL.deletingPathExtension().lastPathComponent
                    .replacingOccurrences(of: ".", with: "", options: .anchored)  // avoid file to be hidden
                
                // append an unique string to avoid overwriting another backup file with the same file name.
                let maxIdentifierLength = Int(NAME_MAX) - (baseFileName + " ()." + fileURL.pathExtension).length
                let fileName = baseFileName + " (" + UUID().uuidString.prefix(maxIdentifierLength) + ")"
                
                super.autosavedContentsFileURL =  AutosaveDirectory.url.appendingPathComponent(fileName).appendingPathExtension(fileURL.pathExtension)
            }
            
            return super.autosavedContentsFileURL
        }
        
        set {
            super.autosavedContentsFileURL = newValue
        }
    }
    
    
    override func makeWindowControllers() {
        
        if self.windowControllers.isEmpty {  // -> A transient document already has one.
            let windowController = NSStoryboard(name: "DocumentWindow").instantiateInitialController() as! DocumentWindowController
            
            self.addWindowController(windowController)
            
            // avoid showing "edited" indicator in the close button when the content is empty
            if !Self.autosavesInPlace {
                self.textStorageObserver = NotificationCenter.default
                    .publisher(for: NSTextStorage.didProcessEditingNotification, object: self.textStorage)
                    .map { $0.object as! NSTextStorage }
                    .map(\.string.isEmpty)
                    .removeDuplicates()
                    .receive(on: RunLoop.main)
                    .assign(to: \.isWhitepaper, on: windowController)
            }
        }
        
        self.applyContentToWindow()
    }
    
    
    override nonisolated func fileNameExtension(forType typeName: String, saveOperation: NSDocument.SaveOperationType) -> String? {
        
        if !self.isDraft, let pathExtension = self.fileURL?.pathExtension {
            return pathExtension
        }
        
        return self.syntaxParser.style.extensions.first
    }
    
    
    override func revert(toContentsOf url: URL, ofType typeName: String) throws {
        
        assert(Thread.isMainThread)
        
        // once force-close all sheets
        // -> Presented errors will be displayed again after the revert automatically. (since OS X 10.10)
        self.windowForSheet?.sheets.forEach { $0.close() }
        
        // store current selections
        let lastString = self.textStorage.string.immutable
        let editorStates = self.textStorage.layoutManagers
            .compactMap(\.textViewForBeginningOfSelection)
            .map { (textView: $0, ranges: $0.selectedRanges.map(\.rangeValue)) }
        
        try super.revert(toContentsOf: url, ofType: typeName)
        
        // do nothing if already no textView exists
        guard !editorStates.isEmpty else { return }
        
        // apply to UI
        self.applyContentToWindow()
        
        // select previous ranges again
        // -> Taking performance issues into consideration,
        //    the selection ranges will be adjusted only when the content size is small enough;
        //    otherwise, just cut extra ranges off.
        let string = self.textStorage.string
        let range = self.textStorage.range
        let maxLength = 20_000  // takes ca. 1.3 sec. with MacBook Pro 13-inch late 2016 (3.3 GHz)
        let considersDiff = lastString.length < maxLength || string.length < maxLength
        
        for state in editorStates {
            let selectedRanges = considersDiff
                ? string.equivalentRanges(to: state.ranges, in: lastString)
                : state.ranges.map { $0.intersection(range) ?? NSRange(location: range.upperBound, length: 0) }
            
            guard !selectedRanges.isEmpty else { continue }
            
            state.textView.selectedRanges = selectedRanges.unique as [NSValue]
        }
    }
    
    
    override func duplicate() throws -> NSDocument {
        
        let document = try super.duplicate() as! Document
        
        document.setSyntaxStyle(name: self.syntaxParser.style.name)
        document.lineEnding = self.lineEnding
        document.fileEncoding = self.fileEncoding
        document.isVerticalText = self.isVerticalText
        document.isExecutable = self.isExecutable
        
        return document
    }
    
    
    override func read(from url: URL, ofType typeName: String) throws {
        
        // [caution] This method may be called from a background thread due to concurrent-opening.
        
        let storategy: DocumentFile.EncodingStorategy = {
            if let encoding = self.readingEncoding {
                return .specific(encoding)
            }
            
            var encodingList = UserDefaults.standard[.encodingList]
            let isInitialOpen = (self.fileData == nil) && (self.textStorage.length == 0)
            if !isInitialOpen {  // prioritize the current encoding
                encodingList.insert(self.fileEncoding.encoding.cfEncoding, at: 0)
            }
            
            return .automatic(priority: encodingList, refersToTag: UserDefaults.standard[.referToEncodingTag])
        }()
        
        // .readingEncoding is only valid once
        self.readingEncoding = nil
        
        let file = try DocumentFile(fileURL: url, encodingStorategy: storategy)  // FILE_ACCESS
        
        // store file data in order to check the file content identity in `presentedItemDidChange()`
        self.fileData = file.data
        
        // use file attributes only if `fileURL` exists
        // -> The passed-in `url` in this method can point to a file that isn't the real document file,
        //    for example on resuming an unsaved document.
        if self.fileURL != nil {
            self.fileAttributes = file.attributes
            self.isExecutable = file.permissions.user.contains(.execute)
        }
        
        // do not save `com.apple.TextEncoding` extended attribute if it doesn't exists
        self.shouldSaveEncodingXattr = (file.xattrEncoding != nil)
        
        // set text orientation state
        // -> Ignore if no metadata found to avoid restoring to the horizontal layout while editing unwantedly.
        if UserDefaults.standard[.savesTextOrientation], file.isVerticalText {
            self.isVerticalText = true
        }
        
        if file.allowsInconsistentLineEndings {
            self.suppressesInconsistentLineEndingAlert = true
        }
        
        // update textStorage
        self.replaceContent(with: file.string)
        
        // set read values
        self.fileEncoding = file.fileEncoding
        self.lineEnding = self.lineEndingScanner.majorLineEnding ?? self.lineEnding  // keep default if no line endings are found
        
        // determine syntax style (only on the first file open)
        if self.windowForSheet == nil {
            let styleName = SyntaxManager.shared.settingName(documentFileName: url.lastPathComponent, content: file.string)
            self.setSyntaxStyle(name: styleName, isInitial: true)
        }
    }
    
    
    override func data(ofType typeName: String) throws -> Data {
        
        // [caution] This method may be called from a background thread due to async-saving.
        
        let fileEncoding = self.fileEncoding
        
        // get data from string to save
        // -> .data(using:allowLossyConversion:) never returns nil as long as allowLossyConversion is true.
        var data = self.textStorage.string
            .convertingYenSign(for: fileEncoding.encoding)
            .data(using: fileEncoding.encoding, allowLossyConversion: true)!
        
        self.unblockUserInteraction()
        
        // add UTF-8 BOM if needed
        if fileEncoding.withUTF8BOM {
            data.insert(contentsOf: Unicode.BOM.utf8.sequence, at: 0)
        }
        
        // keep to swap with `fileData` later, but only when succeed
        self.lastSavedData = data
        
        return data
    }
    
    
    override func save(to url: URL, ofType typeName: String, for saveOperation: NSDocument.SaveOperationType, completionHandler: @escaping (Error?) -> Void) {
        
        // break undo grouping
        for layoutManager in self.textStorage.layoutManagers {
            layoutManager.textViewForBeginningOfSelection?.breakUndoCoalescing()
        }
        
        // workaround the issue that invoking the async version super blocks the save process
        // with macOS 12-13 + Xcode 13-14 (2022 FB11203469).
        // To reproduce the issue:
        //     1. Make a document unsaved ("Edited" status in the window subtitle).
        //     2. Open the save panel once and cancel it.
        //     3. Quit the application.
        //     4. Then, the application hangs up.
        super.save(to: url, ofType: typeName, for: saveOperation) { (error) in
            defer {
                completionHandler(error)
            }
            if error != nil { return }
            
            // apply syntax style that is inferred from the file name or the shebang
            if saveOperation == .saveAsOperation,
               let styleName = SyntaxManager.shared.settingName(documentFileName: url.lastPathComponent)
                ?? SyntaxManager.shared.settingName(documentContent: self.textStorage.string)
            {
                // -> Due to the async-saving, self.textStorage can be changed from the actual saved contents.
                //    But we don't care about that.
                self.setSyntaxStyle(name: styleName)
            }
            
            if !saveOperation.isAutosave {
                ScriptManager.shared.dispatch(event: .documentSaved, document: self)
            }
        }
    }
    
    
    override func writeSafely(to url: URL, ofType typeName: String, for saveOperation: NSDocument.SaveOperationType) throws {
        
        // [caution] This method may be called from a background thread due to async-saving.
        
        try super.writeSafely(to: url, ofType: typeName, for: saveOperation)
        
        if saveOperation != .autosaveElsewhereOperation {
            // get the latest file attributes
            do {
                self.fileAttributes = try FileManager.default.attributesOfItem(atPath: url.path)  // FILE_ACCESS
            } catch {
                assertionFailure(error.localizedDescription)
            }
            
            // store file data in order to check the file content identity in `presentedItemDidChange()`
            assert(self.lastSavedData != nil)
            self.fileData = self.lastSavedData
        }
        self.lastSavedData = nil
    }
    
    
    override func fileAttributesToWrite(to url: URL, ofType typeName: String, for saveOperation: NSDocument.SaveOperationType, originalContentsURL absoluteOriginalContentsURL: URL?) throws -> [String: Any] {
        
        // [caution] This method may be called from a background thread due to async-saving.
        
        var attributes = try super.fileAttributesToWrite(to: url, ofType: typeName, for: saveOperation, originalContentsURL: absoluteOriginalContentsURL)
        
        // give the execute permission if user requested
        if self.saveOptions.isExecutable, !saveOperation.isAutosave {
            let permissions: UInt16 = (self.fileAttributes?[.posixPermissions] as? UInt16) ?? 0o644  // ???: Is the default permission really always 644?
            attributes[FileAttributeKey.posixPermissions] = permissions | S_IXUSR
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
        
        // set default file extension in a hacky way (2018-02 on macOS 10.13 SDK for macOS 10.11 - 12)
        savePanel.allowsOtherFileTypes = true
        savePanel.allowedContentTypes = []  // empty array allows setting any extension
        
        if let fileType = self.fileType,
           let filenameExtension = self.fileNameExtension(forType: fileType, saveOperation: .saveOperation),
           let utType = UTType(filenameExtension: filenameExtension)
        {
            // set once allowedContentTypes, so that the initial filename selection excludes the file extension
            savePanel.allowedContentTypes = [utType]
            
            // disable it immediately in the next runloop to allow setting other extensions
            Task.detached { @MainActor [weak savePanel] in
                savePanel?.allowedContentTypes = []
            }
        } else {
            // just keep no extension
            savePanel.allowedContentTypes = []
        }
        
        // set accessory view
        let accessory = SavePanelAccessory(options: self.saveOptions)
        let accessoryView = NSHostingView(rootView: accessory)
        accessoryView.ensureFrameSize()
        savePanel.accessoryView = accessoryView
        
        return true
    }
    
    
    override func canClose(withDelegate delegate: Any, shouldClose shouldCloseSelector: Selector?, contextInfo: UnsafeMutableRawPointer?) {
        
        // suppress save dialog if content is empty and not saved explicitly
        if (self.isDraft || self.fileURL == nil), self.textStorage.string.isEmpty {
            self.updateChangeCount(.changeCleared)
            
            // delete autosaved file if exists
            if let fileURL = self.fileURL {
                NSDocumentController.shared.removeRecentDocument(url: fileURL)
                
                var deletionError: NSError?
                NSFileCoordinator(filePresenter: self).coordinate(writingItemAt: fileURL, options: .forDeleting, error: &deletionError) { (newURL) in  // FILE_ACCESS
                    do {
                        try FileManager.default.removeItem(at: newURL)
                    } catch {
                        // do nothing and let super's `.canClose(withDelegate:shouldClose:contextInfo:)` handle the stuff
                        Swift.print("Failed empty file deletion: \(error)")
                        return
                    }
                    
                    self.fileURL = nil
                    self.isDraft = false
                }
            }
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
                                              syntaxName: self.syntaxParser.style.name)
        let printView = PrintTextView(info: info)
        
        printView.setLayoutOrientation(viewController.verticalLayoutOrientation ? .vertical : .horizontal)
        printView.baseWritingDirection = viewController.writingDirection
        printView.ligature = UserDefaults.standard[.ligature] ? .standard : .none
        printView.font = UserDefaults.standard[.setPrintFont]
            ? NSFont(name: UserDefaults.standard[.printFontName], size: UserDefaults.standard[.printFontSize])
            : viewController.font
        
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
    
    
    
    // MARK: Protocols
    
    /// File has been modified by an external process.
    override func presentedItemDidChange() {
        
        // [caution] This method can be called from any thread.
        
        // [caution] DO NOT invoke `super.presentedItemDidChange()` that reverts document automatically if autosavesInPlace is enable.
//        super.presentedItemDidChange()
        
        guard
            UserDefaults.standard[.documentConflictOption] != .ignore,
            !self.isExternalUpdateAlertShown,  // don't check twice if already notified
            var fileURL = self.fileURL
        else { return }
        
        // check whether the document content is really modified
        // -> Avoid using NSFileCoordinator although the document recommends
        //    because it cause deadlock when the document in the iCloud Document remotely modified.
        //    (2022-08 on macOS 12.5, Xcode 14, #1296)
        fileURL.removeCachedResourceValue(forKey: .contentModificationDateKey)
        let data: Data
        do {
            // ignore if file's modificationDate is the same as document's modificationDate
            let contentModificationDate = try fileURL.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate  // FILE_ACCESS
            guard contentModificationDate != self.fileModificationDate else { return }
            
            // check if file contents was changed from the stored file data
            data = try Data(contentsOf: fileURL, options: [.mappedIfSafe])  // FILE_ACCESS
        } catch {
            return assertionFailure(error.localizedDescription)
        }
        
        guard data != self.fileData else { return }
        
        // notify about external file update
        DispatchQueue.main.async { [weak self] in
            switch UserDefaults.standard[.documentConflictOption] {
                case .ignore:
                    assertionFailure()
                case .notify:
                    self?.showUpdatedByExternalProcessAlert()
                case .revert:
                    self?.revertWithoutAsking()
            }
        }
    }
    
    
    /// Apply the current states to menu items.
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        
        switch menuItem.action {
            case #selector(changeEncoding(_:)):
                menuItem.state = (menuItem.tag == self.fileEncoding.tag) ? .on : .off
                
            case #selector(changeLineEnding(_:)):
                menuItem.state = (menuItem.tag == self.lineEnding.index) ? .on : .off
                
            case #selector(changeSyntaxStyle(_:)):
                menuItem.state = (menuItem.title == self.syntaxParser.style.name) ? .on : .off
                
            default: break
        }
        
        return super.validateMenuItem(menuItem)
    }
    
    
    /// Open existing document file (alternative methods for `init(contentsOf:ofType:)`).
    func didMakeDocumentForExisitingFile(url: URL) {
        
        // [caution] This method may be called from a background thread due to concurrent-opening.
        // -> This method won't be invoked on Resume. (2015-01-26)
        
        ScriptManager.shared.dispatch(event: .documentOpened, document: self)
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
    
    
    /// Replace whole content with the given `string`.
    ///
    /// - Parameter string: The content string to replace with.
    func replaceContent(with string: String) {
        
        assert(self.textStorage.layoutManagers.isEmpty || Thread.isMainThread)
        
        self.textStorage.replaceCharacters(in: self.textStorage.range, with: string)
    }
    
    
    /// Reinterpret the document file with the desired encoding.
    ///
    /// - Parameter encoding: The file encoding to read.
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
            
            throw ReinterpretationError.reinterpretationFailed(fileURL: fileURL, encoding: encoding)
        }
    }
    
    
    /// Change the file encoding and register the process to the undo manager.
    ///
    /// - Parameters:
    ///   - fileEncoding: The file encoding to change with.
    ///   - lossy: Whether the change is lossy.
    /// - Throws: `EncodingError` (Kind.lossyConversion) can be thrown but only if `lossy` flag is `false`.
    func changeEncoding(to fileEncoding: FileEncoding, lossy: Bool) throws {
        
        assert(Thread.isMainThread)
        
        guard fileEncoding != self.fileEncoding else { return }
        
        // check if conversion is lossy
        guard lossy || self.textStorage.string.canBeConverted(to: fileEncoding.encoding) else {
            throw EncodingError(kind: .lossyConversion, fileEncoding: fileEncoding, attempter: self)
        }
        
        // register undo
        if let undoManager = self.undoManager {
            undoManager.registerUndo(withTarget: self) { [currentFileEncoding = self.fileEncoding, shouldSaveEncodingXattr = self.shouldSaveEncodingXattr] target in
                target.fileEncoding = currentFileEncoding
                target.shouldSaveEncodingXattr = shouldSaveEncodingXattr
                target.incompatibleCharacterScanner.invalidate()
                
                // register redo
                target.undoManager?.registerUndo(withTarget: target) { try? $0.changeEncoding(to: fileEncoding, lossy: lossy) }
            }
            undoManager.setActionName(String(localized: "Encoding to “\(fileEncoding.localizedName)”"))
        }
        
        // update encoding
        self.fileEncoding = fileEncoding
        self.shouldSaveEncodingXattr = true
        
        // update incompatible characters inspector
        self.incompatibleCharacterScanner.invalidate()
    }
    
    
    /// Change line endings and register the process to the undo manager.
    ///
    /// - Parameter lineEnding: The line ending type to change with.
    func changeLineEnding(to lineEnding: LineEnding) {
        
        assert(Thread.isMainThread)
        
        guard lineEnding != self.lineEnding ||
                !self.lineEndingScanner.inconsistentLineEndings.isEmpty
        else { return }
        
        // register undo
        if let undoManager = self.undoManager {
            undoManager.registerUndo(withTarget: self) { [currentLineEnding = self.lineEnding, string = self.textStorage.string] target in
                target.replaceContent(with: string)
                target.lineEnding = currentLineEnding
                
                // register redo
                target.undoManager?.registerUndo(withTarget: target) { $0.changeLineEnding(to: lineEnding)
                }
            }
            undoManager.setActionName(String(localized: "Line Endings to \(lineEnding.name)"))
        }
        
        // update line ending
        self.textStorage.replaceLineEndings(with: lineEnding)
        self.lineEnding = lineEnding
    }
    
    
    /// Change the syntax style to one with the given style name.
    ///
    /// - Parameters:
    ///   - name: The name of the style to change with.
    ///   - isInitial: Whether the setting is initial.
    func setSyntaxStyle(name: String, isInitial: Bool = false) {
        
        guard
            let syntaxStyle = SyntaxManager.shared.setting(name: name),
            syntaxStyle != self.syntaxParser.style
        else { return }
        
        // update
        self.syntaxParser.style = syntaxStyle
        
        // skip notification when initial style was set on file open
        // to avoid redundant highlight parse due to async notification.
        guard !isInitial else { return }
        
        self.didChangeSyntaxStyle.send(name)
    }
    
    
    
    // MARK: Action Messages
    
    /// Save document.
    @IBAction override func save(_ sender: Any?) {
        
        self.askSavingSafety { (continuesSaving: Bool) in
            guard continuesSaving else { return }
            
            super.save(sender)
        }
    }
    
    
    /// Save document to a new location.
    @IBAction override func saveAs(_ sender: Any?) {
        
        self.askSavingSafety { (continuesSaving: Bool) in
            guard continuesSaving else { return }
            
            super.saveAs(sender)
        }
    }
    
    
    /// Change the line ending with sender's tag.
    @IBAction func changeLineEnding(_ sender: NSMenuItem) {
        
        guard let lineEnding = LineEnding.allCases[safe: sender.tag] else { return assertionFailure() }
        
        self.changeLineEnding(to: lineEnding)
    }
    
    
    /// Change the document file encoding.
    @IBAction func changeEncoding(_ sender: NSMenuItem) {
        
        let fileEncoding = FileEncoding(tag: sender.tag)
        
        guard fileEncoding != self.fileEncoding else { return }
        
        // change encoding interactively
        self.performActivity(withSynchronousWaiting: true) { [unowned self] (activityCompletionHandler) in
            
            let completionHandler = { [weak self] (didChange: Bool) in
                if !didChange, let self {
                    // reset status bar selection for in case if the operation was invoked from the popup button in the bar
                    let originalEncoding = self.fileEncoding
                    self.fileEncoding = originalEncoding
                }
                activityCompletionHandler()
            }
            
            // change encoding immediately if there is nothing to worry about
            if self.fileURL == nil ||
                self.textStorage.string.isEmpty ||
                (fileEncoding.encoding == .utf8 && self.fileEncoding.encoding == .utf8) {
                do {
                    try self.changeEncoding(to: fileEncoding, lossy: false)
                    completionHandler(true)
                } catch {
                    self.presentErrorAsSheet(error, recoveryHandler: completionHandler)
                }
                return
            }
            
            // ask whether just change the encoding or reinterpret document file
            let alert = NSAlert()
            alert.messageText = "File encoding".localized
            alert.informativeText = String(localized: "Do you want to convert or reinterpret this document using “\(fileEncoding.localizedName)”?")
            alert.addButton(withTitle: "Convert".localized)
            alert.addButton(withTitle: "Reinterpret".localized)
            alert.addButton(withTitle: "Cancel".localized)
            
            let documentWindow = self.windowForSheet!
            Task {
                let returnCode = await alert.beginSheetModal(for: documentWindow)
                switch returnCode {
                    case .alertFirstButtonReturn:  // = Convert
                        do {
                            try self.changeEncoding(to: fileEncoding, lossy: false)
                            completionHandler(true)
                        } catch {
                            self.presentErrorAsSheet(error, recoveryHandler: completionHandler)
                        }
                        
                    case .alertSecondButtonReturn:  // = Reinterpret
                        // ask user if document is edited
                        if self.isDocumentEdited {
                            let alert = NSAlert()
                            alert.messageText = "The document has unsaved changes.".localized
                            alert.informativeText = String(localized: "Do you want to discard the changes and reopen the document using “\(fileEncoding.localizedName)”?")
                            alert.addButton(withTitle: "Cancel".localized)
                            alert.addButton(withTitle: "Discard Changes".localized)
                            alert.buttons.last?.hasDestructiveAction = true
                            
                            documentWindow.attachedSheet?.orderOut(self)  // close previous sheet
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
    
    
    /// Change the syntax style.
    @IBAction func changeSyntaxStyle(_ sender: AnyObject?) {
        
        guard let name = sender?.title else { return assertionFailure() }
        
        self.setSyntaxStyle(name: name)
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
    
    
    /// Transfer file information to UI.
    private func applyContentToWindow() {
        
        // update incompatible characters if pane is visible
        self.incompatibleCharacterScanner.invalidate()
        
        guard let viewController = self.viewController else { return }
        
        // update view
        viewController.invalidateStyleInTextStorage()
        if self.isVerticalText {
            viewController.verticalLayoutOrientation = true
        }
        
        // show alert if line endings are inconsistent
        if !self.suppressesInconsistentLineEndingAlert,
           !self.lineEndingScanner.inconsistentLineEndings.isEmpty,
           !self.isBrowsingVersions
        {
            if self.windowForSheet?.isVisible == true {
                self.showInconsistentLineEndingAlert()
            } else {
                // wait for the window to appear
                self.windowObserver = self.windowForSheet?
                    .publisher(for: \.isVisible)
                    .first { $0 }
                    .delay(for: .seconds(0.15), scheduler: RunLoop.main)  // wait for window open animation
                    .sink { [weak self] _ in self?.showInconsistentLineEndingAlert() }
            }
        }
    }
    
    
    /// Check if can save safely with the current encoding and ask if not.
    private func askSavingSafety(completionHandler: @escaping (Bool) -> Void) {
        
        assert(Thread.isMainThread)
        
        // check file encoding for conversion and ask user how to solve
        do {
            try self.checkSavingSafetyForConverting()
        } catch {
            return self.presentErrorAsSheetSafely(error, recoveryHandler: completionHandler)
        }
        
        completionHandler(true)
    }
    
    
    /// Check if the content can be saved with the current file encoding.
    private func checkSavingSafetyForConverting() throws {
        
        guard self.textStorage.string.canBeConverted(to: self.fileEncoding.encoding) else {
            throw EncodingError(kind: .lossySaving, fileEncoding: self.fileEncoding, attempter: self)
        }
    }
    
    
    /// Display alert about inconsistent line endings.
    private func showInconsistentLineEndingAlert() {
        
        assert(Thread.isMainThread)
        
        guard
            !UserDefaults.standard[.suppressesInconsistentLineEndingAlert],
            !self.suppressesInconsistentLineEndingAlert
        else { return }
        guard let documentWindow = self.windowForSheet else { return assertionFailure() }
        
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "The document has inconsistent line endings.".localized
        alert.informativeText = String(localized: "Do you want to convert all line endings to \(self.lineEnding.name), the most common line endings in this document?")
        alert.addButton(withTitle: "Convert".localized)
        alert.addButton(withTitle: "Review".localized)
        alert.addButton(withTitle: "Ignore".localized)
        alert.showsSuppressionButton = true
        alert.suppressionButton?.title = "Don’t ask again for this document".localized
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
                    (self.windowControllers.first?.contentViewController as? WindowContentViewController)?
                        .showSidebarPane(index: .warnings)
                case .alertThirdButtonReturn:  // == Ignore
                    break
                default:
                    fatalError()
            }
        }
    }
    
    
    /// Display alert about file modification by an external process.
    private func showUpdatedByExternalProcessAlert() {
        
        assert(Thread.isMainThread)
        
        // do nothing if alert is already shown
        guard !self.isExternalUpdateAlertShown else { return }
        
        self.performActivity(withSynchronousWaiting: true) { [unowned self] activityCompletionHandler in
            self.isExternalUpdateAlertShown = true
            
            let messageText = self.isDocumentEdited
                ? "The file has been changed by another application. There are also unsaved changes in CotEditor."
                : "The file has been changed by another application."
            
            let alert = NSAlert()
            alert.messageText = messageText.localized
            alert.informativeText = "Do you want to keep CotEditor’s edition or update it to the modified edition?".localized
            alert.addButton(withTitle: "Keep CotEditor’s Edition".localized)
            alert.addButton(withTitle: "Update".localized)
            
            // mark the alert as critical in order to interrupt other sheets already attached
            guard let documentWindow = self.windowForSheet else {
                activityCompletionHandler()
                assertionFailure()
                return
            }
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
    
    
    /// Revert receiver with current document file without asking to user before.
    private func revertWithoutAsking() {
        
        assert(Thread.isMainThread)
        
        guard
            let fileURL = self.fileURL,
            let fileType = self.fileType
        else { return }
        
        do {
            try self.revert(toContentsOf: fileURL, ofType: fileType)
        } catch {
            self.presentErrorAsSheetSafely(error)
        }
    }
}



// MARK: - Error

private enum ReinterpretationError: LocalizedError {
    
    case noFile
    case reinterpretationFailed(fileURL: URL, encoding: String.Encoding)
    
    
    var errorDescription: String? {
        
        switch self {
            case .noFile:
                return "The document doesn’t have a file to reinterpret.".localized
            
            case let .reinterpretationFailed(fileURL, encoding):
                return String(localized: "The file “\(fileURL.lastPathComponent)” couldn’t be reinterpreted using text encoding “\(String.localizedName(of: encoding)).”")
        }
    }
    
    
    var recoverySuggestion: String? {
        
        switch self {
            case .noFile:
                return nil
                
            case .reinterpretationFailed:
                return "The file may have been saved using a different text encoding, or it may not be a text file.".localized
        }
    }
}



private struct EncodingError: LocalizedError, RecoverableError {
    
    enum ErrorKind {
        case lossySaving
        case lossyConversion
    }
    
    let kind: ErrorKind
    let fileEncoding: FileEncoding
    let attempter: Document
    
    
    
    var errorDescription: String? {
        
        String(localized: "Some characters would have to be changed or deleted in saving as “\(self.fileEncoding.localizedName).”")
    }
    
    
    var recoverySuggestion: String? {
        
        switch self.kind {
            case .lossySaving:
                return "Do you want to continue processing?".localized
                
            case .lossyConversion:
                return "Do you want to change encoding and show incompatible characters?".localized
        }
    }
    
    
    var recoveryOptions: [String] {
        
        switch self.kind {
            case .lossySaving:
                return ["Show Incompatible Characters".localized,
                        "Save Available Text".localized,
                        "Cancel".localized]
                
            case .lossyConversion:
                return ["Change Encoding".localized,
                        "Cancel".localized]
        }
    }
    
    
    func attemptRecovery(optionIndex recoveryOptionIndex: Int) -> Bool {
        
        switch self.kind {
            case .lossySaving:
                switch recoveryOptionIndex {
                    case 0:  // == Show Incompatible Characters
                        self.showIncompatibleCharacters()
                        return false
                    case 1:  // == Save
                        return true
                    case 2:  // == Cancel
                        return false
                    default:
                        preconditionFailure()
                }
                
            case .lossyConversion:
                switch recoveryOptionIndex {
                    case 0:  // == Change Encoding
                        try? self.attempter.changeEncoding(to: self.fileEncoding, lossy: true)
                        self.showIncompatibleCharacters()
                        return true
                    case 1:  // == Cancel
                        return false
                    default:
                        preconditionFailure()
                }
        }
    }
    
    
    private func showIncompatibleCharacters() {
        
        let windowContentController = self.attempter.windowControllers.first?.contentViewController as? WindowContentViewController
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            windowContentController?.showSidebarPane(index: .warnings)
        }
    }
}
