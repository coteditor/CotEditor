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
//  © 2017-2023 1024jp
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

extension NSTextStorage {
    
    /// Observe text storage update for in case when a part of the contents is directly edited from an AppleScript.
    ///
    /// e.g.:
    /// ```AppleScript
    /// tell first document of application "CotEditor"
    ///     set first paragraph of contents to "foo bar"
    /// end tell
    /// ```
    ///
    /// - Attention: This method is aimed to be used only for text storages that will be passed to AppleScript.
    ///
    /// - Parameters
    ///   - block: The block to be executed when the textStorage is edited.
    ///   - editedString: The contents of the textStorage after the editing.
    final func observeDirectEditing(block: @escaping (_ editedString: String) -> Void) {
        
        weak var observer: (any NSObjectProtocol)?
        observer = NotificationCenter.default.addObserver(forName: NSTextStorage.didProcessEditingNotification, object: self, queue: .main) { [weak self] notification in
            if let observer {
                NotificationCenter.default.removeObserver(observer)
            }
            
            guard let textStorage = notification.object as? NSTextStorage else { return assertionFailure() }
            
            // -> After `self` becoming `nil`, notifications by other objects come also into this block.
            guard textStorage == self else { return }
            
            block(textStorage.string)
        }
        
        // disconnect the observation after 0.5 sec. anyway (otherwise app may crash)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let observer {
                NotificationCenter.default.removeObserver(observer)
            }
        }
    }
}
