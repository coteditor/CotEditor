//
//  UnicodeInputViewController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2014-05-06.
//
//  ---------------------------------------------------------------------------
//
//  © 2014-2020 1024jp
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

import Cocoa

@objc protocol UnicodeInputReceiver: AnyObject {
    
    func insertUnicodeCharacter(_ sender: UnicodeInputViewController)
}



// MARK: -

final class UnicodeInputViewController: NSViewController, NSTextFieldDelegate {
    
    // MARK: Public Properties
    
    static let sharedPanel = NSWindowController.instantiate(storyboard: "UnicodePanel")
    
    @objc private(set) dynamic var characterString: String?
    
    
    // MARK: Private Properties
    
    private var windowObserver: NSObjectProtocol?
    
    @objc private dynamic var codePoint: String?
    @objc private dynamic var isValid = false
    @objc private dynamic var unicodeName: String?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    deinit {
        if let observer = self.windowObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.windowObserver = NotificationCenter.default.addObserver(forName: NSWindow.didResignMainNotification, object: nil, queue: .main) { [unowned self] _ in
            guard
                NSApp.isActive,
                NSDocumentController.shared.documents.count <= 1  // The 1 is the document now resigning.
                else { return }
            
            self.view.window?.performClose(self)
        }
    }
    
    
    
    // MARK: Delegate
    
    /// text in text field was changed
    func controlTextDidChange(_ obj: Notification) {
        
        self.isValid = false
        self.unicodeName = nil
        self.characterString = nil
        
        guard
            let input = (obj.object as? NSTextField)?.stringValue,
            let longChar = UInt32(codePoint: input)
            else { return }
        
        self.unicodeName = longChar.unicodeName
        
        guard let scalar = UnicodeScalar(longChar) else { return }
        
        self.isValid = true
        
        // -> Workaround that Swift 5 omits U+FEFF at the beginning. (2019-06 macOS 10.14)
        self.characterString = (scalar == UnicodeScalar("\u{feff}")) ? "\u{feff}\u{feff}" : String(scalar)
    }
    
    
    
    // MARK: Action Message
    
    /// input unicode character to the frontmost document
    @IBAction func insertToDocument(_ sender: Any?) {
        
        guard self.characterString?.isEmpty == false else { return }
        
        guard let receiver = NSApp.target(forAction: #selector(UnicodeInputReceiver.insertUnicodeCharacter)) as? UnicodeInputReceiver else {
            NSSound.beep()
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
        let hexString = codePoint[range]
        
        self.init(hexString, radix: 16)
    }
    
}
