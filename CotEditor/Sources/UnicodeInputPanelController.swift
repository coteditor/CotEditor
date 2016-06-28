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
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Cocoa

@objc protocol UnicodeInputReceiver  {
    
    func insertUnicodeCharacter(_ sender: UnicodeInputPanelController)
}



// MARK:

class UnicodeInputPanelController: NSWindowController, NSTextFieldDelegate {
    
    // MARK: Public Properties
    
    static let shared = UnicodeInputPanelController()
    
    dynamic var characterString: String? {
        
        return self.character?.string
    }
    
    
    // MARK: Private Properties
    
    private dynamic var unicode = ""
    private dynamic var isValid = false
    
    private dynamic var character: CEUnicodeCharacter?
    
    private let unicodeRegex = try! RegularExpression(pattern: "^(?:U\\+|0x|\\\\u)?([0-9a-f]{1,5})$", options: .caseInsensitive)
    
    
    
    // MARK:
    // MARK: Lifecycle
    
    deinit {
        NotificationCenter.default().removeObserver(self)
    }
    
    
    override var windowNibName: String? {
        
        return "UnicodePanel"
    }
    
    
    
    // MARK: Window Controller Methods
    
    override func windowDidLoad() {
        
        super.windowDidLoad()
        
        NotificationCenter.default().addObserver(self, selector: #selector(mainWindowDidResign(_:)), name: .NSWindowDidResignMain, object: nil)
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
        
        guard let input = (obj.object as? NSTextField)?.stringValue else { return }
        
        let result = self.unicodeRegex.firstMatch(in: input, options: [], range: NSRange(location: 0, length: input.utf16.count))
        
        self.isValid = (result != nil)
        self.character = self.isValid ? CEUnicodeCharacter(character: self.longChar) : nil
    }
    
    
    
    // MARK: Action Message
    
    /// input unicode character to the frontmost document
    @IBAction func insertToDocument(_ sender: AnyObject?) {
        
        guard self.characterString?.isEmpty ?? false else { return }
        
        guard let receiver = NSApp.target(forAction: #selector(UnicodeInputReceiver.insertUnicodeCharacter(_:))) as? UnicodeInputReceiver else {
            NSBeep()
            return
        }
        
        receiver.insertUnicodeCharacter(self)
        
        self.unicode = ""
        self.character = nil
        self.isValid = false
    }
    
    
    
    // MARK: Private Methods
    
    /// UTF32Char form of current input unicode codepoint
    private var longChar: UTF32Char {
        
        let scanner = Scanner(string: self.unicode)
        scanner.charactersToBeSkipped = CharacterSet(charactersIn: "uU+\\")
        
        var longChar: UTF32Char = 0
        scanner.scanHexInt32(&longChar)
        
        return longChar
    }
    
}
