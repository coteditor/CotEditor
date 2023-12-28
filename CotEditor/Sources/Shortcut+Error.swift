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
import Foundation

extension Shortcut {
    
    struct CustomizationError: LocalizedError {
        
        enum Kind {
            
            case singleType
            case alreadyTaken(name: String)
            case shiftOnlyModifier
            case unsupported
        }
        
        var kind: Kind
        var shortcut: Shortcut
        
        
        var errorDescription: String? {
            
            switch self.kind {
                case .singleType:
                    String(localized: "Single type is invalid for a shortcut.")
                    
                case .alreadyTaken(let name):
                    String(localized: "“\(self.shortcut.symbol)” is already taken by the “\(name)” command.")
                    
                case .shiftOnlyModifier:
                    String(localized: "The Shift key can be used only with another modifier key.")
                    
                case .unsupported:
                    String(localized: "The combination “\(self.shortcut.symbol)” is not supported for the shortcut customization.")
            }
        }
    }
    

    /// Validates whether the shortcut is available for user customization.
    ///
    /// - Throws: `Shortcut.CustomizationError`
    func checkCustomizationAvailability() throws {
        
        // Tab or Backtab
        if self.keyEquivalent == "\u{9}" || self.keyEquivalent == "\u{19}" {
            throw CustomizationError(kind: .unsupported, shortcut: self)
        }
        
        // avoid Shift-only modifier with a letter
        // -> typing Shift + letter inserting an uppercase letter instead of invoking a shortcut
        if self.modifiers == .shift, self.keyEquivalent.contains(where: \.isLetter) {
            throw CustomizationError(kind: .shiftOnlyModifier, shortcut: self)
        }
        
        // single key is invalid
        if !self.isValid {
            throw CustomizationError(kind: .singleType, shortcut: self)
        }
        
        // duplication check
        if let duplicatedName = NSApp.mainMenu?.commandName(for: self) {
            throw CustomizationError(kind: .alreadyTaken(name: duplicatedName), shortcut: self)
        }
    }
}
