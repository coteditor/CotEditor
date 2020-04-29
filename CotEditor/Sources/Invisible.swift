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

import class Foundation.UserDefaults

enum Invisible {
    
    case newLine
    case tab
    case space
    case noBreakSpace
    case fullwidthSpace
    case otherSpaceSeparator  // Unicode Category Zs (excl. U+1680)
    case otherControl  // Unicode Category Cc and U+200B
    
    
    init?(codeUnit: Unicode.UTF16.CodeUnit) {
        
        // > NSGlyphGenerator generates NSControlGlyph for all characters
        // > in the Unicode General Category C* and U200B (ZERO WIDTH SPACE).
        //   cf. https://developer.apple.com/documentation/appkit/nscontrolglyph
        
        switch codeUnit {
            case 0x000A:  // LINE FEED (Cc) a.k.a. \n
                self = .newLine
            case 0x0009:  // HORIZONTAL TABULATION (Cc) a.k.a. \t
                self = .tab
            case 0x0020:  // SPACE (Zs)
                self = .space
            case 0x00A0,  // NO-BREAK SPACE (Zs)
                 0x2007,  // FIGURE SPACE (Zs)
                 0x202F:  // NARROW NO-BREAK SPACE (Zs)
                self = .noBreakSpace
            case 0x3000:  // IDEOGRAPHIC SPACE (Zs) a.k.a. Japanese full-width space
                self = .fullwidthSpace
            case 0x2000...0x200A,  // (Zs) various width spaces, such as THREE-PER-EM SPACE
                 0x205F:  // MEDIUM MATHEMATICAL SPACE (Zs)
                self = .otherSpaceSeparator
            case 0x0000...0x001F,  // C0 (Cc)
                 0x007F...0x009F,  // C1 (Cc)
                 0x200B,  // ZERO WIDTH SPACE (Cf)
                 0x200C,  // ZERO WIDTH NON-JOINER (Cf)
                 0x200E...0x200F, 0x202A...0x202E, 0x2066...0x2069,  // bidi controls (Cf)
                 0x2060,  // WORD JOINER (Cf)
                 0xFEFF,  // ZERO WIDTH NO-BREAK SPACE a.k.a. BOM (Cf)
                 0xFFF9...0xFFFB:  // interlinear annotations, controls for ruby (Cf)
                self = .otherControl
            default:
                return nil
        }
    }
    
    
    var symbol: Character {
        
        switch self {
            case .newLine: return "↩"
            case .tab: return "→"
            case .space: return "·"
            case .noBreakSpace: return "·̂"
            case .fullwidthSpace: return "□"
            case .otherSpaceSeparator: return "="
            case .otherControl: return "�"
        }
    }
    
}



// MARK: User Deafults

extension Invisible: CaseIterable {
    
    var visibilityDefaultKey: DefaultKey<Bool> {
        
        switch self {
            case .newLine: return .showInvisibleNewLine
            case .tab: return .showInvisibleTab
            case .space: return .showInvisibleSpace
            case .noBreakSpace: return .showInvisibleWhitespaces
            case .fullwidthSpace: return .showInvisibleWhitespaces
            case .otherSpaceSeparator: return .showInvisibleWhitespaces
            case .otherControl: return .showInvisibleControl
        }
    }
}


extension UserDefaults {
    
    var showsInvisible: [Invisible] {
        
        return Invisible.allCases.filter { self[$0.visibilityDefaultKey] }
    }
    
}
