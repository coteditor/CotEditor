//
//  ShortcutFieldTests.swift
//  Tests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-10-30.
//
//  ---------------------------------------------------------------------------
//
//  © 2026 1024jp
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
import SwiftUI
import Testing
import Shortcut
@testable import CotEditor

@MainActor struct ShortcutFieldTests {
    
    /// Tests that recording and clearing update the binding and validate only nonempty shortcuts.
    ///
    /// - Parameter shortcut: The shortcut to record, or `nil` to clear the field.
    @Test(arguments: [Shortcut(.f6, modifiers: .command), nil])
    func recording(_ shortcut: Shortcut?) {
        
        var value: Shortcut? = Shortcut(.f5, modifiers: .command)
        var validated: Shortcut?
        let field = ShortcutField(value: Binding(get: { value }, set: { value = $0 }), error: .constant(nil)) {
            validated = $0
        }
        let sender = NSTextField()
        sender.objectValue = shortcut
        
        field.makeCoordinator().controlTextDidEndEditing(Notification(name: NSControl.textDidEndEditingNotification, object: sender))
        
        #expect(value == shortcut)
        #expect(validated == shortcut)
        #expect(sender.objectValue as? Shortcut == shortcut)
    }
    
    
    /// Tests that a rejected binding write restores the value accepted by the caller.
    @Test func rejectedWrite() {
        
        let original = Shortcut(.f5, modifiers: .command)
        let field = ShortcutField(value: Binding(get: { original }, set: { _ in }), error: .constant(nil)) { _ in }
        let sender = NSTextField()
        sender.objectValue = Shortcut(.f6, modifiers: .command)
        
        field.makeCoordinator().controlTextDidEndEditing(Notification(name: NSControl.textDidEndEditingNotification, object: sender))
        
        #expect(sender.objectValue as? Shortcut == original)
    }
    
    
    /// Tests that a reused coordinator uses the current bindings and validation when rejecting input.
    @Test func updatedField() {
        
        var oldValue: Shortcut? = Shortcut(.f5, modifiers: .command)
        var value: Shortcut? = Shortcut(.f6, modifiers: .command)
        var error: Shortcut.CustomizationError?
        let original = value
        let attempted = Shortcut(.f7, modifiers: .command)
        let field = ShortcutField(value: Binding(get: { oldValue }, set: { oldValue = $0 }), error: .constant(nil)) { _ in
            Issue.record("Outdated validation was used.")
        }
        let coordinator = field.makeCoordinator()
        coordinator.field = ShortcutField(value: Binding(get: { value }, set: { value = $0 }),
                                          error: Binding(get: { error }, set: { error = $0 })) { shortcut throws(Shortcut.CustomizationError) in
            throw .unsupported(shortcut)
        }
        let sender = NSTextField()
        sender.objectValue = attempted
        
        coordinator.controlTextDidEndEditing(Notification(name: NSControl.textDidEndEditingNotification, object: sender))
        
        #expect(oldValue == Shortcut(.f5, modifiers: .command))
        #expect(value == original)
        #expect(sender.objectValue as? Shortcut == original)
        guard case .unsupported(let rejected)? = error else {
            Issue.record("The current error binding was not updated.")
            return
        }
        #expect(rejected == attempted)
    }
}
