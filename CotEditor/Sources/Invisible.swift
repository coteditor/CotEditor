/*
 
 Invisible.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-01-03.
 
 ------------------------------------------------------------------------------
 
 © 2014-2018 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 https://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Foundation

enum Invisible {
    
    case space
    case tab
    case newLine
    case fullwidthSpace
    case verticalTab
    case replacement
    
    
    var candidates: [String] {
        
        switch self {
        case .space:
            return ["·", "°", "ː", "␣"]
        case .tab:
            return ["¬", "⇥", "‣", "▹"]
        case .newLine:
            return ["¶", "↩", "↵", "⏎"]
        case .fullwidthSpace:
            return ["□", "⊠", "■", "•"]
        case .verticalTab:
            return ["␋"]
        case .replacement:
            return ["�"]
        }
    }
    
}



// MARK: Code Unit

extension Invisible {

    init?(codeUnit: Unicode.UTF16.CodeUnit) {
        
        switch codeUnit {
        case " ".utf16.first!, 0x00A0:
            self = .space
        case "\t".utf16.first!:  // HORIZONTAL TABULATION
            self = .tab
        case "\n".utf16.first!:
            self = .newLine
        case 0x3000:  // IDEOGRAPHIC SPACE a.k.a. full-width space (JP)
            self = .fullwidthSpace
        case 0x000B:  // LINE TABULATION a.k.a. vertical tab
            self = .verticalTab
        default:
            // `.replacement` cannot be determined only with code unit
            return nil
        }
    }
    
}



// MARK: User Defaults

extension Invisible {
    
    var usedSymbol: String {
        
        guard
            let key = self.defaultTypeKey,
            let symbol = self.candidates[safe: UserDefaults.standard[key]]
            else { return self.candidates.first! }
        
        return symbol
    }
    
    
    private var defaultTypeKey: DefaultKey<Int>? {
        
            switch self {
            case .space: return .invisibleSpace
            case .tab: return .invisibleTab
            case .newLine: return .invisibleNewLine
            case .fullwidthSpace: return .invisibleFullwidthSpace
            case .verticalTab: return nil
            case .replacement: return nil
            }
    }
    
}
