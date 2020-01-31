//
//  Invisible.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-01-03.
//
//  ---------------------------------------------------------------------------
//
//  © 2014-2020 1024jp
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

enum Invisible {
    
    case space
    case tab
    case newLine
    case fullwidthSpace
    case otherControl
    
    
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
        case .otherControl:
            return ["�"]
        }
    }
    
    
    var rtlCandidates: [String] {
        
        switch self {
        case .tab:
            return ["¬", "⇤", "◂", "◃"]
        case .newLine:
            return ["¶", "↪", "↳", "⏎"]
        default:
            return self.candidates
        }
    }
    
}



// MARK: Code Unit

extension Invisible {

    init?(codeUnit: Unicode.UTF16.CodeUnit) {
        
        switch codeUnit {
        case 0x0020, 0x00A0:  // SPACE, NO-BREAK SPACE
            self = .space
        case 0x0009:  // HORIZONTAL TABULATION a.k.a. \t
            self = .tab
        case 0x000A:  // LINE FEED a.k.a. \n
            self = .newLine
        case 0x3000:  // IDEOGRAPHIC SPACE a.k.a. full-width space (JP)
            self = .fullwidthSpace
        case 0x0000...0x001F, 0x0080...0x009F, 0x200B:  // C0, C1, ZERO WIDTH SPACE
            // -> NSGlyphGenerator generates NSControlGlyph for all characters
            //    in the Unicode General Category C* and U+200B (ZERO WIDTH SPACE).
            self = .otherControl
        default:
            return nil
        }
    }
    
}



// MARK: User Defaults

extension UserDefaults {
    
    func invisibleSymbol(for invisible: Invisible) -> String {
        
        guard
            let key = invisible.defaultTypeKey,
            let symbol = invisible.candidates[safe: self[key]]
            else { return invisible.candidates[0] }
        
        return symbol
    }
}


private extension Invisible {
    
    var defaultTypeKey: DefaultKey<Int>? {
        
            switch self {
            case .space: return .invisibleSpace
            case .tab: return .invisibleTab
            case .newLine: return .invisibleNewLine
            case .fullwidthSpace: return .invisibleFullwidthSpace
            case .otherControl: return nil
            }
    }
    
}
