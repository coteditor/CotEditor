//
//  String+AdvancedCounting.swift
//  StringUtils
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2014-05-04.
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

import Foundation

public struct CharacterCountOptions: Sendable {
    
    public enum CharacterUnit: String, Sendable, CaseIterable {
        
        case graphemeCluster
        case unicodeScalar
        case utf16
        case byte
    }
    
    
    public var unit: CharacterUnit
    public var normalizationForm: UnicodeNormalizationForm?
    public var ignoresNewlines: Bool
    public var ignoresWhitespaces: Bool
    public var treatsConsecutiveWhitespaceAsSingle: Bool
    public var encoding: String.Encoding
    
    
    public init(unit: CharacterUnit = .graphemeCluster, normalizationForm: UnicodeNormalizationForm? = nil, ignoresNewlines: Bool = false, ignoresWhitespaces: Bool = false, treatsConsecutiveWhitespaceAsSingle: Bool = false, encoding: String.Encoding = .utf8) {
        
        self.unit = unit
        self.normalizationForm = normalizationForm
        self.ignoresNewlines = ignoresNewlines
        self.ignoresWhitespaces = ignoresWhitespaces
        self.treatsConsecutiveWhitespaceAsSingle = treatsConsecutiveWhitespaceAsSingle
        self.encoding = encoding
    }
}


public extension String {
    
    /// Counts string in the way described in the `option`.
    ///
    /// - Parameter options: The way to count.
    /// - Returns: Counted number, or nil if failed.
    func count(options: CharacterCountOptions) -> Int? {
        
        guard !self.isEmpty else { return 0 }
        
        var string = self
        
        if options.ignoresNewlines {
            string.replace(/\R/, with: "")
        }
        if options.ignoresWhitespaces {
            string.replace(/[\t\p{Zs}]/, with: "")
        }
        if options.treatsConsecutiveWhitespaceAsSingle,
           !options.ignoresNewlines || !options.ignoresWhitespaces
        {
            // \s = [\t\n\f\r\p{Z}]
            string.replace(/\s{2,}/, with: " ")
        }
        
        if let normalizationForm = options.normalizationForm {
            string = string.normalizing(in: normalizationForm)
        }
        
        switch options.unit {
            case .graphemeCluster:
                return string.count
            case .unicodeScalar:
                return string.unicodeScalars.count
            case .utf16:
                return string.utf16.count
            case .byte:
                guard string.canBeConverted(to: options.encoding) else { return nil }
                return string.lengthOfBytes(using: options.encoding)
        }
    }
}
