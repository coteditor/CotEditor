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
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Cocoa

class DocumentController: NSDocumentController {

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
        
        // [caution] This method can be called before the UserDefaults is initialized.
        
        self._accessorySelectedEncoding = UInt(UserDefaults.standard.integer(forKey: DefaultKey.encodingInOpen.rawValue))
        self.autosaveDirectoryURL = try! FileManager.default.urlForDirectory(.autosavedInformationDirectory,
                                                                             in: .userDomainMask,
                                                                             appropriateFor: nil,
                                                                             create: true)
        
        super.init()
        
        self.autosavingDelay = TimeInterval(UserDefaults.standard.double(forKey: DefaultKey.autosavingDelay.rawValue))
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    // MARK: Document Controller Methods
    
    /// check file before creating a new document instance
    override func makeDocument(withContentsOf url: URL, ofType typeName: String) throws -> NSDocument {
        
        // [caution] This method may be called from a background thread due to concurrent-opening.
        
        var error: NSError?
        
        if UTTypeConformsTo(typeName, kUTTypeImage) && !UTTypeEqual(typeName, kUTTypeScalableVectorGraphics) ||   // SVG is plain-text (except SVGZ)
            UTTypeConformsTo(typeName, kUTTypeAudiovisualContent) ||
            UTTypeConformsTo(typeName, kUTTypeGNUZipArchive) ||
            UTTypeConformsTo(typeName, kUTTypeZipArchive) ||
            UTTypeConformsTo(typeName, kUTTypeBzip2Archive)
        {
            let localizedTypeName = (UTTypeCopyDescription(typeName as CFString)?.takeRetainedValue() as String?) ?? "unknown file type"
            
            print(UTTypeCopyDescription(typeName as CFString)?.takeRetainedValue())
            
            error = NSError(domain: CotEditorError.domain, code: CotEditorError.fileReadBinaryFile.rawValue,
                            userInfo: [NSLocalizedDescriptionKey: String(format: NSLocalizedString("The file “%@” doesn’t appear to be text data.", comment: ""), url.lastPathComponent!),
                                       NSLocalizedRecoverySuggestionErrorKey: String(format: NSLocalizedString("The file is %@.\n\nDo you really want to open the file?", comment: ""), localizedTypeName),
                                       NSLocalizedRecoveryOptionsErrorKey: [NSLocalizedString("Open", comment: ""),
                                                                            NSLocalizedString("Cancel", comment: "")],
                                       NSRecoveryAttempterErrorKey: self,
                                       NSURLErrorKey: url,
                                       NSUnderlyingErrorKey: NSError(domain: NSCocoaErrorDomain, code: NSFileReadCorruptFileError, userInfo: nil)])
        }
        
        // display alert if file is enorm large
        let fileSizeThreshold = UserDefaults.standard.integer(forKey: DefaultKey.largeFileAlertThreshold.rawValue)
        if fileSizeThreshold > 0,
            let fileSize = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize,
            fileSize > fileSizeThreshold
        {
            let formatter = ByteCountFormatter()
            
            error = NSError(domain: CotEditorError.domain, code: CotEditorError.fileReadTooLarge.rawValue,
                            userInfo: [NSLocalizedDescriptionKey: String(format: NSLocalizedString("The file “%@” has a size of %@.", comment: ""),
                                                                         url.lastPathComponent!,
                                                                         formatter.stringFromByteCount(Int64(fileSize))),
                                       NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString("Opening such a large file can make the application slow or unresponsive.\n\nDo you really want to open the file?", comment: ""),
                                       NSLocalizedRecoveryOptionsErrorKey: [NSLocalizedString("Open", comment: ""),
                                                                            NSLocalizedString("Cancel", comment: "")],
                                       NSRecoveryAttempterErrorKey: self,
                                       NSURLErrorKey: url,
                                       NSUnderlyingErrorKey: NSError(domain: NSCocoaErrorDomain, code: NSFileReadTooLargeError, userInfo: nil)])
        }
        
        // ask user for opening file
        if let error = error {
            var wantsOpen = false
            if Thread.isMainThread {
                wantsOpen = self.presentError(error)
            } else {
                DispatchQueue.main.sync { [unowned self] in
                    wantsOpen = self.presentError(error)
                }
            }
            
            // cancel operation
            guard wantsOpen else {
                throw NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError, userInfo:nil)
            }
        }
        
        // let super make document
        let document = try super.makeDocument(withContentsOf: url, ofType: typeName)
        
        // reset encoding menu
        self.resetAccessorySelectedEncoding()
        
        return document
    }
    
    
    /// add encoding menu to open panel
    override func beginOpenPanel(_ openPanel: NSOpenPanel, forTypes inTypes: [String]?, completionHandler: (Int) -> Void) {
        
        // initialize encoding menu and set the accessory view
        if self.openPanelAccessoryView == nil {
            Bundle.main.loadNibNamed("OpenDocumentAccessory", owner: self, topLevelObjects: nil)
            if #available(OSX 10.11, *) { } else {
                // real time togging of hidden files visibility works only on El Capitan (and later?)
                self.showHiddenFilesCheckbox?.removeFromSuperview()
            }
        }
        self.buildEncodingPopupButton()
        openPanel.accessoryView = self.openPanelAccessoryView
        
        // force accessory view visible
        if #available(OSX 10.11, *) {
            openPanel.isAccessoryViewDisclosed = true
        }
        
        // set visibility of hidden files in the panel
        openPanel.showsHiddenFiles = self.showsHiddenFiles
        openPanel.treatsFilePackagesAsDirectories = self.showsHiddenFiles
        // ->  bind showsHiddenFiles flag with openPanel (for El capitan and leter)
        openPanel.bind(#keyPath(showsHiddenFiles), to: self, withKeyPath: #keyPath(showsHiddenFiles), options: nil)
        openPanel.bind(#keyPath(NSOpenPanel.treatsFilePackagesAsDirectories), to: self, withKeyPath: #keyPath(showsHiddenFiles), options: nil)
        
        // run non-modal open panel
        super.beginOpenPanel(openPanel, forTypes: inTypes) { [weak self] (result: Int) in
            
            // reset encoding menu if cancelled
            if result == NSModalResponseCancel {
                self?.resetAccessorySelectedEncoding()
            }
            
            self?.showsHiddenFiles = false  // reset flag
            
            completionHandler(result)
        }
    }
    
    
    /// check if file opening is cancelled
    override func attemptRecovery(fromError error: NSError, optionIndex recoveryOptionIndex: Int) -> Bool {
        
        if error.domain == CotEditorError.domain, let code = CotEditorError(rawValue: error.code) {
            switch code {
            case .fileReadBinaryFile, .fileReadTooLarge:
                return (recoveryOptionIndex == 0)
            default: break
            }
        }
        
        return false
    }
    
    
    
    // MARK: Public Methods
    
    /// String.Encoding accessor for encodnig user selected in open panel
    var accessorySelectedEncoding: String.Encoding {
        get {
            return String.Encoding(rawValue: self._accessorySelectedEncoding)
        }
        set (encoding) {
            self._accessorySelectedEncoding = encoding.rawValue
        }
    }
    
    
    
    // MARK: Action Messages
    
    /// reset selection of the encoding menu
    @IBAction func openHiddenDocument(_ sender: AnyObject?) {
        
        self.showsHiddenFiles = true
        
        self.openDocument(sender)
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
        
        let items = EncodingManager.shared.encodingMenuItems
        for item in items {
            menu.addItem(item)
        }
        
        self.resetAccessorySelectedEncoding()
    }
    
    
    /// reset selection of the encoding menu
    private func resetAccessorySelectedEncoding() {
        
        let defaultEncoding = String.Encoding(rawValue: UInt(UserDefaults.standard.integer(forKey: DefaultKey.encodingInOpen.rawValue)))
        
        DispatchQueue.main.async { [weak self] in
            self?.accessorySelectedEncoding = defaultEncoding
        }
    }
    
}
