/*
 
 Document.swift
 
 CotEditor
 https://coteditor.com
 
 Created by nakamuxu on 2004-12-08.
 
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014-2016 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Cocoa

extension Notification.Name {
    
    static let DocumentDidChangeEncoding = Notification.Name("DocumentDidChangeEncoding")
    static let DocumentDidChangeLineEnding = Notification.Name("DocumentDidChangeLineEnding")
    static let DocumentDidChangeSyntaxStyle = Notification.Name("DocumentDidChangeSyntaxStyle")
}


// constants

private let UniqueFileIDLength = 8

/// Maximal length to scan encoding declaration
private let MaxEncodingScanLength = 2000

private enum SerializationKey {
    static let readingEncoding = "readingEncoding"
    static let syntaxStyle = "syntaxStyle"
    static let autosaveIdentifier = "autosaveIdentifier"
}

// file extended attributes
private let NSFileExtendedAttributes = FileAttributeKey("NSFileExtendedAttributes")
private enum FileExtendedAttributeName {
    static let Encoding = "com.apple.TextEncoding"
    static let VerticalText = "com.coteditor.VerticalText"
}



// MARK:

final class Document: NSDocument, EncodingHolder {
    
    // MARK: Readonly Properties
    
    let textStorage = NSTextStorage()
    private(set) var encoding: String.Encoding
    private(set) var hasUTF8BOM = false
    private(set) var lineEnding: LineEnding
    private(set) var fileAttributes: [FileAttributeKey: Any]?
    private(set) var syntaxStyle: SyntaxStyle
    
    private(set) lazy var selection: TextSelection = TextSelection(document: self)
    private(set) lazy var analyzer: DocumentAnalyzer = DocumentAnalyzer(document: self)
    private(set) lazy var incompatibleCharacterScanner: IncompatibleCharacterScanner = IncompatibleCharacterScanner(document: self)
    
    
    // MARK: Private Properties
    
    private lazy var printPanelAccessoryController: PrintPanelAccessoryController = PrintPanelAccessoryController()
    @IBOutlet private weak var savePanelAccessoryView: NSView?
    
    private var readingEncoding: String.Encoding  // encoding to read document file
    private var needsShowUpdateAlertWithBecomeKey = false
    private var isExternalUpdateAlertShown = false
    private var fileHash: Data?  // MD5
    private var isVerticalText = false
    private var odbEventSender: ODBEventSender?
    private var shouldSaveXattr = true
    private var autosaveIdentifier: String
    private var suppressesIANACharsetConflictAlert = false
    private dynamic var isExecutable = false  // bind in save panel accessory view
    
    
    
    // MARK:
    // MARK: Lifecycle
    
    override init() {
        
        // [caution] This method may be called from a background thread due to concurrent-opening.
        
        let uuid = UUID().uuidString
        self.autosaveIdentifier = uuid.substring(to: uuid.index(uuid.startIndex, offsetBy: UniqueFileIDLength))
        
        self.encoding = String.Encoding(rawValue: Defaults[.encodingInNew])
        if self.encoding == .utf8 {
            self.hasUTF8BOM = Defaults[.saveUTF8BOM]
        }
        self.lineEnding = LineEnding(index: Defaults[.lineEndCharCode]) ?? .LF
        self.syntaxStyle = SyntaxManager.shared.style(name: Defaults[.syntaxStyle]) ?? SyntaxStyle()
        
        // set encoding to read file
        // -> The value is either user setting or selection of open panel.
        // -> This must be set before `readFromData:ofType:error:` is called.
        self.readingEncoding = (DocumentController.shared() as! DocumentController).accessorySelectedEncoding
        
        super.init()
        
        self.hasUndoManager = true
        
        // observe sytnax style update
        NotificationCenter.default.addObserver(self, selector: #selector(syntaxDidUpdate), name: .StyntaxDidUpdate, object: nil)
    }
    
    
    /// initialize instance with existing file
    convenience init(fileURL url: URL, ofType typeName: String) throws {
        
        // [caution] This method may be called from a background thread due to concurrent-opening.
        // This method won't be invoked on Resume. (2015-01-26)
        
        // Workaround initializer in order to invoke self's (actually super's) `init(contentsOf:ofType:)` inside.
        
        try self.init(contentsOf: url, ofType: typeName)
        
        // set sender of external editor protocol (ODB Editor Suite)
        self.odbEventSender = ODBEventSender()
        
        // check file meta data for text orientation
        if Defaults[.savesTextOrientation] {
            let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)  // FILE_READ
            self.isVerticalText = ((attributes?[NSFileExtendedAttributes] as? [String: Any])?[FileExtendedAttributeName.VerticalText] != nil)
        }
    }
    
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    /// store internal document state
    override func encodeRestorableState(with coder: NSCoder) {
        
        coder.encode(Int(self.encoding.rawValue), forKey: SerializationKey.readingEncoding)
        coder.encode(self.autosaveIdentifier, forKey: SerializationKey.autosaveIdentifier)
        coder.encode(self.syntaxStyle.styleName, forKey: SerializationKey.syntaxStyle)
        
        super.encodeRestorableState(with: coder)
    }
    
    
    /// resume UI state
    override func restoreState(with coder: NSCoder) {
        
        super.restoreState(with: coder)
        
        if coder.containsValue(forKey: SerializationKey.readingEncoding) {
            self.readingEncoding = String.Encoding(rawValue: UInt(coder.decodeInteger(forKey: SerializationKey.readingEncoding)))
        }
        if let identifier = coder.decodeObject(forKey: SerializationKey.autosaveIdentifier) as? String {
            self.autosaveIdentifier = identifier
        }
        if let styleName = coder.decodeObject(forKey: SerializationKey.syntaxStyle) as? String {
            self.setSyntaxStyle(name: styleName)
        }
    }
    
    
    
    // MARK: Document Methods
    
    /// enable Autosave in Place
    override class func autosavesInPlace() -> Bool {
        
        return self._autosavesInPlace
    }
    // avoid changing the value while the application is running
    private static let _autosavesInPlace = Defaults[.enablesAutosaveInPlace]
    
    
    /// can read document on a background thread?
    override class func canConcurrentlyReadDocuments(ofType: String) -> Bool {
        
        return true
    }
    
    
    /// enable asynchronous saving
    override func canAsynchronouslyWrite(to url: URL, ofType typeName: String, for saveOperation: NSSaveOperationType) -> Bool {
        
        return saveOperation == .autosaveElsewhereOperation || saveOperation == .autosaveInPlaceOperation
    }
    
    
    /// make custom windowControllers
    override func makeWindowControllers() {
        
        let storyboard = NSStoryboard(name: "DocumentWindow", bundle: nil)
        let windowController = storyboard.instantiateInitialController() as! NSWindowController
        
        self.addWindowController(windowController)
    }
    
    
    /// URL of document file
    override var fileURL: URL? {
        
        didSet {
            guard self.fileURL != oldValue else { return }
            
            DispatchQueue.main.async { [weak self] in
                self?.analyzer.invalidateFileInfo()
            }
        }
    }
    
    
    /// return preferred file extension corresponding the current syntax style
    override func fileNameExtension(forType typeName: String, saveOperation: NSSaveOperationType) -> String? {
        
        if let pathExtension = self.fileURL?.pathExtension {
            return pathExtension
        }
        
        let styleName = self.syntaxStyle.styleName
        let extensions = SyntaxManager.shared.extensions(name: styleName)
        
        return extensions.first
    }
    
    
    /// revert to saved file contents
    override func revert(toContentsOf url: URL, ofType typeName: String) throws {
        
        // once force-close all sheets
        //   -> Presented errors will be displayed again after the revert automatically (since OS X 10.10).
        self.windowForSheet?.sheets.forEach { $0.close() }
        
        try super.revert(toContentsOf: url, ofType: typeName)
        
        // apply to UI
        self.applyContentToWindow()
    }
    
    
    /// setup duplicated document
    override func duplicate() throws -> NSDocument {
        
        let document = try super.duplicate() as! Document
        
        document.setSyntaxStyle(name: self.syntaxStyle.styleName)
        document.lineEnding = self.lineEnding
        document.encoding = self.encoding
        document.hasUTF8BOM = self.hasUTF8BOM
        
        // apply text orientation
        document.viewController?.verticalLayoutOrientation = self.viewController?.verticalLayoutOrientation ?? self.isVerticalText
        
        return document
    }
    
    
    /// load document from file and return whether it succeeded
    override func read(from url: URL, ofType typeName: String) throws {
        
        // [caution] This method may be called from a background thread due to concurrent-opening.
        
        let data = try Data(contentsOf: url)  // FILE_READ
        
        // store file hash (MD5) in order to check the file content identity in `presentedItemDidChange`
        self.fileHash = data.md5
        
        // read file attributes only if `fileURL` exists
        // -> The passed-in `url` in this method can point to a file that isn't the real document file,
        //    for example on resuming of an unsaved document.
        if let filePath = self.fileURL?.path {
            if let attributes = try? FileManager.default.attributesOfItem(atPath: filePath) {  // FILE_READ
                self.fileAttributes = attributes
                let posixPermissions = (attributes[.posixPermissions] as? UInt16) ?? 0
                self.isExecutable = (posixPermissions & S_IXUSR) != 0
            }
        }
        
        // try reading the `com.apple.TextEncoding` extended attribute
        let xattrEncoding: String.Encoding? = {
            guard
                let extendedAttributes = (try? FileManager.default.attributesOfItem(atPath: url.path)[NSFileExtendedAttributes]) as? [String: Any],
                let xattrEncodingData = extendedAttributes[FileExtendedAttributeName.Encoding] as? Data
                else { return nil }
            
            return xattrEncodingData.decodingXattrEncoding
        }()
        self.shouldSaveXattr = (xattrEncoding != nil)
        
        // decode Data to String
        let content: String
        let encoding: String.Encoding
        if self.readingEncoding == .autoDetection {
            (content, encoding) = try self.string(data: data, xattrEncoding: xattrEncoding)
        } else {
            encoding = self.readingEncoding
            if !data.isEmpty {
                content = try String(contentsOf: url, encoding: encoding)  // FILE_READ
            } else {
                content = ""
            }
        }
        
        // set read values
        self.encoding = encoding
        self.hasUTF8BOM = (encoding == .utf8) && data.hasUTF8BOM
        
        if let lineEnding = content.detectedLineEnding {  // keep default if no line endings are found
            self.lineEnding = lineEnding
        }
        
        // notify
        DispatchQueue.main.async { [weak self] in
            NotificationCenter.default.post(name: .DocumentDidChangeEncoding, object: self)
            NotificationCenter.default.post(name: .DocumentDidChangeLineEnding, object: self)
        }
        
        // standardize line endings to LF (File Open)
        // (Line endings replacemement by other text modifications are processed in the following methods.)
        //
        // # Methods Standardizing Line Endings on Text Editing
        //   - File Open:
        //       - Document > read(from:ofType:)
        //   - Key Typing, Script, Paste, Drop or Replace via Find Panel:
        //       - EditorTextViewController > textView(_:shouldChangeTextInRange:replacementString:)
        let string = content.replacingLineEndings(with: .LF)
        
        self.textStorage.replaceCharacters(in: self.textStorage.string.nsRange, with: string)
        
        // determine syntax style
        let styleName = SyntaxManager.shared.styleName(documentFileName: url.lastPathComponent)
            ?? SyntaxManager.shared.styleName(documentContent: string)
            ?? Defaults[.syntaxStyle]
        
        self.setSyntaxStyle(name: styleName)
    }
    
    
    /// create Data object to save
    override func data(ofType typeName: String) throws -> Data {
        
        // [caution] This method may be called from a background thread due to async-saving.
        
        let encoding = self.encoding
        let needsUTF8BOM = (encoding == .utf8) && self.hasUTF8BOM
        
        // convert Yen sign in consideration of the current encoding
        let string = self.string.convertingYenSign(for: encoding)
        
        // unblock the user interface, since fetching current document state has been done here
        self.unblockUserInteraction()
        
        // get data from string to save
        guard var data = string.data(using: encoding, allowLossyConversion: true) else {
            throw NSError(domain: CocoaError.errorDomain,
                          code: CocoaError.fileWriteInapplicableStringEncoding.rawValue,
                          userInfo: [NSStringEncodingErrorKey: encoding.rawValue])
        }
        
        // add UTF-8 BOM if needed
        if needsUTF8BOM {
            data = data.addingUTF8BOM
        }
        
        return data
    }
    
    
    /// save or autosave the document contents to a file
    override func save(to url: URL, ofType typeName: String, for saveOperation: NSSaveOperationType, completionHandler: @escaping (Error?) -> Void) {
        
        // trim trailing whitespace if needed
        if Defaults[.trimsTrailingWhitespaceOnSave] {
            let keepsEditingPoint = (saveOperation == .autosaveInPlaceOperation || saveOperation == .autosaveElsewhereOperation)
            
            for layoutManager in self.textStorage.layoutManagers {
                guard
                    let textView = layoutManager.textViewForBeginningOfSelection,
                    let window = textView.window else { continue }
                
                if !keepsEditingPoint || layoutManager.layoutManagerOwnsFirstResponder(in: window) {
                    textView.trimTrailingWhitespace(keepingEditingPoint: keepsEditingPoint)
                    break  // trimming once is enough
                }
            }
        }
        
        // break undo grouping
        for layoutManager in self.textStorage.layoutManagers {
            layoutManager.textViewForBeginningOfSelection?.breakUndoCoalescing()
        }
        
        // modify place to create backup file
        //   -> save backup file always in `~/Library/Autosaved Information/` directory
        //      (The default backup URL is the same directory as the fileURL.)
        let newUrl: URL = {
            guard let fileURL = self.fileURL, saveOperation == .autosaveElsewhereOperation else { return url }
            
            let autosaveDirectoryURL = (DocumentController.shared() as! DocumentController).autosaveDirectoryURL
            var baseFileName = fileURL.deletingPathExtension().lastPathComponent
            if baseFileName.hasPrefix(".") {  // avoid file to be hidden
                baseFileName.remove(at: baseFileName.startIndex)
            }
            // append a unique string to avoid overwriting another backup file with the same file name.
            let fileName = baseFileName + " (\(self.autosaveIdentifier))"
            
            return autosaveDirectoryURL.appendingPathComponent(fileName).appendingPathExtension(fileURL.pathExtension)
        }()
        
        super.save(to: newUrl, ofType: typeName, for: saveOperation) { [weak self] (error: Error?) in
            guard let `self` = self else { return }
            
            // [note] This completionHandler block will always be invoked on the main thread.
         
            defer {
                completionHandler(error)
            }
            
            guard error == nil else { return }
            
            // apply syntax style that is inferred from the file name
            if saveOperation == .saveAsOperation {
                let fileName = url.lastPathComponent
                if let styleName = SyntaxManager.shared.styleName(documentFileName: fileName) {
                    self.setSyntaxStyle(name: styleName)
                }
            }
            
            if saveOperation != .autosaveElsewhereOperation {
                // get the latest file attributes
                self.fileAttributes = try? FileManager.default.attributesOfItem(atPath: url.path)  // FILE_READ
                
                // update file information
                self.analyzer.invalidateFileInfo()
                
                // send file update notification for the external editor protocol (ODB Editor Suite)
                self.odbEventSender?.sendModifiedEvent(fileURL: url, operation: saveOperation)
            }
        }
    }
    
    
    /// write new data to file (invoked in file saving proccess)
    override func write(to url: URL, ofType typeName: String, for saveOperation: NSSaveOperationType, originalContentsURL absoluteOriginalContentsURL: URL?) throws {
        
        // [caution] This method may be called from a background thread due to async-saving.
        
        // store current state here, since the main thread will already be unblocked after `data(ofType:)`
        let encoding = self.encoding
        self.isVerticalText = self.viewController?.verticalLayoutOrientation ?? false
        
        try super.write(to: url, ofType: typeName, for: saveOperation, originalContentsURL: absoluteOriginalContentsURL)
        
        if saveOperation != .autosaveElsewhereOperation {
            // store file hash (MD5) in order to check the file content identity in `presentedItemDidChange`
            if let data = try? Data(contentsOf: url) {  // FILE_READ
                self.fileHash = data.md5
            }
            
            // store file encoding for revert
            self.readingEncoding = encoding
        }
    }
    
    
    /// customize document's file attributes
    override func fileAttributesToWrite(to url: URL, ofType typeName: String, for saveOperation: NSSaveOperationType, originalContentsURL absoluteOriginalContentsURL: URL?) throws -> [String : Any] {
        
        // [caution] This method may be called from a background thread due to async-saving.
        
        var attributes = try super.fileAttributesToWrite(to: url, ofType: typeName, for: saveOperation, originalContentsURL: absoluteOriginalContentsURL)
        
        // set extended file attributes
        var extendedAttributes: [String: Any] = (attributes[NSFileExtendedAttributes.rawValue] as? [String: Any]) ?? [:]
        // save encoding to the extended file attributes (com.apple.TextEncoding)
        if saveOperation == .autosaveElsewhereOperation || self.shouldSaveXattr {
            extendedAttributes[FileExtendedAttributeName.Encoding] = self.encoding.xattrEncodingData
        }
        // save text orientation state to the extended file attributes (com.coteditor.VerticalText)
        if Defaults[.savesTextOrientation] {
            extendedAttributes[FileExtendedAttributeName.VerticalText] = self.isVerticalText ? Data(bytes: [1]) : nil
        }
        if attributes[NSFileExtendedAttributes.rawValue] != nil || !extendedAttributes.isEmpty {
            attributes[NSFileExtendedAttributes.rawValue] = extendedAttributes
        }
        
        // give the execute permission if user requested
        if self.isExecutable && saveOperation != .autosaveElsewhereOperation {
            var permissions = (attributes[FileAttributeKey.posixPermissions.rawValue] as? UInt16) ?? 0
            if let originalPath = absoluteOriginalContentsURL?.path, permissions == 0 {
                permissions = ((try? FileManager.default.attributesOfItem(atPath: originalPath))?[.posixPermissions] as? UInt16) ?? 0  // FILE_READ
            }
            if permissions == 0 {
                permissions = 0o644  // ???: Is the default permission really always 644?
            }
            permissions |= S_IXUSR
            attributes[FileAttributeKey.posixPermissions.rawValue] = NSNumber(value: permissions)
        }
        
        return attributes
    }
    
    
    /// avoid let system add the standard save panel accessory (pop-up menu for document type change)
    override var shouldRunSavePanelWithAccessoryView: Bool {
        
        return false
    }
    
    
    /// prepare save panel
    override func prepareSavePanel(_ savePanel: NSSavePanel) -> Bool {
        
        // disable hide extension checkbox
        // -> Because it doesn't work.
        savePanel.isExtensionHidden = false
        savePanel.canSelectHiddenExtension = false
        
        // set default file extension in hacky way (2016-10 on macOS 10.12 SDK for macOS 10.10 - 10.12)
        self.allowedFileTypes = nil
        savePanel.allowedFileTypes = nil  // nil allows setting any extension
        if let pathExtension = self.fileNameExtension(forType: self.fileType!, saveOperation: .saveOperation) {
            // bind allowedFileTypes flag with savePanel
            // -> So that initial filename selection excludes file extension.
            self.allowedFileTypes = [pathExtension]
            savePanel.bind(#keyPath(NSSavePanel.allowedFileTypes), to: self, withKeyPath: #keyPath(allowedFileTypes))
            
            //disable and unbind `allowedFileTypes` immediately in the next runloop to allow set other extensions
            DispatchQueue.main.async { [weak self] in
                self?.allowedFileTypes = nil
                savePanel.unbind(#keyPath(NSSavePanel.allowedFileTypes))
            }
        }
        
        // set accessory view
        if self.savePanelAccessoryView == nil {
            Bundle.main.loadNibNamed("SaveDocumentAccessory", owner: self, topLevelObjects: nil)
        }
        savePanel.accessoryView = self.savePanelAccessoryView
        
        return super.prepareSavePanel(savePanel)
    }
    private dynamic var allowedFileTypes: [String]? = nil
    
    
    /// display dialogs about save before closing document
    override func canClose(withDelegate delegate: Any, shouldClose shouldCloseSelector: Selector?, contextInfo: UnsafeMutableRawPointer?) {
        
        // disable save dialog if content is empty and not saved
        if self.fileURL == nil && self.textStorage.string.isEmpty {
            self.updateChangeCount(.changeCleared)
        }
        
        super.canClose(withDelegate: delegate, shouldClose: shouldCloseSelector, contextInfo: contextInfo)
    }
    
    
    /// close document
    override func close() {
        
        self.syntaxStyle.cancelAllParses()
        
        // send file close notification for the external editor protocol (ODB Editor Suite)
        if let fileURL = self.fileURL {
            self.odbEventSender?.sendCloseEvent(fileURL: fileURL)
        }
        
        super.close()
    }
    
    
    /// setup print setting including print panel
    override func printOperation(withSettings printSettings: [String : Any]) throws -> NSPrintOperation {
        
        let viewController = self.viewController!
        
        // create printView
        let printView = PrintTextView()
        printView.setLayoutOrientation(viewController.verticalLayoutOrientation ? .vertical : .horizontal)
        printView.theme = viewController.theme
        printView.documentName = self.displayName
        printView.filePath = self.fileURL?.path
        printView.syntaxName = self.syntaxStyle.styleName
        printView.documentShowsInvisibles = viewController.showsInvisibles
        printView.documentShowsLineNumber = viewController.showsLineNumber
        
        // set font for printing
        printView.font = {
            if Defaults[.setPrintFont] {  // == use printing font
                return NSFont(name: Defaults[.printFontName]!,
                              size: Defaults[.printFontSize])
            }
            return viewController.font
        }()
        
        // [caution] need to set string after setting other properties
        printView.string = self.textStorage.string
        
        // create print operation
        let printOperation = NSPrintOperation(view: printView, printInfo: self.printInfo)
        printOperation.printInfo.dictionary().addEntries(from: printSettings)
        printOperation.showsProgressPanel = true
        printOperation.canSpawnSeparateThread = true  // display print progress panel as a sheet
        
        // setup print panel
        printOperation.printPanel.addAccessoryController(self.printPanelAccessoryController)
        printOperation.printPanel.options.formUnion([.showsPaperSize, .showsOrientation, .showsScaling])
        
        return printOperation
    }
    
    
    /// printing information associated with the document
    override var printInfo: NSPrintInfo {
        
        get {
            let printInfo = super.printInfo
            
            printInfo.horizontalPagination = .fitPagination
            printInfo.isHorizontallyCentered = false
            printInfo.isVerticallyCentered = false
            printInfo.leftMargin = kHorizontalPrintMargin
            printInfo.rightMargin = kHorizontalPrintMargin
            printInfo.topMargin = kVerticalPrintMargin
            printInfo.bottomMargin = kVerticalPrintMargin
            printInfo.dictionary()[NSPrintHeaderAndFooter] = true
            
            return printInfo
        }

        set {
            super.printInfo = newValue
        }
    }
    
    
    
    // MARK: Protocols
    
    /// file has been modified by an external process
    override func presentedItemDidChange() {
        
        // [caution] This method can be called from any thread.
        
        // [caution] DO NOT invoke `super.presentedItemDidChange()` that reverts document automatically if autosavesInPlace is enable.
//        super.presentedItemDidChange()
        
        let option = DocumentConflictOption(rawValue: Defaults[.documentConflictOption]) ?? .notify
        
        // do nothing
        if option == .ignore { return }
        
        // don't check twice if document is already marked as modified
        guard !self.needsShowUpdateAlertWithBecomeKey else { return }
        
        guard let fileURL = self.fileURL else { return }
        
        // ignore if file's modificationDate is the same as document's modificationDate
        var fileModificationDate: Date?
        let coordinator = NSFileCoordinator(filePresenter: self)
        coordinator.coordinate(readingItemAt: fileURL, options: .withoutChanges, error: nil) { (newURL) in
            fileModificationDate = (try? FileManager.default.attributesOfItem(atPath: newURL.path))?[.modificationDate] as? Date  // FILE_READ
        }
        guard fileModificationDate != self.fileModificationDate else { return }
        
        // ignore if file's MD5 hash is the same as the stored MD5 and deal as if it was not modified
        var fileHash: Data?
        coordinator.coordinate(readingItemAt: fileURL, options: .withoutChanges, error: nil) { (newURL) in
            fileHash = try? Data(contentsOf: newURL).md5  // FILE_READ
        }
        guard fileHash != self.fileHash else {
            // update the document's fileModificationDate for a workaround (2014-03 by 1024jp)
            // If not, an alert shows up when user saves the file.
            if let lastModificationDate = self.fileModificationDate,
               let fileModificationDate = fileModificationDate,
               lastModificationDate < fileModificationDate {
                self.fileModificationDate = fileModificationDate
            }
            return
        }
        
        // notify about external file update
        DispatchQueue.main.async { [weak self] in
            switch option {
            case .ignore:
                break
            case .notify:
                // notify and show dialog later
                self?.notifyExternalFileUpdate()
            case .revert:
                if let fileURL = self?.fileURL, let fileType = self?.fileType {
                    try? self?.revert(toContentsOf: fileURL, ofType: fileType)
                }
            }
        }
    }
    
    
    /// apply current state to menu items
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        
        guard let action = menuItem.action else { return false }
        
        switch action {
        case #selector(changeEncoding(_:)):
            let encodingTag = self.hasUTF8BOM ? -Int(self.encoding.rawValue) : Int(self.encoding.rawValue)
            menuItem.state = (menuItem.tag == encodingTag) ? NSOnState : NSOffState
            
        case #selector(changeLineEnding(_:)):
            menuItem.state = (LineEnding(index: menuItem.tag) == self.lineEnding) ? NSOnState : NSOffState
            
        case #selector(changeSyntaxStyle(_:)):
            let name = self.syntaxStyle.styleName
            menuItem.state = (menuItem.title == name) ? NSOnState : NSOffState
            
        default: break
        }
        
        return super.validateMenuItem(menuItem)
    }
    
    
    
    // MARK: Notifications
    
    /// set a flag of syntax highlight update if corresponded style has been updated
    func syntaxDidUpdate(_ notification: Notification) {
        
        guard
            let oldName = notification.userInfo?[SettingFileManager.NotificationKey.old] as? String,
            let newName = notification.userInfo?[SettingFileManager.NotificationKey.new] as? String else { return }
        
        if oldName == self.syntaxStyle.styleName {
            self.setSyntaxStyle(name: newName)
        }
    }
    
    
    
    // MARK: Public Methods
    
    /// Return whole string in the current text storage which document's line endings are already applied to.  (Note: The internal text storage has always LF for its line ending.)
    var string: String {
        
        let editorString = self.textStorage.string // line ending is always LF
        
        if self.lineEnding == .LF {
            return NSString(string: editorString) as String  // make sure being immutable
        }
        
        return editorString.replacingLineEndings(with: self.lineEnding)
    }
    
    
    /// return document window's editor wrapper
    var viewController: DocumentViewController? {
        
        return (self.windowControllers.first?.contentViewController as? WindowContentViewController)?.documentViewController
    }
    
    
    /// transfer file information to UI
    func applyContentToWindow() {
        
        guard let viewController = self.viewController else { return }
        
        viewController.invalidateStyleInTextStorage()
        
        // update status bar and document inspector
        self.analyzer.invalidateFileInfo()
        self.analyzer.invalidateModeInfo()
        self.analyzer.invalidateEditorInfo()
        
        // update incompatible characters if pane is visible
        self.incompatibleCharacterScanner.invalidate()
        
        // apply text orientation
        viewController.verticalLayoutOrientation = self.isVerticalText
    }
    
    
    
    // string encoding
    
    /// reinterpret file with the desired encoding and show error dialog if failed
    @discardableResult
    func reinterpretAndShowError(encoding: String.Encoding) {
        
        do {
            try self.reinterpret(encoding: encoding)
            
        } catch let error {
            NSBeep()
            if let window = self.windowForSheet {
                self.presentError(error, modalFor: window, delegate: nil, didPresent: nil, contextInfo: nil)
            } else {
                self.presentError(error)
            }
        }
    }
    
    
    /// reinterpret file with the desired encoding
    func reinterpret(encoding: String.Encoding) throws {
        
        guard let fileURL = self.fileURL else {
            throw EncodingError(kind: .reinterpretationFailed(fileURL: self.fileURL), encoding: encoding, withUTF8BOM: false, attempter: self)
        }
        
        // do nothing if given encoding is the same as current one
        if encoding == self.encoding { return }
        
        // reinterpret
        self.readingEncoding = encoding
        do {
            try self.revert(toContentsOf: fileURL, ofType: self.fileType!)
            
        } catch {
            self.readingEncoding = self.encoding
            throw EncodingError(kind: .reinterpretationFailed(fileURL: fileURL), encoding: encoding, withUTF8BOM: false, attempter: self)
        }
    }
    
    
    /// change string encoding registering process to the undo manager
    @discardableResult
    func changeEncoding(to encoding: String.Encoding, withUTF8BOM: Bool, askLossy: Bool, lossy: Bool) -> Bool {  // TODO: throw?
        
        guard encoding != self.encoding || withUTF8BOM != self.hasUTF8BOM else { return true }
        
        let encodingName = String.localizedName(of: encoding, withUTF8BOM: withUTF8BOM)
        
        // ask lossy
        guard !askLossy || self.string.canBeConverted(to: encoding) else {
            let error = EncodingError(kind: .lossyEncodingConversion, encoding: encoding, withUTF8BOM: withUTF8BOM, attempter: self)
            
            if let window = self.windowForSheet {
                window.attachedSheet?.orderOut(self)  // close previous sheet
                self.presentError(error, modalFor: window, delegate: nil, didPresent: nil, contextInfo: nil)
            }
            return false
        }
        
        // register undo
        if let undoManager = self.undoManager {
        (undoManager.prepare(withInvocationTarget: self) as AnyObject).objcChangeEncoding(to: self.encoding.rawValue, withUTF8BOM: self.hasUTF8BOM, askLossy: false, lossy: lossy)
        undoManager.setActionName(String(format: NSLocalizedString("Encoding to “%@”", comment: ""), encodingName))
        }
        
        // update encoding
        self.encoding = encoding
        self.hasUTF8BOM = withUTF8BOM
        
        // notify
        NotificationCenter.default.post(name: .DocumentDidChangeEncoding, object: self)
        
        // update UI
        self.incompatibleCharacterScanner.scan()
        self.analyzer.invalidateModeInfo()
        
        return true
    }
    
    
    /// dummy method for undoManager that can recognize only ObjC-compatible methods...
    func objcChangeEncoding(to encoding: UInt, withUTF8BOM: Bool, askLossy: Bool, lossy: Bool) {
        
        self.changeEncoding(to: String.Encoding(rawValue: encoding), withUTF8BOM: withUTF8BOM, askLossy: askLossy, lossy: lossy)
    }
    
    
    /// change line endings registering process to the undo manager
    func changeLineEnding(to lineEnding: LineEnding) {
        
        guard lineEnding != self.lineEnding else { return }
        
        // register undo
        if let undoManager = self.undoManager {
            (undoManager.prepare(withInvocationTarget: self) as AnyObject).objcChangeLineEnding(to: String(self.lineEnding.rawValue))
            undoManager.setActionName(String(format: NSLocalizedString("Line Endings to “%@”", comment: ""), lineEnding.name))
        }
        
        // update line ending
        self.lineEnding = lineEnding
        
        // notify
        NotificationCenter.default.post(name: .DocumentDidChangeLineEnding, object: self)
        
        // update UI
        self.analyzer.invalidateModeInfo()
        self.analyzer.invalidateEditorInfo()
    }
    
    
    /// dummy method for undoManager that can recognize only ObjC-compatible methods...
    func objcChangeLineEnding(to lineEnding: String) {
        
        self.changeLineEnding(to: LineEnding(rawValue: lineEnding.characters.first!)!)
    }
    
    
    /// change syntax style with style name
    func setSyntaxStyle(name: String?) {
        
        guard let name = name, !name.isEmpty else { return }
        
        guard let syntaxStyle = SyntaxManager.shared.style(name: name), syntaxStyle != self.syntaxStyle else { return }
        
        self.syntaxStyle.cancelAllParses()
        
        // update
        syntaxStyle.textStorage = self.textStorage
        self.syntaxStyle = syntaxStyle
        
        NotificationCenter.default.post(name: .DocumentDidChangeSyntaxStyle, object: self)
    }
    
    
    
    // MARK: Action Messages
    
    /// save document
    @IBAction override func save(_ sender: Any?) {
        
        self.askSavingSafety { (continuesSaving: Bool) in
            if continuesSaving {
                super.save(sender)
            }
        }
    }
    
    
    /// save document with new name
    @IBAction override func saveAs(_ sender: Any?) {
        
        self.askSavingSafety { (continuesSaving: Bool) in
            if continuesSaving {
                super.saveAs(sender)
            }
        }
    }
    
    
    /// show Share Service menu
    @IBAction func share(_ sender: Any?) {
        
        guard let view = sender as? NSView else { return }
        
        let items: [URL] = {
            guard let url = self.fileURL else { return [] }
            
            return [url]
        }()
        let sharingServicePicker = NSSharingServicePicker(items: items)
        
        sharingServicePicker.show(relativeTo: view.bounds, of: view, preferredEdge: .minY)
    }
    
    
    /// change line ending with sender's tag
    @IBAction func changeLineEnding(_ sender: AnyObject?) {
        
        guard
            let tag = sender?.tag,
            let lineEnding = LineEnding(index: tag) else { return }
        
        self.changeLineEnding(to: lineEnding)
    }
    
    
    /// change document file encoding
    @IBAction func changeEncoding(_ sender: AnyObject?) {
        
        guard let tag = sender?.tag, let encodingName = sender?.title else { return }
        
        let encoding = String.Encoding(rawValue: UInt(abs(tag)))
        let withUTF8BOM = (tag == -Int(String.Encoding.utf8.rawValue))
        
        guard encoding != self.encoding || withUTF8BOM != self.hasUTF8BOM else { return }
        
        // change encoding immediately if there is nothing to worry about
        if self.textStorage.string.isEmpty ||
            self.fileURL == nil ||
            encoding == .utf8 && encoding == self.encoding {
            self.changeEncoding(to: encoding, withUTF8BOM: withUTF8BOM, askLossy: true, lossy: false)
            return
        }
        
        // ask whether just change the encoding or reinterpret docuemnt file
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("File encoding", comment: "")
        alert.informativeText = String(format: NSLocalizedString("Do you want to convert or reinterpret this document using “%@”?", comment: ""), encodingName)
        alert.addButton(withTitle: NSLocalizedString("Convert", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Reinterpret", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
        
        alert.beginSheetModal(for: self.windowForSheet!) { [weak self] (returnCode: NSModalResponse) in
            guard let `self` = self else { return }
            
            switch returnCode {
            case NSAlertFirstButtonReturn:  // = Convert
                self.changeEncoding(to: encoding, withUTF8BOM: withUTF8BOM, askLossy: true, lossy: false)
                
            case NSAlertSecondButtonReturn:  // = Reinterpret
                if self.isDocumentEdited, let fileURL = self.fileURL {
                    let alert = NSAlert()
                    alert.messageText = String(format: NSLocalizedString("The file “%@” has unsaved changes.", comment: ""), fileURL.lastPathComponent)
                    alert.informativeText = NSLocalizedString("Do you want to discard the changes and reset the file encoding?", comment: "")
                    alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
                    alert.addButton(withTitle: NSLocalizedString("Discard Changes", comment: ""))
                    
                    self.windowForSheet!.attachedSheet?.orderOut(self)  // close previous sheet
                    alert.beginSheetModal(for: self.windowForSheet!, completionHandler: { (returnCode: NSModalResponse) in
                        switch returnCode {
                        case NSAlertFirstButtonReturn:  // = Cancel
                            // reset toolbar selection for in case if the operation was invoked from the toolbar popup
                            NotificationCenter.default.post(name: .DocumentDidChangeEncoding, object: self)
                            
                        case NSAlertSecondButtonReturn:  // = Discard Changes
                            try? self.reinterpret(encoding: encoding)
                            
                        default: break
                        }
                    })
                    
                } else {
                    try? self.reinterpret(encoding: encoding)
                    
                }
                
            case NSAlertThirdButtonReturn:  // = Cancel
                // reset toolbar selection for in case if the operation was invoked from the toolbar popup
                NotificationCenter.default.post(name: .DocumentDidChangeEncoding, object: self)
                
            default: break
            }
        }
    }
    
    
    /// change syntax style
    @IBAction func changeSyntaxStyle(_ sender: AnyObject?) {
        
        guard let name = sender?.title, name != self.syntaxStyle.styleName else { return }
        
        self.setSyntaxStyle(name: name)
    }
    
    
    /// insert IANA CharSet name to editor's insertion point
    @IBAction func insertIANACharSetName(_ sender: Any?) {
        
        guard let string = self.encoding.ianaCharSetName else { return }
        
        self.insert(string: string)
    }
    
    
    
    // MARK: Private Methods
    
    /// read String from Dada detecting file encoding automatically
    private func string(data: Data, xattrEncoding: String.Encoding?) throws -> (String, String.Encoding) {
        
        // try interpreting with xattr encoding
        if let xattrEncoding = xattrEncoding {
            // just trust xattr encoding if content is empty
            if let string = data.isEmpty ? "" : String(data: data, encoding: xattrEncoding) {
                return (string, xattrEncoding)
            }
        }
        
        // detect encoding from data
        let encodingList = Defaults[.encodingList].map { return $0.uint32Value }
        var usedEncoding: String.Encoding?
        let string = try String(data: data, suggestedCFEncodings: encodingList, usedEncoding: &usedEncoding)
        
        // try reading encoding declaration and take priority of it if it seems well
        if let scannedEncoding = self.scanEncodingFromDeclaration(content: string), scannedEncoding != usedEncoding {
            if let string = String(data: data, encoding: scannedEncoding) {
                return (string, scannedEncoding)
            }
        }
        
        return (string, usedEncoding!)
    }
    
    
    /// detect file encoding from encoding declaration like "charset=" or "encoding=" in file content
    private func scanEncodingFromDeclaration(content: String) -> String.Encoding? {
        
        guard Defaults[.referToEncodingTag] else { return nil }
        
        let suggestedCFEncodings = Defaults[.encodingList]
        
        return content.scanEncodingDeclaration(forTags: ["charset=", "encoding=", "@charset", "encoding:", "coding:"],
                                               upTo: MaxEncodingScanLength,
                                               suggestedCFEncodings: suggestedCFEncodings.map { return $0.uint32Value })
    }
    
    
    /// check if can save safety with the current encoding and ask if not
    private func askSavingSafety(completionHandler: @escaping (Bool) -> Void) {
        
        let content = self.string
        let encoding = self.encoding
        
        // check encoding declaration in the document and alert if incompatible with saving encoding
        if !self.suppressesIANACharsetConflictAlert {
            do {
                try self.checkSavingSafetyForConverting(content: content, encoding: encoding)
                
            } catch let error {
                // --> ask directly with a non-sheet NSAlert for the suppression button
                let alert = NSAlert(error: error)
                alert.showsSuppressionButton = true
                alert.suppressionButton?.title = NSLocalizedString("Do not show this warning for this document again", comment: "")
                
                let result = alert.runModal()
                // do not show the alert in this document again
                if alert.suppressionButton?.state == NSOnState {
                    self.suppressesIANACharsetConflictAlert = true
                }
                
                switch result {
                case NSAlertFirstButtonReturn:  // == Cancel
                    completionHandler(false)
                    return
                default: break  // == Continue Saving
                }
            }
        }
        
        // check file encoding for conversion and ask user how to solve
        do {
            try self.checkSavingSafetyForConverting(content: content, encoding: encoding)
            
        } catch let error {
            self.recoverBlock = completionHandler
            self.presentError(error,
                              modalFor: self.windowForSheet!,
                              delegate: self,
                              didPresent: #selector(didPresentErrorWithRecovery(didRecover:block:)),
                              contextInfo: nil)
        }
        
        completionHandler(true)
    }
    
    
    /// check compatibility of saving encoding with the encoding decralation in document
    private func checkSavingSafetyWithIANACharSetName(content: String, encoding: String.Encoding) throws {
        
        guard let IANACharSetEncoding = self.scanEncodingFromDeclaration(content: content) else { return }
        
        guard encoding.isCompatible(ianaCharSetEncoding: IANACharSetEncoding) else {
            throw EncodingError(kind: .ianaCharsetNameConflict(ianaEncoding: IANACharSetEncoding), encoding: encoding, withUTF8BOM: false, attempter: self)
        }
    }
    
    
    /// check if the content can be saved with the file encoding
    private func checkSavingSafetyForConverting(content: String, encoding: String.Encoding) throws {
        
        // convert yen if needed
        let newString = content.convertingYenSign(for: encoding)
        
        guard newString.canBeConverted(to: encoding) else {
            throw EncodingError(kind: .unconvertibleCharacters, encoding: encoding, withUTF8BOM: false, attempter: self)
        }
    }
    
    
    /// notify about external file update
    private func notifyExternalFileUpdate() {
        
        // rise a flag
        self.needsShowUpdateAlertWithBecomeKey = true
        
        if NSApp.isActive {
            // display dialog immediately
            self.showUpdatedByExternalProcessAlert()
            
        } else {
            // alert first when application becomes active
            NotificationCenter.default.addObserver(self, selector: #selector(showUpdatedByExternalProcessAlert), name: .NSApplicationDidBecomeActive, object: nil)
            
            // let application icon in Dock jump
            NSApp.requestUserAttention(.informationalRequest)
        }
    }
    
    
    /// display alert about file modification by an external process
    func showUpdatedByExternalProcessAlert() {
    
        NotificationCenter.default.removeObserver(self, name: .NSApplicationDidBecomeActive, object: nil)
        
        guard let fileURL = self.fileURL,
            self.needsShowUpdateAlertWithBecomeKey,
            !self.isExternalUpdateAlertShown  // do nothing if alert is already shown
            else { return }
        
        let messageText: String = {
            if self.isDocumentEdited {
                return "The file has been modified by another application. There are also unsaved changes in CotEditor."
            } else {
                return "The file has been modified by another application."
            }
        }()
        
        let alert = NSAlert()
        alert.messageText = NSLocalizedString(messageText, comment: "")
        alert.informativeText = NSLocalizedString("Do you want to keep CotEditor’s edition or update to the modified edition?", comment: "")
        alert.addButton(withTitle: NSLocalizedString("Keep CotEditor’s Edition", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Update", comment: ""))
        
        // mark the alert as critical in order to interpret other sheets already attached
        if self.windowForSheet?.attachedSheet != nil {
            alert.alertStyle = .critical
        }
        
        self.isExternalUpdateAlertShown = true
        self.windowForSheet?.orderFront(self)
        
        // display alert
        alert.beginSheetModal(for: self.windowForSheet!) { [weak self] (returnCode: NSModalResponse) in
            guard let `self` = self else { return }
            
            if returnCode == NSAlertSecondButtonReturn { // == Revert
                try? self.revert(toContentsOf: fileURL, ofType: self.fileType!)
            }
            
            self.isExternalUpdateAlertShown = false
            self.needsShowUpdateAlertWithBecomeKey = false
        }
    }
    
    
    /// perform didRecoverBlock after recovering presented error
    private var recoverBlock: ((Bool) -> Void)? = nil
    func didPresentErrorWithRecovery(didRecover: Bool, block: UnsafeMutableRawPointer) {
        
        self.recoverBlock?(didRecover)
        self.recoverBlock = nil
    }
    
}



// MARK: - Protocol

extension Document: Editable {
    
    var textView: NSTextView? {
        
        return self.viewController?.focusedTextView
    }
}




// MARK: - Error

private struct EncodingError: LocalizedError, RecoverableError {
    
    enum ErrorKind {
        case ianaCharsetNameConflict(ianaEncoding: String.Encoding)
        case unconvertibleCharacters
        case reinterpretationFailed(fileURL: URL?)  // TODO: not RecoverableError
        case lossyEncodingConversion
    }
    
    let kind: ErrorKind
    let encoding: String.Encoding
    let withUTF8BOM: Bool
    let attempter: Document  // attempter
    
    
    
    var errorDescription: String? {
        
        switch self.kind {
        case .ianaCharsetNameConflict(let ianaEncoding):
            return String(format: NSLocalizedString("The encoding is “%@”, but the IANA charset name in text is “%@”.", comment: ""),
                          self.encodingName, String.localizedName(of: ianaEncoding))
        case .unconvertibleCharacters:
            return String(format: NSLocalizedString("Some characters would have to be changed or deleted in saving as “%@”.", comment: ""), self.encodingName)
        case .reinterpretationFailed:
            return NSLocalizedString("Can not reinterpret.", comment: "")
        case .lossyEncodingConversion:
            return String(format: NSLocalizedString("Some characters would have to be changed or deleted in saving as “%@”.", comment: ""), self.encodingName)
        }
    }
    
    
    var recoverySuggestion: String? {
        
        switch self.kind {
        case .ianaCharsetNameConflict:
            return NSLocalizedString("Do you want to continue processing?", comment: "")
            
        case .unconvertibleCharacters:
            return NSLocalizedString("Do you want to continue processing?", comment: "")
            
        case .reinterpretationFailed(let fileURL):
            guard let fileURL = fileURL else {
                return NSLocalizedString("The document doesn’t have a file to reinterpret.", comment: "")
            }
            return String(format: NSLocalizedString("The file “%@” could not be reinterpreted using the new encoding “%@”.", comment: ""), fileURL.lastPathComponent, self.encodingName)
            
        case .lossyEncodingConversion:
            return NSLocalizedString("Do you want to change encoding and show incompatible characters?", comment: "'")
        }
    }
    
    
    var recoveryOptions: [String] {
        
        switch self.kind {
        case .ianaCharsetNameConflict:
            return [NSLocalizedString("Cancel", comment: ""),
                    NSLocalizedString("Continue Saving", comment: "")]
            
        case .unconvertibleCharacters:
            return [NSLocalizedString("Show Incompatible Chars", comment: ""),
                    NSLocalizedString("Save Available Strings", comment: ""),
                    NSLocalizedString("Cancel", comment: "")]
            
        case .reinterpretationFailed:
            return []
            
        case .lossyEncodingConversion:
            return [NSLocalizedString("Cancel", comment: ""),
                    NSLocalizedString("Change Encoding", comment: "")]
        }
    }
    
    
    func attemptRecovery(optionIndex recoveryOptionIndex: Int) -> Bool {
        
        let document = self.attempter
        let windowContentController = document.windowControllers.first?.contentViewController as? WindowContentViewController
        
        switch self.kind {
        case .ianaCharsetNameConflict:
            switch recoveryOptionIndex {
            case 0:  // == Cancel
                return false
            case 1:  // == Continue Saving
                return true
            default:
                return false
            }
        case .unconvertibleCharacters:
            switch recoveryOptionIndex {
            case 0:  // == Show Incompatible Chars
                windowContentController?.showSidebarPane(index: .incompatibleCharacters)
                return false
            case 1:  // == Save
                return true
            case 2:  // == Cancel
                return false
            default:
                return false
            }
            
        case .reinterpretationFailed:
            return false
            
        case .lossyEncodingConversion:
            switch recoveryOptionIndex {
            case 0:  // == Cancel
                // reset to force reverting toolbar selection
                NotificationCenter.default.post(name: .DocumentDidChangeEncoding, object: document)
                return false
            case 1:  // == Change Encoding
                document.changeEncoding(to: self.encoding, withUTF8BOM: self.withUTF8BOM, askLossy: false, lossy: true)
                (document.undoManager?.prepare(withInvocationTarget: windowContentController) as? WindowContentViewController)?.showSidebarPane(index: .incompatibleCharacters)
                windowContentController?.showSidebarPane(index: .incompatibleCharacters)
                return true
            default:
                return false
            }
        }
    }
    
    
    private var encodingName: String {
        
        return String.localizedName(of: self.encoding, withUTF8BOM: self.withUTF8BOM)
    }
    
}
