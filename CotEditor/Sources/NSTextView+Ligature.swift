//
//  NSTextView+Ligature.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2019-06-22.
//
//  ---------------------------------------------------------------------------
//
//  © 2019-2020 1024jp
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

extension NSTextView {
    
    enum LigatureMode: Int {
        
        case none
        case standard
        case all
    }
    
    
    /// Ligature mode.
    var ligature: LigatureMode {
        
        get {
            guard
                let rawValue = self.typingAttributes[.ligature] as? Int,
                let mode = LigatureMode(rawValue: rawValue)
            else { return .standard }
            
            return mode
        }
        
        set {
            switch newValue {
                case .standard:  // NSTextView uses the standard ligature by default.
                    self.typingAttributes[.ligature] = nil
                    if let textStorage = self.textStorage {
                        textStorage.removeAttribute(.ligature, range: textStorage.range)
                    }
                case .none, .all:
                    self.typingAttributes[.ligature] = newValue.rawValue
                    if let textStorage = self.textStorage {
                        textStorage.addAttribute(.ligature, value: newValue.rawValue, range: textStorage.range)
                    }
            }
        }
    }
}
