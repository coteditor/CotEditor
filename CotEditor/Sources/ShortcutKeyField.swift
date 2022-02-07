//
//  ShortcutKeyField.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2014-12-16.
//
//  ---------------------------------------------------------------------------
//
//  © 2004-2007 nakamuxu
//  © 2014-2022 1024jp
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
import Combine

final class ShortcutKeyField: NSTextField {
    
    // MARK: Private Properties
    
    private var keyDownMonitor: Any?
    private var windowObserver: AnyCancellable?
    
    
    
    // MARK: -
    // MARK: Text Field Methods
    
    deinit {
        if let monitor = self.keyDownMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
    
    
    /// text field turns into edit mode
    override func becomeFirstResponder() -> Bool {
        
        guard super.becomeFirstResponder() else { return false }
        
        // hide insertion point
        (self.currentEditor() as? NSTextView)?.insertionPointColor = .clear
        
        self.keyDownMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [unowned self] (event) -> NSEvent? in
            
            guard let charactersIgnoringModifiers = event.charactersIgnoringModifiers else { return event }
            
            // correct Backspace and Forward Delete keys
            //  -> Backspace:      The key above the Return.
            //     Forward Delete: The key with printed "Delete" where next to the ten key pad.
            // cf. https://developer.apple.com/documentation/appkit/nsmenuitem/1514842-keyequivalent
            let keyEquivalent: String
            switch event.specialKey {
                case NSEvent.SpecialKey.delete:
                    keyEquivalent = String(NSEvent.SpecialKey.backspace.unicodeScalar)
                case NSEvent.SpecialKey.deleteForward:
                    keyEquivalent = String(NSEvent.SpecialKey.delete.unicodeScalar)
                default:
                    keyEquivalent = charactersIgnoringModifiers
            }
            
            // remove unwanted Shift
            let ignoresShift = "`~!@#$%^&()_{}|\":<>?=/*-+.'".contains(keyEquivalent)
            let modifierMask = event.modifierFlags
                .intersection([.control, .option, .shift, .command])
                .subtracting(ignoresShift ? .shift : [])
            
            // set input shortcut string to field
            // -> The single .delete works as delete.
            self.objectValue = (event.specialKey == .delete && modifierMask.isEmpty)
                ? nil
                : Shortcut(modifierMask: modifierMask, keyEquivalent: keyEquivalent).keySpecChars
            
            // end editing
            self.window?.endEditing(for: nil)
            
            return nil
        }
        
        if let window = self.window {
            self.windowObserver = NotificationCenter.default.publisher(for: NSWindow.didResignKeyNotification, object: window)
                .sink { [unowned self] _ in window.endEditing(for: self) }
        }
        
        return true
    }
    
    
    /// end editing
    override func textDidEndEditing(_ notification: Notification) {
        
        // restore insertion point
        (self.currentEditor() as? NSTextView)?.insertionPointColor = .controlTextColor
        
        // end monitoring key down event
        if let monitor = self.keyDownMonitor {
            NSEvent.removeMonitor(monitor)
            self.keyDownMonitor = nil
        }
        
        self.windowObserver = nil
        
        super.textDidEndEditing(notification)
    }
    
}
