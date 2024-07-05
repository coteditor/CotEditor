//
//  NSTextStorage+ScriptingSupport.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2017-01-30.
//
//  ---------------------------------------------------------------------------
//
//  © 2017-2024 1024jp
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

import AppKit.NSTextStorage

extension NSTextStorage {
    
    /// Observes text storage update for in case when a part of the contents are directly edited from AppleScript.
    ///
    /// example:
    /// ```AppleScript
    /// tell first document of application "CotEditor"
    ///     set first paragraph of contents to "foo bar"
    /// end tell
    /// ```
    ///
    /// - Attention: This method is aimed to be used only for text storages that will be passed to AppleScript.
    ///
    /// - Parameters:
    ///   - block: The block to be executed when the textStorage is edited.
    ///   - editedString: The contents of the textStorage after the editing.
    final func observeDirectEditing(block: @MainActor @Sendable @escaping (_ editedString: String) -> Void) {
        
        let notifications = NotificationCenter.default.notifications(named: NSTextStorage.didProcessEditingNotification, object: self)
        
        Task {
            try await withThrowingTaskGroup(of: Void.self) { group in
                // observe text storage update
                group.addTask {
                    for await textStorage in notifications.map({ $0.object as! NSTextStorage }) {
                        let string = textStorage.string
                        await block(string)
                        break
                    }
                }
                
                // timeout
                group.addTask {
                    try await Task.sleep(for: .seconds(0.5))
                    throw CancellationError()
                }
                
                _ = try await group.next()!
                group.cancelAll()
            }
        }
    }
}
