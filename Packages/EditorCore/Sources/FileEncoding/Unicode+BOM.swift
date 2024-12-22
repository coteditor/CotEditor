//
//  Unicode+BOM.swift
//  FileEncoding
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-01-16.
//
//  ---------------------------------------------------------------------------
//
//  © 2014-2024 1024jp
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

public extension Unicode {
    
    /// Byte order mark.
    enum BOM: Sendable, CaseIterable {
        
        case utf8
        case utf32BigEndian
        case utf32LittleEndian
        case utf16BigEndian
        case utf16LittleEndian
        
        
        /// The byte sequence.
        public var sequence: [UInt8] {
            
            switch self {
                case .utf8: [0xEF, 0xBB, 0xBF]
                case .utf32BigEndian: [0x00, 0x00, 0xFE, 0xFF]
                case .utf32LittleEndian: [0xFF, 0xFE, 0x00, 0x00]
                case .utf16BigEndian: [0xFE, 0xFF]
                case .utf16LittleEndian: [0xFF, 0xFE]
            }
        }
        
        
        /// The corresponding string encoding.
        var encoding: String.Encoding {
            
            switch self {
                case .utf8: .utf8
                case .utf32BigEndian, .utf32LittleEndian: .utf32
                case .utf16BigEndian, .utf16LittleEndian: .utf16
            }
        }
    }
}
