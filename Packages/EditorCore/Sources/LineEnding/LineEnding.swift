//
//  LineEnding.swift
//  LineEnding
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2014-11-30.
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

public enum LineEnding: Character, Sendable, CaseIterable {
    
    case lf = "\n"
    case cr = "\r"
    case crlf = "\r\n"
    case nel = "\u{0085}"
    case lineSeparator = "\u{2028}"
    case paragraphSeparator = "\u{2029}"
    
    
    /// The string representation of the line ending.
    public var string: String {
        
        String(self.rawValue)
    }
    
    
    /// The length in Unicode scalars.
    public var length: Int {
        
        self.rawValue.unicodeScalars.count
    }
    
    
    /// The index in the `enum`.
    public var index: Int {
        
        Self.allCases.firstIndex(of: self)!
    }
    
    
    /// Whether the line ending is a basic one.
    public var isBasic: Bool {
        
        switch self {
            case .lf, .cr, .crlf: true
            case .nel, .lineSeparator, .paragraphSeparator: false
        }
    }
    
    
    /// The short label to display.
    public var label: String {
        
        switch self {
            case .lf: "LF"
            case .cr: "CR"
            case .crlf: "CRLF"
            case .nel: "NEL"
            case .lineSeparator: "LS"
            case .paragraphSeparator: "PS"
        }
    }
}
