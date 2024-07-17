//
//  NSMenuItem+Shortcut.swift
//  Shortcut
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2023-03-11.
//
//  ---------------------------------------------------------------------------
//
//  © 2023-2024 1024jp
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

public extension NSMenuItem {
    
    /// The `Shortcut` representation of the keyboard shortcut.
    final var shortcut: Shortcut? {
        
        get {
            Shortcut(self.keyEquivalent, modifiers: self.keyEquivalentModifierMask)
        }
        
        set {
            self.keyEquivalent = newValue?.keyEquivalent ?? ""
            self.keyEquivalentModifierMask = newValue?.modifiers ?? []
        }
    }
}


public extension NSMenu {
    
    /// Finds the menu item that has the given shortcut.
    ///
    /// - Parameter shortcut: The shortcut to find.
    /// - Returns: The command name for the user.
    final func commandName(for shortcut: Shortcut) -> String? {
        
        self.items.lazy
            .compactMap { item in
                if let submenu = item.submenu {
                    submenu.commandName(for: shortcut)
                } else if shortcut == item.shortcut {
                    item.title
                } else {
                    nil
                }
            }
            .first?
            .trimmingCharacters(in: .whitespaces.union(.punctuationCharacters))  // remove ellipsis
    }
}
