//
//  Unicode.Scalar+ControlCharacter.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2015-12-29.
//
//  ---------------------------------------------------------------------------
//
//  © 2015-2020 1024jp
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
    
    /// Alternate picture caracter for invisible control character.
    var pictureRepresentation: Unicode.Scalar? {
        
        switch self.value {
            case 0x0000...0x0020:  // C0 + SPACE
                return Unicode.Scalar(self.value + 0x2400)  // shift 0x2400 to Unicode control pictures
            case 0x007F:  // DELETE
                return Unicode.Scalar(0x2421)  // SYMBOL FOR DELETE character
            default:
                return nil
        }
    }
    
    
    /// Human-friendly name if receiver is a control character.
    var controlCharacterName: String? {
        
        switch self.value {
            // C0
            case 0x0000: return "NULL"
            case 0x0001: return "START OF HEADING"
            case 0x0002: return "START OF TEXT"
            case 0x0003: return "END OF TEXT"
            case 0x0004: return "END OF TRANSMISSION"
            case 0x0005: return "ENQUIRY"
            case 0x0006: return "ACKNOWLEDGE"
            case 0x0007: return "BELL"
            case 0x0008: return "BACKSPACE"
            case 0x0009: return "HORIZONTAL TABULATION"
            case 0x000A: return "LINE FEED"
            case 0x000B: return "VERTICAL TABULATION"
            case 0x000C: return "FORM FEED"
            case 0x000D: return "CARRIAGE RETURN"
            case 0x000E: return "SHIFT OUT"
            case 0x000F: return "SHIFT IN"
            case 0x0010: return "DATA LINK ESCAPE"
            case 0x0011: return "DEVICE CONTROL ONE"
            case 0x0012: return "DEVICE CONTROL TWO"
            case 0x0013: return "DEVICE CONTROL THREE"
            case 0x0014: return "DEVICE CONTROL FOUR"
            case 0x0015: return "NEGATIVE ACKNOWLEDGE"
            case 0x0016: return "SYNCHRONOUS IDLE"
            case 0x0017: return "END OF TRANSMISSION BLOCK"
            case 0x0018: return "CANCEL"
            case 0x0019: return "END OF MEDIUM"
            case 0x001A: return "SUBSTITUTE"
            case 0x001B: return "ESCAPE"
            case 0x001C: return "FILE SEPARATOR"
            case 0x001D: return "GROUP SEPARATOR"
            case 0x001E: return "RECORD SEPARATOR"
            case 0x001F: return "UNIT SEPARATOR"
            
            // DELETE
            case 0x007F: return "DELETE"
            
            // C1
            case 0x0080: return "PADDING CHARACTER"
            case 0x0081: return "HIGH OCTET PRESET"
            case 0x0082: return "BREAK PERMITTED HERE"
            case 0x0083: return "NO BREAK HERE"
            case 0x0084: return "INDEX"
            case 0x0085: return "NEXT LINE"
            case 0x0086: return "START OF SELECTED AREA"
            case 0x0087: return "END OF SELECTED AREA"
            case 0x0088: return "CHARACTER TABULATION SET"
            case 0x0089: return "CHARACTER TABULATION WITH JUSTIFICATION"
            case 0x008A: return "LINE TABULATION SET"
            case 0x008B: return "PARTIAL LINE FORWARD"
            case 0x008C: return "PARTIAL LINE BACKWARD"
            case 0x008D: return "REVERSE LINE FEED"
            case 0x008E: return "SINGLE SHIFT TWO"
            case 0x008F: return "SINGLE SHIFT THREE"
            case 0x0090: return "DEVICE CONTROL STRING"
            case 0x0091: return "PRIVATE USE ONE"
            case 0x0092: return "PRIVATE USE TWO"
            case 0x0093: return "SET TRANSMIT STATE"
            case 0x0094: return "CANCEL CHARACTER"
            case 0x0095: return "MESSAGE WAITING"
            case 0x0096: return "START OF PROTECTED AREA"
            case 0x0097: return "END OF PROTECTED AREA"
            case 0x0098: return "START OF STRING"
            case 0x0099: return "SINGLE GRAPHIC CHARACTER INTRODUCER"
            case 0x009A: return "SINGLE CHARACTER INTRODUCER"
            case 0x009B: return "CONTROL SEQUENCE INTRODUCER"
            case 0x009C: return "STRING TERMINATOR"
            case 0x009D: return "OPERATING SYSTEM COMMAND"
            case 0x009E: return "PRIVACY MESSAGE"
            case 0x009F: return "APPLICATION PROGRAM COMMAND"
            
            default:
                assert(self.properties.generalCategory != .control)
                return nil
        }
    }
    
}
