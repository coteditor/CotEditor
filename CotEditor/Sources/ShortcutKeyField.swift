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
//  © 2014-2018 1024jp
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

final class ShortcutKeyField: NSTextField {
    
    // MARK: Private Properties
    
    private var keyDownMonitor: Any?
    
    
    
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
        
        self.keyDownMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [unowned self] (event: NSEvent) -> NSEvent? in
            guard
                var charsIgnoringModifiers = event.charactersIgnoringModifiers,
                let char = charsIgnoringModifiers.unicodeScalars.first
                else { return event }
            
            // correct Backspace and Delete keys
            //  -> "backspace" key:        the key above "return"
            //     "delete (forword)" key: the key with printed "Delete" where next to the ten key pad.
            switch Int(char.value) {
                case NSDeleteCharacter:
                    charsIgnoringModifiers = String(Unicode.Scalar(NSBackspaceCharacter)!)
                case NSDeleteFunctionKey:
                    charsIgnoringModifiers = String(Unicode.Scalar(NSDeleteCharacter)!)
                default: break
            }
            
            // remove unwanted Shift
            let ignoringShiftSet = CharacterSet(charactersIn: "`~!@#$%^&()_{}|\":<>?=/*-+.'")
            let ignoringMask: NSEvent.ModifierFlags = ignoringShiftSet.contains(char) ? .shift : []
            let modifierMask = event.modifierFlags.subtracting(ignoringMask)
            
            // set input shortcut string to field
            // -> The single NSDeleteCharacter works as delete.
            let keySpecChars = Shortcut(modifierMask: modifierMask, keyEquivalent: charsIgnoringModifiers).keySpecChars
            self.objectValue = (keySpecChars == "\u{8}") ? nil : keySpecChars
            
            // end editing
            self.window?.endEditing(for: nil)
            
            return nil
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
        
        super.textDidEndEditing(notification)
    }
    
}
