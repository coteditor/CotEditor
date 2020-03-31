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

extension Unicode.Scalar {
    
    static let zeroWidthSpace = Unicode.Scalar(0x200B)!
}


enum Invisible {
    
    case newLine
    case tab
    case space
    case fullwidthSpace
    case otherControl
    
    
    var symbol: Character {
        
        switch self {
            case .newLine: return "↩"
            case .tab: return "‣"
            case .space: return "·"
            case .fullwidthSpace: return "□"
            case .otherControl: return "�"
        }
    }
    
    
    private var rtlSymbol: Character {  // not used
        
        switch self {
            case .newLine: return "↪"
            case .tab: return "◂"
            default: return self.symbol
        }
    }
    
}



// MARK: Code Unit

extension Invisible {
    
    init?(codeUnit: Unicode.UTF16.CodeUnit) {
        
        switch codeUnit {
            case 0x000A:  // LINE FEED a.k.a. \n
                self = .newLine
            case 0x0009:  // HORIZONTAL TABULATION a.k.a. \t
                self = .tab
            case 0x0020, 0x00A0:  // SPACE, NO-BREAK SPACE
                self = .space
            case 0x3000:  // IDEOGRAPHIC SPACE a.k.a. Japanese full-width space
                self = .fullwidthSpace
            case 0x0000...0x001F,  // C0
                 0x0080...0x009F,  // C1
                 0x200B:  // ZERO WIDTH SPACE
                // -> NSGlyphGenerator generates NSControlGlyph for all characters
                //    in the Unicode General Category C* and U+200B (ZERO WIDTH SPACE).
                self = .otherControl
            default:
                return nil
        }
    }
    
}
