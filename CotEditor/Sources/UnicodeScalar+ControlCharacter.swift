//
//  UnicodeScalar+ControlCharacter.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2015-12-29.
//
//  ---------------------------------------------------------------------------
//
//  © 2015-2019 1024jp
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

extension UnicodeScalar {
    
    /// alternate picture caracter for invisible control character
    var pictureRepresentation: UnicodeScalar? {
        
        switch self.value {
            case ControlCharacter.C0Range:
                return UnicodeScalar(self.value + 0x2400)  // shift 0x2400 to Unicode control pictures
            case ControlCharacter.deleteCharacter:
                return UnicodeScalar(0x2421)  // SYMBOL FOR DELETE character
            default:
                return nil
        }
    }
    
}



extension UTF32Char {
    
    /// unicode name if receiver is a control character
    var controlCharacterName: String? {
        
        switch self {
            case ControlCharacter.C0Range:
                let index = Int(self)
                return ControlCharacter.C0Names[index]
            case ControlCharacter.C1Range:
                let index = Int(self - ControlCharacter.C1Range.lowerBound)  // shift to 0-based array index
                return ControlCharacter.C1Names[index]
            case ControlCharacter.deleteCharacter:
                return ControlCharacter.deleteName
            case ControlCharacter.zeroWidthNoBreakSpaceCharacter:
                return ControlCharacter.zeroWidthNoBreakSpaceName
            default:
                return nil
        }
    }
    
}



// MARK: -

enum ControlCharacter {
    
    // MARK: Code Point Ranges
    
    static let deleteCharacter = UInt32(0x007F)
    static let C0Range = UInt32(0x0000)...UInt32(0x0020)  // U+0020 is actually not in range of C0 control character. But they are often included in actual fact.
    static let C1Range = UInt32(0x0080)...UInt32(0x009F)
    static let zeroWidthNoBreakSpaceCharacter = UInt32(0xFEFF)  // BOM
    
    
    // MARK: Names
    
    static let deleteName = "DELETE"
    static let zeroWidthNoBreakSpaceName = "ZERO WIDTH NO-BREAK SPACE"
    
    static let C0Names = [
        "NULL",
        "START OF HEADING",
        "START OF TEXT",
        "END OF TEXT",
        "END OF TRANSMISSION",
        "ENQUIRY",
        "ACKNOWLEDGE",
        "BELL",
        "BACKSPACE",
        "HORIZONTAL TABULATION",
        "LINE FEED",
        "VERTICAL TABULATION",
        "FORM FEED",
        "CARRIAGE RETURN",
        "SHIFT OUT",
        "SHIFT IN",
        "DATA LINK ESCAPE",
        "DEVICE CONTROL ONE",
        "DEVICE CONTROL TWO",
        "DEVICE CONTROL THREE",
        "DEVICE CONTROL FOUR",
        "NEGATIVE ACKNOWLEDGE",
        "SYNCHRONOUS IDLE",
        "END OF TRANSMISSION BLOCK",
        "CANCEL",
        "END OF MEDIUM",
        "SUBSTITUTE",
        "ESCAPE",
        "FILE SEPARATOR",
        "GROUP SEPARATOR",
        "RECORD SEPARATOR",
        "UNIT SEPARATOR",
        "SPACE",
    ]
    
    static let C1Names = [
        "PADDING CHARACTER",
        "HIGH OCTET PRESET",
        "BREAK PERMITTED HERE",
        "NO BREAK HERE",
        "INDEX",
        "NEXT LINE",
        "START OF SELECTED AREA",
        "END OF SELECTED AREA",
        "CHARACTER TABULATION SET",
        "CHARACTER TABULATION WITH JUSTIFICATION",
        "LINE TABULATION SET",
        "PARTIAL LINE FORWARD",
        "PARTIAL LINE BACKWARD",
        "REVERSE LINE FEED",
        "SINGLE SHIFT TWO",
        "SINGLE SHIFT THREE",
        "DEVICE CONTROL STRING",
        "PRIVATE USE ONE",
        "PRIVATE USE TWO",
        "SET TRANSMIT STATE",
        "CANCEL CHARACTER",
        "MESSAGE WAITING",
        "START OF PROTECTED AREA",
        "END OF PROTECTED AREA",
        "START OF STRING",
        "SINGLE GRAPHIC CHARACTER INTRODUCER",
        "SINGLE CHARACTER INTRODUCER",
        "CONTROL SEQUENCE INTRODUCER",
        "STRING TERMINATOR",
        "OPERATING SYSTEM COMMAND",
        "PRIVACY MESSAGE",
        "APPLICATION PROGRAM COMMAND",
    ]
    
}
