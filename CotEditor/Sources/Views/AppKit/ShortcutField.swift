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
//  © 2014-2025 1024jp
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

import SwiftUI
import AppKit
import Shortcut

struct ShortcutField: NSViewRepresentable {
    
    typealias NSViewType = NSTextField
    
    @Binding var value: Shortcut?
    @Binding var error: (any Error)?
    
    
    func makeNSView(context: Context) -> NSTextField {
        
        let nsView = ShortcutTextField()
        nsView.cell?.sendsActionOnEndEditing = true
        nsView.delegate = context.coordinator
        nsView.formatter = ShortcutFormatter()
        nsView.isEditable = true
        nsView.isBordered = false
        nsView.drawsBackground = false
        
        // fix the alignment to right regardless the UI layout direction
        nsView.alignment = .right
        nsView.baseWritingDirection = .leftToRight
        
        return nsView
    }
    
    
    func updateNSView(_ nsView: NSTextField, context: Context) {
        
        nsView.objectValue = self.value
    }
    
    
    func makeCoordinator() -> Coordinator {
        
        Coordinator(shortcut: $value, error: $error)
    }
    
    
    @MainActor final class Coordinator: NSObject, NSTextFieldDelegate {
        
        @Binding private var shortcut: Shortcut?
        @Binding private var error: (any Error)?
        
        
        init(shortcut: Binding<Shortcut?>, error: Binding<(any Error)?>) {
            
            self._shortcut = shortcut
            self._error = error
        }
        
        
        func controlTextDidEndEditing(_ obj: Notification) {
            
            guard let sender = obj.object as? NSTextField else { return assertionFailure() }
            
            let shortcut = sender.objectValue as? Shortcut
            
            self.error = nil
            
            // not edited
            guard shortcut != self.shortcut else { return }
            
            if let shortcut {
                do {
                    try shortcut.checkCustomizationAvailability(for: NSApp.mainMenu)
                    
                } catch {
                    self.error = error
                    sender.objectValue = self.shortcut  // reset text field
                    NSSound.beep()
                    
                    // make text field edit mode again
                    // -> Wrap with Task to delay a bit (2024-05, macOS 14).
                    Task {
                        _ = sender.becomeFirstResponder()
                    }
                    return
                }
            }
            
            // successfully update data
            self.shortcut = shortcut
        }
    }
}


final class ShortcutTextField: NSTextField, NSTextViewDelegate {
    
    // MARK: Private Properties
    
    private var keyDownMonitor: Any?
    private var windowObservationTask: Task<Void, Never>?
    
    
    // MARK: Text Field Methods
    
    override func viewWillMove(toSuperview newSuperview: NSView?) {
        
        super.viewWillMove(toSuperview: newSuperview)
        
        if newSuperview != nil {
            // fix the alignment to right regardless the UI layout direction
            self.alignment = .right
            self.baseWritingDirection = .leftToRight
        }
    }
    
    
    override func viewWillMove(toWindow newWindow: NSWindow?) {
        
        super.viewWillMove(toWindow: newWindow)
        
        if newWindow == nil {
            self.windowObservationTask?.cancel()
            self.windowObservationTask = nil
        }
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
        
        self.windowObservationTask?.cancel()
        if let window = self.window {
            self.windowObservationTask = Task {
                for await _ in NotificationCenter.default.notifications(named: NSWindow.didResignKeyNotification, object: window).map(\.name) {
                    window.makeFirstResponder(nil)
                }
            }
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
        if let monitor = self.keyDownMonitor {
            NSEvent.removeMonitor(monitor)
            self.keyDownMonitor = nil
        }
        self.windowObservationTask?.cancel()
        self.windowObservationTask = nil
        
        super.textDidEndEditing(notification)
    }
    
    
    // MARK: Text View Delegate
    
    func textView(_ view: NSTextView, menu: NSMenu, for event: NSEvent, at charIndex: Int) -> NSMenu? {
        
        // disable contextual menu for field editor
        nil
    }
}
