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
//  © 2017-2026 1024jp
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
import StringUtils

extension NSTextStorage {
    
    /// Observes the first text storage update when part of the content is directly edited from AppleScript.
    ///
    /// Example:
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
    ///   - editedString: The content of the textStorage after the editing.
    @MainActor final func observeDirectEditing(block: @MainActor @escaping @Sendable (_ editedString: String) -> Void) {
        
        let center = NotificationCenter.default
        let (strings, continuation) = AsyncStream<String>.makeStream(bufferingPolicy: .bufferingOldest(1))
        let observer = center.addObserver(of: self, for: DirectEditingMessage.self) { message in
            continuation.yield(message.string)
        }
        
        Task {
            defer {
                center.removeObserver(observer)
                continuation.finish()
            }
            
            try? await withThrowingTaskGroup { group in
                // observe text storage update
                group.addTask {
                    for await string in strings {
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


/// A snapshot of the text storage content when an editing notification is posted.
private struct DirectEditingMessage: NotificationCenter.MainActorMessage {
    
    typealias Subject = NSTextStorage
    
    static let name = NSTextStorage.didProcessEditingNotification
    
    let string: String
    
    
    /// Converts an editing notification into a snapshot of the edited content.
    ///
    /// - Parameters:
    ///   - notification: The text storage editing notification.
    /// - Returns: A message containing the edited content, or `nil` if the notification has no text storage object.
    static func makeMessage(_ notification: Notification) -> Self? {
        
        guard let textStorage = notification.object as? NSTextStorage else { return nil }
        
        return Self(string: textStorage.string.immutable)
    }
}
