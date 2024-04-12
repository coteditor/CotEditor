//
//  ShortcutField.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2014-12-16.
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

import AppKit
import Combine

final class ShortcutField: NSTextField, NSTextViewDelegate {
    
    // MARK: Private Properties
    
    private var keyDownMonitor: Any?
    private var windowObserver: AnyCancellable?
    
    
    
    // MARK: Text Field Methods
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        // fix the alignment to right regardless the UI layout direction
        self.alignment = .right
        self.baseWritingDirection = .leftToRight
    }
    
    
    /// Text field turns into edit mode.
    override func becomeFirstResponder() -> Bool {
        
        guard super.becomeFirstResponder() else { return false }
        
        if let fieldEditor = self.currentEditor() as? NSTextView {
            // hide insertion point
            fieldEditor.insertionPointColor = .clear
            fieldEditor.delegate = self
        }
        
        self.keyDownMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [unowned self] event -> NSEvent? in
            guard let shortcut = Shortcut(keyDownEvent: event) else { return event }
            
            if event.keyCode == 53, shortcut.modifiers.isEmpty {  // single Escape
                // treat as cancel
            } else if event.specialKey == .delete, shortcut.modifiers.isEmpty {  // single Delete
                // treat as delete
                self.objectValue = nil
            } else {
                self.objectValue = shortcut
            }
            
            self.window?.makeFirstResponder(nil)
            
            return nil
        }
        
        if let window = self.window {
            self.windowObserver = NotificationCenter.default.publisher(for: NSWindow.didResignKeyNotification, object: window)
                .map { $0.object as! NSWindow }
                .sink { $0.makeFirstResponder(nil) }
        }
        
        return true
    }
    
    
    /// Invoked when the editing ends.
    override func textDidEndEditing(_ notification: Notification) {
        
        // restore field editor
        if let fieldEditor = self.currentEditor() as? NSTextView {
            fieldEditor.insertionPointColor = .controlTextColor
            fieldEditor.delegate = nil
        }
        
        // end monitoring key down event
        self.removeKeyMonitor()
        self.windowObserver = nil
        
        super.textDidEndEditing(notification)
    }
    
    
    
    // MARK: Text View Delegate
    
    func textView(_ view: NSTextView, menu: NSMenu, for event: NSEvent, at charIndex: Int) -> NSMenu? {
        
        // disable contextual menu for field editor
        nil
    }
    
    
    // MARK: Private Methods
    
    /// Stops and removes the key down monitoring.
    private func removeKeyMonitor() {
        
        if let monitor = self.keyDownMonitor {
            NSEvent.removeMonitor(monitor)
            self.keyDownMonitor = nil
        }
    }
}
