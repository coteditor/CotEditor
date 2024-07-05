//
//  Unicode.Scalar+ControlCharacter.swift
//  CharacterInfo
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2015-12-29.
//
//  ---------------------------------------------------------------------------
//
//  © 2015-2024 1024jp
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
    
    /// The alternate picture character for invisible control character if available.
    var pictureRepresentation: Unicode.Scalar? {
        
        switch self.value {
            case 0x0000...0x0020:  // C0 + SPACE
                Unicode.Scalar(self.value + 0x2400)  // shift 0x2400 to Unicode control pictures
            case 0x007F:  // DELETE
                Unicode.Scalar(0x2421)  // SYMBOL FOR DELETE character
            default:
                nil
        }
    }
    
    
    /// Human-friendly name if receiver is a control character.
    var controlCharacterName: String? {
        
        switch self.value {
            // C0
            case 0x0000: "NULL"
            case 0x0001: "START OF HEADING"
            case 0x0002: "START OF TEXT"
            case 0x0003: "END OF TEXT"
            case 0x0004: "END OF TRANSMISSION"
            case 0x0005: "ENQUIRY"
            case 0x0006: "ACKNOWLEDGE"
            case 0x0007: "BELL"
            case 0x0008: "BACKSPACE"
            case 0x0009: "HORIZONTAL TABULATION"
            case 0x000A: "LINE FEED"
            case 0x000B: "VERTICAL TABULATION"
            case 0x000C: "FORM FEED"
            case 0x000D: "CARRIAGE RETURN"
            case 0x000E: "SHIFT OUT"
            case 0x000F: "SHIFT IN"
            case 0x0010: "DATA LINK ESCAPE"
            case 0x0011: "DEVICE CONTROL ONE"
            case 0x0012: "DEVICE CONTROL TWO"
            case 0x0013: "DEVICE CONTROL THREE"
            case 0x0014: "DEVICE CONTROL FOUR"
            case 0x0015: "NEGATIVE ACKNOWLEDGE"
            case 0x0016: "SYNCHRONOUS IDLE"
            case 0x0017: "END OF TRANSMISSION BLOCK"
            case 0x0018: "CANCEL"
            case 0x0019: "END OF MEDIUM"
            case 0x001A: "SUBSTITUTE"
            case 0x001B: "ESCAPE"
            case 0x001C: "FILE SEPARATOR"
            case 0x001D: "GROUP SEPARATOR"
            case 0x001E: "RECORD SEPARATOR"
            case 0x001F: "UNIT SEPARATOR"
            
            // DELETE
            case 0x007F: "DELETE"
            
            // C1
            case 0x0080: "PADDING CHARACTER"
            case 0x0081: "HIGH OCTET PRESET"
            case 0x0082: "BREAK PERMITTED HERE"
            case 0x0083: "NO BREAK HERE"
            case 0x0084: "INDEX"
            case 0x0085: "NEXT LINE"
            case 0x0086: "START OF SELECTED AREA"
            case 0x0087: "END OF SELECTED AREA"
            case 0x0088: "CHARACTER TABULATION SET"
            case 0x0089: "CHARACTER TABULATION WITH JUSTIFICATION"
            case 0x008A: "LINE TABULATION SET"
            case 0x008B: "PARTIAL LINE FORWARD"
            case 0x008C: "PARTIAL LINE BACKWARD"
            case 0x008D: "REVERSE LINE FEED"
            case 0x008E: "SINGLE SHIFT TWO"
            case 0x008F: "SINGLE SHIFT THREE"
            case 0x0090: "DEVICE CONTROL STRING"
            case 0x0091: "PRIVATE USE ONE"
            case 0x0092: "PRIVATE USE TWO"
            case 0x0093: "SET TRANSMIT STATE"
            case 0x0094: "CANCEL CHARACTER"
            case 0x0095: "MESSAGE WAITING"
            case 0x0096: "START OF PROTECTED AREA"
            case 0x0097: "END OF PROTECTED AREA"
            case 0x0098: "START OF STRING"
            case 0x0099: "SINGLE GRAPHIC CHARACTER INTRODUCER"
            case 0x009A: "SINGLE CHARACTER INTRODUCER"
            case 0x009B: "CONTROL SEQUENCE INTRODUCER"
            case 0x009C: "STRING TERMINATOR"
            case 0x009D: "OPERATING SYSTEM COMMAND"
            case 0x009E: "PRIVACY MESSAGE"
            case 0x009F: "APPLICATION PROGRAM COMMAND"
                
            default: nil
        }
    }
}
