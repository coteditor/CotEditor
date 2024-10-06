//
//  Shortcut+Error.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2023-02-01.
//
//  ---------------------------------------------------------------------------
//
//  © 2014-2024 1024jp
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
import Foundation
import Shortcut

extension Shortcut {
    
    enum CustomizationError: LocalizedError {
        
        case singleType
        case alreadyTaken(Shortcut, name: String)
        case shiftOnlyModifier
        case unsupported(Shortcut)
        
        
        var errorDescription: String? {
            
            switch self {
                case .singleType:
                    String(localized: "Shortcut.CustomizationError.singleType.description",
                           defaultValue: "Single type is invalid for a shortcut.")
                    
                case .alreadyTaken(let shortcut, let name):
                    String(localized: "Shortcut.CustomizationError.alreadyTaken.description",
                           defaultValue: "“\(shortcut.symbol)” is already taken by the “\(name)” command.")
                    
                case .shiftOnlyModifier:
                    String(localized: "Shortcut.CustomizationError.shiftOnlyModifier.description",
                           defaultValue: "The Shift key can be used only with another modifier key.")
                    
                case .unsupported(let shortcut):
                    String(localized: "Shortcut.CustomizationError.unsupported.description",
                           defaultValue: "The combination “\(shortcut.symbol)” is not supported for the shortcut customization.")
            }
        }
    }
    

    /// Validates whether the shortcut is available for user customization.
    ///
    /// - Parameter menu: The menu tree for duplication check.
    @MainActor func checkCustomizationAvailability(for menu: NSMenu?) throws(Shortcut.CustomizationError) {
        
        // Tab or Backtab
        if self.keyEquivalent == "\u{9}" || self.keyEquivalent == "\u{19}" {
            throw .unsupported(self)
        }
        
        // avoid Shift-only modifier with a letter
        // -> typing Shift + letter inserting an uppercase letter instead of invoking a shortcut
        if self.modifiers == .shift, self.keyEquivalent.contains(where: \.isLetter) {
            throw .shiftOnlyModifier
        }
        
        // single key is invalid
        if !self.isValid {
            throw .singleType
        }
        
        // duplication check
        if let duplicatedName = menu?.commandName(for: self) {
            throw .alreadyTaken(self, name: duplicatedName)
        }
    }
}
