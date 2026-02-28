//
//  FindResult+Localization.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-02-28.
//
//  ---------------------------------------------------------------------------
//
//  © 2015-2026 1024jp
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

import Foundation
import TextFind

extension FindResult {
    
    /// The short result message for the user interface.
    var message: String {
        
        switch self.action {
            case .find:
                String(localized: "FindResult.find.message",
                       defaultValue: "\(self.count) matches",
                       table: "TextFind",
                       comment: "short result message for Find All (%lld is number of found)")
            case .replace:
                String(localized: "FindResult.replace.message",
                       defaultValue: "\(self.count) replaced",
                       table: "TextFind",
                       comment: "short result message for Replace All (%lld is number of replaced)")
        }
    }
    
    
    /// The short result message that shows the current match position, if available.
    var positionMessage: String? {
        
        guard let index = self.currentMatchIndex else { return nil }
        
        return switch self.action {
            case .find:
                String(localized: "FindResult.find.positionMessage",
                       defaultValue: "\(index)/\(self.count)",
                       table: "TextFind",
                       comment: "short result message for Find Next/Previous (%1$lld is current match position and %2$lld is number of found)")
            case .replace:
                nil
        }
    }
    
    
    /// The accessibility message that announces the current match position, if available.
    var accessibilityPositionMessage: String? {
        
        switch (self.action, self.currentMatchIndex) {
            case (.find, .some(let index)):
                String(localized: "FindResult.find.accessibilityPositionMessage",
                       defaultValue: "Match \(index) of \(self.count).",
                       table: "TextFind",
                       comment: "accessibility result message for Find Next/Previous (%1$lld is current match position and %2$lld is number of found)")
            default:
                nil
        }
    }
}
