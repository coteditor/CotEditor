/*
 
 UnicodeInputPanelController.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2014-05-06.
 
 ------------------------------------------------------------------------------
 
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

@objc protocol UnicodeInputReceiver: class {
    
    func insertUnicodeCharacter(_ sender: UnicodeInputPanelController)
}



// MARK:

final class UnicodeInputPanelController: NSWindowController, NSTextFieldDelegate {
    
    // MARK: Public Properties
    
    static let shared = UnicodeInputPanelController()
    
    private(set) dynamic var characterString: String?
    
    
    // MARK: Private Properties
    
    private dynamic var codePoint: String?
    private dynamic var isValid = false
    private dynamic var unicodeName: String?
    
    
    
    // MARK:
    // MARK: Lifecycle
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    override var windowNibName: String? {
        
        return "UnicodePanel"
    }
    
    
    
    // MARK: Window Controller Methods
    
    override func windowDidLoad() {
        
        super.windowDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(mainWindowDidResign(_:)), name: .NSWindowDidResignMain, object: nil)
    }
    
    
    
    // MARK: Notification
    
    /// notification about main window resign
    func mainWindowDidResign(_ notification: Notification) {
        
        guard NSApp.isActive else { return }
        
        if NSDocumentController.shared().documents.count <= 1 {  // The 1 is the document now resigning.
            self.window?.performClose(self)
        }
    }
    
    
    
    // MARK: Delegate
    
    /// text in text field was changed
    override func controlTextDidChange(_ obj: Notification) {
        
        var isValid = false
        var unicodeName: String? = nil
        var characterString: String? = nil
        
        defer {
            self.isValid = isValid
            self.unicodeName = unicodeName
            self.characterString = characterString
        }
        
        guard
            let input = (obj.object as? NSTextField)?.stringValue,
            let longChar = UInt32(codePoint: input) else { return }
        
        unicodeName = longChar.unicodeName
        
        guard let scalar = UnicodeScalar(longChar) else { return }
        
        isValid = true
        characterString = String(Character(scalar))
    }
    
    
    
    // MARK: Action Message
    
    /// input unicode character to the frontmost document
    @IBAction func insertToDocument(_ sender: Any?) {
        
        guard !(self.characterString?.isEmpty ?? true) else { return }
        
        guard let receiver = NSApp.target(forAction: #selector(UnicodeInputReceiver.insertUnicodeCharacter(_:))) as? UnicodeInputReceiver else {
            NSBeep()
            return
        }
        
        receiver.insertUnicodeCharacter(self)
        
        self.codePoint = ""
        self.isValid = false
        self.unicodeName = nil
        self.characterString = nil
    }
    
}



// MARK: Private Methods

private extension UInt32 {
    
    /// initialize from a possible Unicode code point representation like `U+1F600`, `1f600`, `0x1F600` and so on.
    init?(codePoint: String) {
        
        guard let range = codePoint.range(of: "(?<=^(U\\+|0x|\\\\u)?)[0-9a-f]{1,5}$",
                                          options: [.regularExpression, .caseInsensitive]) else { return nil }
        let hexString = codePoint.substring(with: range)
        
        self.init(hexString, radix: 16)
    }
    
}
