/*
 
 DocumentController.swift
 
 CotEditor
 https://coteditor.com
 
 Created by nakamuxu on 2004-12-14.
 
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014-2016 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 https://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Cocoa

protocol AdditionalDocumentPreparing: class {
    
    func didMakeDocumentForExisitingFile(url: URL)
    func registerDocumnentOpenEvent(_ event: NSAppleEventDescriptor)
}


final class DocumentController: NSDocumentController {

    let autosaveDirectoryURL: URL
    
    // MARK: Private Properties
    
    private dynamic var showsHiddenFiles = false  // binding
    
    @IBOutlet private var openPanelAccessoryView: NSView?
    @IBOutlet private weak var accessoryEncodingMenu: NSPopUpButton?
    @IBOutlet private weak var showHiddenFilesCheckbox: NSButton?
    
    private dynamic var _accessorySelectedEncoding: UInt
    
    
    
    // MARK:
    // MARK: Lifecycle
    
    override init() {
        
        self._accessorySelectedEncoding = Defaults[.encodingInOpen]
        self.autosaveDirectoryURL = try! FileManager.default.url(for: .autosavedInformationDirectory,
                                                                 in: .userDomainMask,
                                                                 appropriateFor: nil,
                                                                 create: true)
        
        super.init()
        
        self.autosavingDelay = Defaults[.autosavingDelay]
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    // MARK: Document Controller Methods
    
    /// listen document open event of the ODB editor protocol
    override func openDocument(withContentsOf url: URL, display displayDocument: Bool, completionHandler: @escaping (NSDocument?, Bool, Error?) -> Void) {
        
        // -> Need to fetch AppleEvent at this moment.
        let openEvent = NSAppleEventManager.shared().currentAppleEvent
        
        super.openDocument(withContentsOf: url, display: displayDocument) { (document, documentWasAlreadyOpen, error) in
            if let openEvent = openEvent {
                (document as? AdditionalDocumentPreparing)?.registerDocumnentOpenEvent(openEvent)
            }
            
            completionHandler(document, documentWasAlreadyOpen, error)
        }
    }
    
    
    /// check file before creating a new document instance
    override func makeDocument(withContentsOf url: URL, ofType typeName: String) throws -> NSDocument {
        
        // [caution] This method may be called from a background thread due to concurrent-opening.
        
        let error: DocumentReadError? = {
            let cfTypeName = typeName as CFString
            if UTTypeConformsTo(cfTypeName, kUTTypeImage) && !UTTypeEqual(cfTypeName, kUTTypeScalableVectorGraphics) ||   // SVG is plain-text (except SVGZ)
                UTTypeConformsTo(cfTypeName, kUTTypeAudiovisualContent) ||
                UTTypeConformsTo(cfTypeName, kUTTypeGNUZipArchive) ||
                UTTypeConformsTo(cfTypeName, kUTTypeZipArchive) ||
                UTTypeConformsTo(cfTypeName, kUTTypeBzip2Archive)
            {
                return DocumentReadError(kind: .binaryFile(type: typeName), url: url)
            }
            
            // display alert if file is enorm large
            let fileSizeThreshold = Defaults[.largeFileAlertThreshold]
            if fileSizeThreshold > 0,
                let fileSize = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize,
                fileSize > fileSizeThreshold
            {
                return DocumentReadError(kind: .tooLarge(size: fileSize), url: url)
            }
            
            return nil
        }()
        
        // ask user for opening file
        if let error = error {
            try DispatchQueue.syncOnMain {
                let wantsOpen = self.presentError(error)
                
                guard wantsOpen else { throw CocoaError(.userCancelled) }
            }
        }
        
        // make document
        let document = try super.makeDocument(withContentsOf: url, ofType: typeName)
        
        if let delegate = document as? AdditionalDocumentPreparing {
            delegate.didMakeDocumentForExisitingFile(url: url)
        }
        
        // reset encoding menu
        self.resetAccessorySelectedEncoding()
        
        return document
    }
    
    
    /// add encoding menu to open panel
    override func beginOpenPanel(_ openPanel: NSOpenPanel, forTypes inTypes: [String]?, completionHandler: @escaping (Int) -> Void) {
        
        // initialize encoding menu and set the accessory view
        if self.openPanelAccessoryView == nil {
            Bundle.main.loadNibNamed("OpenDocumentAccessory", owner: self, topLevelObjects: nil)
            if #available(macOS 10.11, *) { } else {
                // real time togging of hidden files visibility works only on El Capitan (and later?)
                self.showHiddenFilesCheckbox?.removeFromSuperview()
            }
        }
        self.buildEncodingPopupButton()
        openPanel.accessoryView = self.openPanelAccessoryView
        
        // force accessory view visible
        if #available(macOS 10.11, *) {
            openPanel.isAccessoryViewDisclosed = true
        }
        
        // set visibility of hidden files in the panel
        openPanel.showsHiddenFiles = self.showsHiddenFiles
        openPanel.treatsFilePackagesAsDirectories = self.showsHiddenFiles
        // ->  bind showsHiddenFiles flag with openPanel (for El capitan and leter)
        openPanel.bind(#keyPath(NSOpenPanel.showsHiddenFiles), to: self, withKeyPath: #keyPath(showsHiddenFiles))
        openPanel.bind(#keyPath(NSOpenPanel.treatsFilePackagesAsDirectories), to: self, withKeyPath: #keyPath(showsHiddenFiles))
        
        // run non-modal open panel
        super.beginOpenPanel(openPanel, forTypes: inTypes) { [weak self] (result: Int) in
            
            // reset encoding menu if cancelled
            if result == NSModalResponseCancel {
                self?.resetAccessorySelectedEncoding()
            }
            
            self?.showsHiddenFiles = false  // reset flag
            
            openPanel.unbind(#keyPath(NSOpenPanel.showsHiddenFiles))
            openPanel.unbind(#keyPath(NSOpenPanel.treatsFilePackagesAsDirectories))
            
            completionHandler(result)
        }
    }
    
    
    /// return enability of actions
    override func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        
        guard let action = item.action else { return false }
        
        if #available(macOS 10.12, *) {
            if action == #selector(newDocumentAsTab) {
                return self.currentDocument != nil
            }
        }
        
        return super.validateUserInterfaceItem(item)
    }
    
    
    
    // MARK: Public Methods
    
    /// String.Encoding accessor for encoding user selected in open panel
    var accessorySelectedEncoding: String.Encoding {
        
        get {
            return String.Encoding(rawValue: self._accessorySelectedEncoding)
        }
        set {
            self._accessorySelectedEncoding = newValue.rawValue
        }
    }
    
    
    
    // MARK: Action Messages
    
    /// reset selection of the encoding menu
    @IBAction func openHiddenDocument(_ sender: Any?) {
        
        self.showsHiddenFiles = true
        
        self.openDocument(sender)
    }
    
    
    /// open a new document as new window
    @available(macOS 10.12, *)
    @IBAction func newDocumentAsWindow(_ sender: Any?) {
        
        let document: NSDocument
        do {
            document = try self.openUntitledDocumentAndDisplay(false)
        } catch let error {
            self.presentError(error)
            return
        }
        
        AlphaWindow.tabbingPreference = .manual
        document.makeWindowControllers()
        document.showWindows()
        AlphaWindow.tabbingPreference = nil
    }
    
    
    /// open a new document as tab in the existing frontmost window
    @available(macOS 10.12, *)
    @IBAction func newDocumentAsTab(_ sender: Any?) {
        
        let document: NSDocument
        do {
            document = try self.openUntitledDocumentAndDisplay(false)
        } catch let error {
            self.presentError(error)
            return
        }
        
        document.makeWindowControllers()
        document.windowControllers.first?.window?.tabbingMode = .preferred
        document.showWindows()
    }
    
    
    // MARK: Private Methods
    
    /// update encoding menu in the open panel
    private func buildEncodingPopupButton() {
        
        let menu = self.accessoryEncodingMenu!.menu!
        
        menu.removeAllItems()
        
        let autoDetectItem = NSMenuItem(title: NSLocalizedString("Auto-Detect", comment: ""), action: nil, keyEquivalent: "")
        autoDetectItem.tag = Int(String.Encoding.autoDetection.rawValue)
        menu.addItem(autoDetectItem)
        menu.addItem(NSMenuItem.separator())
        
        let items = EncodingManager.shared.createEncodingMenuItems()
        for item in items {
            menu.addItem(item)
        }
        
        self.resetAccessorySelectedEncoding()
    }
    
    
    /// reset selection of the encoding menu
    private func resetAccessorySelectedEncoding() {
        
        let defaultEncoding = String.Encoding(rawValue: Defaults[.encodingInOpen])
        
        DispatchQueue.main.async { [weak self] in
            self?.accessorySelectedEncoding = defaultEncoding
        }
    }
    
}



// MARK: - Error

private struct DocumentReadError: LocalizedError, RecoverableError {
    
    enum ErrorKind {
        case binaryFile(type: String)
        case tooLarge(size: Int)
    }
    
    let kind: ErrorKind
    let url: URL
    
    
    var errorDescription: String? {
        
        switch self.kind {
        case .binaryFile:
            return String(format: NSLocalizedString("The file “%@” doesn’t appear to be text data.", comment: ""), self.url.lastPathComponent)
            
        case .tooLarge(let size):
            return String(format: NSLocalizedString("The file “%@” has a size of %@.", comment: ""),
                          self.url.lastPathComponent,
                          ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file))
        }
    }
    
    
    var recoverySuggestion: String? {
        
        switch self.kind {
        case .binaryFile(let type):
            let localizedTypeName = (UTTypeCopyDescription(type as CFString)?.takeRetainedValue() as String?) ?? "unknown file type"
            return String(format: NSLocalizedString("The file is %@.\n\nDo you really want to open the file?", comment: ""), localizedTypeName)
            
        case .tooLarge:
            return NSLocalizedString("Opening such a large file can make the application slow or unresponsive.\n\nDo you really want to open the file?", comment: "")
        }
    }
    
    
    var recoveryOptions: [String] {
        
        return [NSLocalizedString("Open", comment: ""),
                NSLocalizedString("Cancel", comment: "")]
    }
    
    
    func attemptRecovery(optionIndex recoveryOptionIndex: Int) -> Bool {
        
        return (recoveryOptionIndex == 0)
    }
    
}
