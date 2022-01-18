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
//  © 2014-2021 1024jp
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

final class Document: NSDocument, AdditionalDocumentPreparing, EncodingHolder {
    
    // MARK: Enums
    
    private enum SerializationKey {
        
        static let readingEncoding = "readingEncoding"
        static let syntaxStyle = "syntaxStyle"
        static let isVerticalText = "isVerticalText"
        static let isTransient = "isTransient"
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
    
    private(set) lazy var selection = TextSelection(document: self)
    private(set) lazy var analyzer = DocumentAnalyzer(document: self)
    private(set) lazy var incompatibleCharacterScanner = IncompatibleCharacterScanner(document: self)
    
    let didChangeSyntaxStyle = PassthroughSubject<String, Never>()
    
    
    // MARK: Private Properties
    
    private lazy var printPanelAccessoryController = PrintPanelAccessoryController.instantiate(storyboard: "PrintPanelAccessory")
    private lazy var savePanelAccessoryController = NSViewController.instantiate(storyboard: "SaveDocumentAccessory")
    
    private var readingEncoding: String.Encoding  // encoding to read document file
    private var isExternalUpdateAlertShown = false
    private var fileData: Data?
    private var shouldSaveXattr = true
    @objc private dynamic var isExecutable = false  // bind in save panel accessory view
    
    private var sytnaxUpdateObserver: AnyCancellable?
    private var textStorageObserver: AnyCancellable?
    
    private var lastSavedData: Data?  // temporal data used only within saving process
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    override init() {
        
        // [caution] This method may be called from a background thread due to concurrent-opening.
        
        let defaultEncoding = String.Encoding(rawValue: UserDefaults.standard[.encodingInNew])
        let encoding = String.availableStringEncodings.contains(defaultEncoding) ? defaultEncoding : .utf8
        self.fileEncoding = FileEncoding(encoding: encoding, withUTF8BOM: (encoding == .utf8) && UserDefaults.standard[.saveUTF8BOM])
        
        self.lineEnding = LineEnding(index: UserDefaults.standard[.lineEndCharCode]) ?? .lf
        self.syntaxParser = SyntaxParser(textStorage: self.textStorage)
        self.syntaxParser.style = SyntaxManager.shared.setting(name: UserDefaults.standard[.syntaxStyle]) ?? SyntaxStyle()
        
        // use the encoding selected by the user in the open panel, if exists
        self.readingEncoding = (DocumentController.shared as! DocumentController).accessorySelectedEncoding ?? .autoDetection
        
        super.init()
        
        self.hasUndoManager = true
        
        // observe sytnax style update
        self.sytnaxUpdateObserver = SyntaxManager.shared.didUpdateSetting
            .filter { [weak self] (change) in change.old == self?.syntaxParser.style.name }
            .sink { [weak self] (change) in self?.setSyntaxStyle(name: change.new ?? BundledStyleName.none) }
    }
    
    
    /// store internal document state
    override func encodeRestorableState(with coder: NSCoder, backgroundQueue queue: OperationQueue) {
        
        super.encodeRestorableState(with: coder, backgroundQueue: queue)
        
        coder.encode(Int(self.fileEncoding.encoding.rawValue), forKey: SerializationKey.readingEncoding)
        coder.encode(self.syntaxParser.style.name, forKey: SerializationKey.syntaxStyle)
        coder.encode(self.isVerticalText, forKey: SerializationKey.isVerticalText)
        coder.encode(self.isTransient, forKey: SerializationKey.isTransient)
    }
    
    
    /// restore UI state
    override func restoreState(with coder: NSCoder) {
        
        super.restoreState(with: coder)
        
        if coder.containsValue(forKey: SerializationKey.readingEncoding) {
            let encoding = String.Encoding(rawValue: UInt(coder.decodeInteger(forKey: SerializationKey.readingEncoding)))
            if String.availableStringEncodings.contains(encoding) {
                self.readingEncoding = encoding
            }
        }
        if let styleName = coder.decodeObject(forKey: SerializationKey.syntaxStyle) as? String {
            if self.syntaxParser.style.name != styleName {
                self.setSyntaxStyle(name: styleName)
            }
        }
        if coder.containsValue(forKey: SerializationKey.isVerticalText) {
            self.isVerticalText = coder.decodeBool(forKey: SerializationKey.isVerticalText)
        }
        if coder.containsValue(forKey: SerializationKey.isTransient) {
            self.isTransient = coder.decodeBool(forKey: SerializationKey.isTransient)
        }
    }
    
    
    
    // MARK: Document Methods
    
    /// enable Autosave in Place
    override class var autosavesInPlace: Bool {
        
        // avoid changing the value while the application is running
        struct InitialValue { static let autosavesInPlace = UserDefaults.standard[.enablesAutosaveInPlace] }
        
        return InitialValue.autosavesInPlace
    }
    
    
    /// whether documents use iCloud storage
    override class var usesUbiquitousStorage: Bool {
        
        // pretend as if iCloud storage is disabled to let the system give up opening the open panel on launch (2018-02 macOS 10.13)
        if UserDefaults.standard[.noDocumentOnLaunchBehavior] != .openPanel,
           NSDocumentController.shared.documents.isEmpty
        {
            return false
        }
        
        return super.usesUbiquitousStorage
    }
    
    
    /// can read document on a background thread?
    override class func canConcurrentlyReadDocuments(ofType: String) -> Bool {
        
        return true
    }
    
    
    /// enable asynchronous saving
    override func canAsynchronouslyWrite(to url: URL, ofType typeName: String, for saveOperation: NSDocument.SaveOperationType) -> Bool {
        
        // -> Async-saving may cause an occasional crash. (2017-10 macOS 10.13 SDK)
        return UserDefaults.standard.bool(forKey: "enablesAsynchronousSaving")
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
                    
                    static let URL = try! FileManager.default.url(for: .autosavedInformationDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                }
                
                let baseFileName = fileURL.deletingPathExtension().lastPathComponent
                    .replacingOccurrences(of: ".", with: "", options: .anchored)  // avoid file to be hidden
                
                // append an unique string to avoid overwriting another backup file with the same file name.
                let maxIdentifierLength = Int(NAME_MAX) - (baseFileName + " ()." + fileURL.pathExtension).length
                let fileName = baseFileName + " (" + UUID().uuidString.prefix(maxIdentifierLength) + ")"
                
                super.autosavedContentsFileURL =  AutosaveDirectory.URL.appendingPathComponent(fileName).appendingPathExtension(fileURL.pathExtension)
            }
            
            return super.autosavedContentsFileURL
        }
        
        set {
            super.autosavedContentsFileURL = newValue
        }
    }
    
    
    /// make custom windowControllers
    override func makeWindowControllers() {
        
        if self.windowControllers.isEmpty {  // -> A transient document already has one.
            let windowController = DocumentWindowController.instantiate(storyboard: "DocumentWindow")
            
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
    
    
    /// return preferred file extension corresponding to the current syntax style
    override func fileNameExtension(forType typeName: String, saveOperation: NSDocument.SaveOperationType) -> String? {
        
        if let pathExtension = self.fileURL?.pathExtension {
            return pathExtension
        }
        
        return self.syntaxParser.style.extensions.first
    }
    
    
    /// revert to saved file contents
    override func revert(toContentsOf url: URL, ofType typeName: String) throws {
        
        assert(Thread.isMainThread)
        
        // once force-close all sheets
        // -> Presented errors will be displayed again after the revert automatically. (since OS X 10.10)
        self.windowForSheet?.sheets.forEach { $0.close() }
        
        // store current selections
        let lastString = self.textStorage.string
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
        //    the selection ranges will be adjusted only when the content size is enough small;
        //    otherwise, just cut extra ranges off.
        let string = self.textStorage.string
        let range = self.textStorage.range
        let maxLength = 20_000  // takes ca. 1.3 sec. with MacBook Pro 13-inch late 2016 (3.3 GHz)
        let considersDiff = lastString.length < maxLength || string.length < maxLength
        
        for state in editorStates {
            let selectedRanges = considersDiff
                ? string.equivalentRanges(to: state.ranges, in: lastString)
                : state.ranges.map { $0.intersection(range) ?? NSRange(location: range.upperBound, length: 0) }
            
            state.textView.selectedRanges = selectedRanges.unique as [NSValue]
        }
    }
    
    
    /// setup duplicated document
    override func duplicate() throws -> NSDocument {
        
        let document = try super.duplicate() as! Document
        
        document.setSyntaxStyle(name: self.syntaxParser.style.name)
        document.lineEnding = self.lineEnding
        document.fileEncoding = self.fileEncoding
        document.isVerticalText = self.isVerticalText
        document.isExecutable = self.isExecutable
        
        return document
    }
    
    
    /// load document from file and return whether it succeeded
    override func read(from url: URL, ofType typeName: String) throws {
        
        // [caution] This method may be called from a background thread due to concurrent-opening.
        
        let file = try DocumentFile(fileURL: url, readingEncoding: self.readingEncoding)  // FILE_READ
        
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
        self.shouldSaveXattr = (file.xattrEncoding != nil)
        
        // set text orientation state
        // -> Ignore if no metadata found to avoid restoring to the horizontal layout while editing unwantedly.
        if UserDefaults.standard[.savesTextOrientation], file.isVerticalText {
            self.isVerticalText = true
        }
        
        // set read values
        self.fileEncoding = file.fileEncoding
        self.lineEnding = file.lineEnding ?? self.lineEnding  // keep default if no line endings are found
        
        // standardize line endings to LF
        // -> Line endings replacement by other text modifications is processed in
        //    `EditorTextViewController.textView(_:shouldChangeTextInRange:replacementString:)`.
        let string = file.string.replacingLineEndings(with: .lf)
        
        // update textStorage
        assert(self.textStorage.layoutManagers.isEmpty || Thread.isMainThread)
        self.textStorage.replaceCharacters(in: self.textStorage.range, with: string)
        
        // determine syntax style (only on the first file open)
        if self.windowForSheet == nil {
            let styleName = SyntaxManager.shared.settingName(documentFileName: url.lastPathComponent, content: string)
            self.setSyntaxStyle(name: styleName, isInitial: true)
        }
    }
    
    
    /// create Data object to save
    override func data(ofType typeName: String) throws -> Data {
        
        // [caution] This method may be called from a background thread due to async-saving.
        
        let fileEncoding = self.fileEncoding
        let string = self.string.immutable
        
        // unblock the user interface, since fetching current document state has been done here
        self.unblockUserInteraction()
        
        // get data from string to save
        guard var data = string.convertingYenSign(for: fileEncoding.encoding).data(using: fileEncoding.encoding, allowLossyConversion: true) else {
            throw CocoaError.error(.fileWriteInapplicableStringEncoding,
                                   userInfo: [NSStringEncodingErrorKey: fileEncoding.encoding.rawValue])
        }
        
        // add UTF-8 BOM if needed
        if fileEncoding.withUTF8BOM {
            data.insert(contentsOf: Unicode.BOM.utf8.sequence, at: 0)
        }
        
        // keep to swap later with `fileData`, but only when succeed
        self.lastSavedData = data
        
        return data
    }
    
    
    /// save or autosave the document contents to a file
    override func save(to url: URL, ofType typeName: String, for saveOperation: NSDocument.SaveOperationType, completionHandler: @escaping (Error?) -> Void) {
        
        // break undo grouping
        for layoutManager in self.textStorage.layoutManagers {
            layoutManager.textViewForBeginningOfSelection?.breakUndoCoalescing()
        }
        
        // workaround the issue that invoking the async version super blocks the save process
        // with macOS 12.1 + Xcode 13.2.1 (2022-01).
        super.save(to: url, ofType: typeName, for: saveOperation) { (error) in
            defer {
                completionHandler(error)
            }
            if error != nil { return }
            
        // apply syntax style that is inferred from the file name or the shebang
        if saveOperation == .saveAsOperation {
            if let styleName = SyntaxManager.shared.settingName(documentFileName: url.lastPathComponent)
                ?? SyntaxManager.shared.settingName(documentContent: self.string)
            // -> Due to the async-saving, self.string can be changed from the actual saved contents.
            //    But we don't care about that.
            {
                self.setSyntaxStyle(name: styleName)
            }
        }
        
        if !saveOperation.isAutosaving {
            ScriptManager.shared.dispatch(event: .documentSaved, document: self)
        }
    }
    }
    
    
    /// write file metadata to the new file (invoked in file saving process)
    override func writeSafely(to url: URL, ofType typeName: String, for saveOperation: NSDocument.SaveOperationType) throws {
        
        // [caution] This method may be called from a background thread due to async-saving.
        
        // store current state here, since the main thread will already be unblocked after `data(ofType:)`
        let encoding = self.fileEncoding.encoding
        let isVerticalText = self.isVerticalText
        
        try super.writeSafely(to: url, ofType: typeName, for: saveOperation)
        
        // save document state to the extended file attributes
        if self.shouldSaveXattr {
            try url.setExtendedAttribute(data: encoding.xattrEncodingData, for: FileExtendedAttributeName.encoding)
        }
        if UserDefaults.standard[.savesTextOrientation] {
            try url.setExtendedAttribute(data: isVerticalText ? Data([1]) : nil, for: FileExtendedAttributeName.verticalText)
        }
        
        if saveOperation != .autosaveElsewhereOperation {
            // get the latest file attributes
            self.fileAttributes = try FileManager.default.attributesOfItem(atPath: url.path)  // FILE_READ
            
            // store file data in order to check the file content identity in `presentedItemDidChange()`
            self.fileData = self.lastSavedData
            
            // store file encoding for revert
            self.readingEncoding = encoding
        }
    }
    
    
    /// customize document's file attributes
    override func fileAttributesToWrite(to url: URL, ofType typeName: String, for saveOperation: NSDocument.SaveOperationType, originalContentsURL absoluteOriginalContentsURL: URL?) throws -> [String: Any] {
        
        // [caution] This method may be called from a background thread due to async-saving.
        
        var attributes = try super.fileAttributesToWrite(to: url, ofType: typeName, for: saveOperation, originalContentsURL: absoluteOriginalContentsURL)
        
        // give the execute permission if user requested
        if self.isExecutable, !saveOperation.isAutosaving {
            let permissions: UInt16 = (self.fileAttributes?[.posixPermissions] as? UInt16) ?? 0o644  // ???: Is the default permission really always 644?
            attributes[FileAttributeKey.posixPermissions.rawValue] = permissions | S_IXUSR
        }
        
        return attributes
    }
    
    
    /// avoid let system add the standard save panel accessory (pop-up menu for document type change)
    override var shouldRunSavePanelWithAccessoryView: Bool {
        
        return false
    }
    
    
    /// prepare save panel
    override func prepareSavePanel(_ savePanel: NSSavePanel) -> Bool {
        
        // set default file extension in a hacky way (2018-02 on macOS 10.13 SDK for macOS 10.11 - 10.14)
        savePanel.allowsOtherFileTypes = true
        savePanel.allowedContentTypes = []  // empty array allows setting any extension
        if
            let fileType = self.fileType,
            let pathExtension = self.fileNameExtension(forType: fileType, saveOperation: .saveOperation),
            let utType = UTType(filenameExtension: pathExtension)
        {
            // set once allowedContentTypes, so that initial filename selection excludes the file extension
            savePanel.allowedContentTypes = [utType]
            
            // disable it immediately in the next runloop to allow setting other extensions
            DispatchQueue.main.async {
                savePanel.allowedContentTypes = []
            }
        }
        
        // set accessory view
        self.savePanelAccessoryController.representedObject = self
        savePanel.accessoryView = self.savePanelAccessoryController.view
        
        return super.prepareSavePanel(savePanel)
    }
    
    
    /// display dialogs about save before closing document
    override func canClose(withDelegate delegate: Any, shouldClose shouldCloseSelector: Selector?, contextInfo: UnsafeMutableRawPointer?) {
        
        var shouldClose = false
        // disable save dialog if content is empty and not saved explicitly
        if (self.isDraft || self.fileURL == nil), self.textStorage.string.isEmpty {
            self.updateChangeCount(.changeCleared)
            
            // remove auto-saved file if exists
            if let url = self.fileURL {
                var deletionError: NSError?
                NSFileCoordinator(filePresenter: self).coordinate(writingItemAt: url, options: .forDeleting, error: &deletionError) { (url) in  // FILE_READ
                    do {
                        try FileManager.default.removeItem(at: url)
                    } catch {
                        // do nothing and let super's `.canClose(withDelegate:shouldClose:contextInfo:)` handle the stuff
                        Swift.print("Failed empty file deletion: \(error)")
                        return
                    }
                    
                    shouldClose = true
                    self.fileURL = nil
                }
            }
        }
        
        // manually call delegate but only when you wanna modify `shouldClose` flag
        guard
            shouldClose,
            let selector = shouldCloseSelector,
            let context = contextInfo,
            let object = delegate as? NSObject,
            let objcClass = objc_getClass(object.className) as? AnyClass,
            let method = class_getMethodImplementation(objcClass, selector)
            else { return super.canClose(withDelegate: delegate, shouldClose: shouldCloseSelector, contextInfo: contextInfo) }
        
        typealias Signature = @convention(c) (NSObject, Selector, NSDocument, Bool, UnsafeMutableRawPointer) -> Void
        let function = unsafeBitCast(method, to: Signature.self)
        
        function(object, selector, self, shouldClose, context)
    }
    
    
    /// close document
    override func close() {
        
        self.syntaxParser.invalidateCurrentParse()
        self.textStorageObserver?.cancel()
        
        super.close()
    }
    
    
    /// setup print setting including print panel
    override func printOperation(withSettings printSettings: [NSPrintInfo.AttributeKey: Any]) throws -> NSPrintOperation {
        
        let viewController = self.viewController!
        
        // create printView
        let printView = PrintTextView()
        printView.setLayoutOrientation(viewController.verticalLayoutOrientation ? .vertical : .horizontal)
        printView.documentName = self.displayName
        printView.filePath = self.fileURL?.path
        printView.syntaxParser.style = self.syntaxParser.style
        printView.documentShowsInvisibles = viewController.showsInvisibles
        printView.documentShowsLineNumber = viewController.showsLineNumber
        printView.baseWritingDirection = viewController.writingDirection
        printView.ligature = UserDefaults.standard[.ligature] ? .standard : .none
        
        // set font for printing
        printView.font = UserDefaults.standard[.setPrintFont]
            ? NSFont(name: UserDefaults.standard[.printFontName], size: UserDefaults.standard[.printFontSize])
            : viewController.font
        
        // [caution] need to set string after setting other properties
        printView.string = self.textStorage.string
        
        // detect URLs manually (2019-05 macOS 10.14).
        // -> TextView anyway links all URLs in the printed PDF even the auto URL detection is disabled,
        //    but then, multiline-URLs over a page break would be broken. (cf. #958)
        printView.detectLink()
        
        // create print operation
        let printInfo = self.printInfo
        printInfo.dictionary().addEntries(from: printSettings)
        let printOperation = NSPrintOperation(view: printView, printInfo: printInfo)
        printOperation.showsProgressPanel = true
        // -> This flag looks fancy but needs to disable
        //    since NSTextView seems to cannot print in a background thraed (macOS -10.15).
        printOperation.canSpawnSeparateThread = false
        
        // setup print panel
        printOperation.printPanel.addAccessoryController(self.printPanelAccessoryController)
        printOperation.printPanel.options.formUnion([.showsPaperSize, .showsOrientation, .showsScaling])
        
        return printOperation
    }
    
    
    /// printing information associated with the document
    override var printInfo: NSPrintInfo {
        
        get {
            let printInfo = super.printInfo
            
            printInfo.horizontalPagination = .fit
            printInfo.isHorizontallyCentered = false
            printInfo.isVerticallyCentered = false
            printInfo.leftMargin = PrintTextView.horizontalPrintMargin
            printInfo.rightMargin = PrintTextView.horizontalPrintMargin
            printInfo.topMargin = PrintTextView.verticalPrintMargin
            printInfo.bottomMargin = PrintTextView.verticalPrintMargin
            printInfo.dictionary()[NSPrintInfo.AttributeKey.headerAndFooter] = true
            
            return printInfo
        }
        
        set {
            super.printInfo = newValue
        }
    }
    
    
    /// document was updated
    override func updateChangeCount(_ change: NSDocument.ChangeType) {
        
        self.isTransient = false
        
        super.updateChangeCount(change)
    }
    
    
    
    // MARK: Protocols
    
    /// file has been modified by an external process
    override func presentedItemDidChange() {
        
        // [caution] This method can be called from any thread.
        
        // [caution] DO NOT invoke `super.presentedItemDidChange()` that reverts document automatically if autosavesInPlace is enable.
//        super.presentedItemDidChange()
        
        guard
            UserDefaults.standard[.documentConflictOption] != .ignore,
            !self.isExternalUpdateAlertShown,  // don't check twice if already notified
            let fileURL = self.fileURL
            else { return }
        
        var didChange = false
        var fileModificationDate: Date?
        var coordinatorError: NSError?
        NSFileCoordinator(filePresenter: self).coordinate(readingItemAt: fileURL, options: .withoutChanges, error: &coordinatorError) { (newURL) in  // FILE_READ
            let data: Data
            do {
                // ignore if file's modificationDate is the same as document's modificationDate
                fileModificationDate = try FileManager.default.attributesOfItem(atPath: newURL.path)[.modificationDate] as? Date
                guard fileModificationDate != self.fileModificationDate else { return }
                
                // check if file contents was changed from the stored file data
                data = try Data(contentsOf: newURL, options: [.mappedIfSafe])
            } catch {
                return assertionFailure(error.localizedDescription)
            }
            didChange = (data != self.fileData)
        }
        if let error = coordinatorError {
            assertionFailure(error.localizedDescription)
        }
        
        guard didChange else {
            // update the document's fileModificationDate for a workaround (2014-03 by 1024jp)
            // -> If not, an alert shows up when user saves the file.
            DispatchQueue.main.async { [weak self] in
                guard
                    let lastModificationDate = self?.fileModificationDate,
                    let fileModificationDate = fileModificationDate,
                    lastModificationDate < fileModificationDate
                    else { return }
                
                self?.fileModificationDate = fileModificationDate
            }
            return
        }
        
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
    
    
    /// apply current state to menu items
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
    
    
    /// open existing document file (alternative methods for `init(contentsOf:ofType:)`)
    func didMakeDocumentForExisitingFile(url: URL) {
        
        // [caution] This method may be called from a background thread due to concurrent-opening.
        // -> This method won't be invoked on Resume. (2015-01-26)
        
        ScriptManager.shared.dispatch(event: .documentOpened, document: self)
    }
    
    
    
    // MARK: Public Methods
    
    /// Return whole string in the current text storage which document's line endings are already applied to.
    ///
    /// - Note: The internal text storage has always LF for its line ending.
    var string: String {
        
        let editorString = self.textStorage.string.immutable  // line ending is always LF
        
        if self.lineEnding == .lf {
            return editorString
        }
        
        return editorString.replacingLineEndings(with: self.lineEnding)
    }
    
    
    /// return document window's editor wrapper
    var viewController: DocumentViewController? {
        
        return (self.windowControllers.first?.contentViewController as? WindowContentViewController)?.documentViewController
    }
    
    
    /// reinterpret file with the desired encoding
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
            self.readingEncoding = self.fileEncoding.encoding
            
            throw ReinterpretationError.reinterpretationFailed(fileURL: fileURL, encoding: encoding)
        }
    }
    
    
    /// change file encoding registering process to the undo manager
    ///
    /// - Throws: `EncodingError` (Kind.lossyConversion) can be thorwn but only if `lossy` flag is `true`.
    func changeEncoding(to fileEncoding: FileEncoding, lossy: Bool) throws {
        
        assert(Thread.isMainThread)
        
        guard fileEncoding != self.fileEncoding else { return }
        
        // check if conversion is lossy
        guard lossy || self.string.canBeConverted(to: fileEncoding.encoding) else {
            throw EncodingError(kind: .lossyConversion, fileEncoding: fileEncoding, attempter: self)
        }
        
        // register undo
        if let undoManager = self.undoManager {
            undoManager.registerUndo(withTarget: self) { [currentFileEncoding = self.fileEncoding] target in
                try? target.changeEncoding(to: currentFileEncoding, lossy: lossy)
            }
            undoManager.setActionName(String(format: "Encoding to “%@”".localized, fileEncoding.localizedName))
        }
        
        // update encoding
        self.fileEncoding = fileEncoding
        
        // check encoding compatibility
        self.incompatibleCharacterScanner.scan()
    }
    
    
    /// change line endings registering process to the undo manager
    func changeLineEnding(to lineEnding: LineEnding) {
        
        assert(Thread.isMainThread)
        
        guard lineEnding != self.lineEnding else { return }
        
        // register undo
        if let undoManager = self.undoManager {
            undoManager.registerUndo(withTarget: self) { [currentLineEnding = self.lineEnding] target in
                target.changeLineEnding(to: currentLineEnding)
            }
            undoManager.setActionName(String(format: "Line Endings to “%@”".localized, lineEnding.name))
        }
        
        // update line ending
        self.lineEnding = lineEnding
        
        // update UI
        self.analyzer.invalidate()
    }
    
    
    /// change syntax style with style name
    func setSyntaxStyle(name: String, isInitial: Bool = false) {
        
        guard
            let syntaxStyle = SyntaxManager.shared.setting(name: name),
            syntaxStyle != self.syntaxParser.style
            else { return }
        
        // update
        self.syntaxParser.invalidateCurrentParse()
        self.syntaxParser.style = syntaxStyle
        
        // skip notification when initial style was set on file open
        // to avoid redundant highlight parse due to async notification.
        guard !isInitial else { return }
        
        self.didChangeSyntaxStyle.send(name)
    }
    
    
    
    // MARK: Action Messages
    
    /// save document
    @IBAction override func save(_ sender: Any?) {
        
        self.askSavingSafety { (continuesSaving: Bool) in
            guard continuesSaving else { return }
            
            super.save(sender)
        }
    }
    
    
    /// save document with new name
    @IBAction override func saveAs(_ sender: Any?) {
        
        self.askSavingSafety { (continuesSaving: Bool) in
            guard continuesSaving else { return }
            
            super.saveAs(sender)
        }
    }
    
    
    /// change line ending with sender's tag
    @IBAction func changeLineEnding(_ sender: NSMenuItem) {
        
        guard let lineEnding = LineEnding(index: sender.tag) else { return assertionFailure() }
        
        self.changeLineEnding(to: lineEnding)
    }
    
    
    /// change document file encoding
    @IBAction func changeEncoding(_ sender: NSMenuItem) {
        
        let fileEncoding = FileEncoding(tag: sender.tag)
        
        guard fileEncoding != self.fileEncoding else { return }
        
        // change encoding interactively
        self.performActivity(withSynchronousWaiting: true) { [unowned self] (activityCompletionHandler) in
            
            let completionHandler = { [weak self] (didChange: Bool) in
                if !didChange, let self = self {
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
            alert.informativeText = String(format: "Do you want to convert or reinterpret this document using “%@”?".localized, fileEncoding.localizedName)
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
                            alert.informativeText = String(format: "Do you want to discard the changes and reopen the document using “%@”?".localized, fileEncoding.localizedName)
                            alert.addButton(withTitle: "Cancel".localized)
                            alert.addButton(withTitle: "Discard Changes".localized)
                            alert.buttons.last?.hasDestructiveAction = true
                            
                            documentWindow.attachedSheet?.orderOut(self)  // close previous sheet
                            let returnCode = alert.runModal(for: documentWindow)  // wait for sheet close
                            
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
    
    
    /// change syntax style
    @IBAction func changeSyntaxStyle(_ sender: AnyObject?) {
        
        guard let name = sender?.title else { return assertionFailure() }
        
        self.setSyntaxStyle(name: name)
    }
    
    
    /// insert IANA CharSet name to editor's insertion point
    @IBAction func insertIANACharSetName(_ sender: Any?) {
        
        guard let string = self.fileEncoding.encoding.ianaCharSetName else { return }
        
        self.insert(string: string)
    }
    
    
    
    // MARK: Private Methods
    
    /// transfer file information to UI
    private func applyContentToWindow() {
        
        // update status bar and document inspector
        self.analyzer.invalidate()
        
        // update incompatible characters if pane is visible
        self.incompatibleCharacterScanner.invalidate()
        
        guard let viewController = self.viewController else { return }
        
        // update view
        viewController.invalidateStyleInTextStorage()
        if self.isVerticalText {
            viewController.verticalLayoutOrientation = true
        }
    }
    
    
    /// check if can save safely with the current encoding and ask if not
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
    
    
    /// check if the content can be saved with the file encoding
    private func checkSavingSafetyForConverting() throws {
        
        guard self.string.canBeConverted(to: self.fileEncoding.encoding) else {
            throw EncodingError(kind: .lossySaving, fileEncoding: self.fileEncoding, attempter: self)
        }
    }
    
    
    /// display alert about file modification by an external process
    private func showUpdatedByExternalProcessAlert() {
        
        assert(Thread.isMainThread)
        
        // do nothing if alert is already shown
        guard !self.isExternalUpdateAlertShown else { return }
        
        self.performActivity(withSynchronousWaiting: true) { [unowned self] activityCompletionHandler in
            self.isExternalUpdateAlertShown = true
            
            let messageText = self.isDocumentEdited
                ? "The file has been modified by another application. There are also unsaved changes in CotEditor."
                : "The file has been modified by another application."
            
            let alert = NSAlert()
            alert.messageText = messageText.localized
            alert.informativeText = "Do you want to keep CotEditor’s edition or update to the modified edition?".localized
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
            
            alert.beginSheetModal(for: documentWindow) { returnCode in
                if returnCode == .alertSecondButtonReturn {  // == Revert
                    self.revertWithoutAsking()
                }
                
                self.isExternalUpdateAlertShown = false
                activityCompletionHandler()
            }
        }
    }
    
    
    /// Revert receiver with current document file without asking to user before
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



// MARK: - Protocol

extension Document: Editable {
    
    var textView: NSTextView? {
        
        return self.viewController?.focusedTextView
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
            
            case .reinterpretationFailed(let fileURL, let encoding):
                return String(format: "The file “%@” couldn’t be reinterpreted using text encoding “%@”.".localized,
                              fileURL.lastPathComponent, String.localizedName(of: encoding))
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
        
        return String(format: "Some characters would have to be changed or deleted in saving as “%@”.".localized, self.fileEncoding.localizedName)
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
            windowContentController?.showSidebarPane(index: .incompatibleCharacters)
        }
    }
    
}
