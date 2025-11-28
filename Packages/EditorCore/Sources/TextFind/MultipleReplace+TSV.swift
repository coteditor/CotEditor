//
//  MultipleReplace+TSV.swift
//  EditorCore
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2025-11-28.
//
//  ---------------------------------------------------------------------------
//
//  © 2025 1024jp
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation

public extension MultipleReplace {
    
    struct TSVParseOptions: OptionSet, Sendable {
        
        public var rawValue: Int
        
        public static let failsOnInvalidValue = Self(rawValue: 1 << 0)
        
        
        public init(rawValue: Int) {
            
            self.rawValue = rawValue
        }
    }
    
    
    /// Creates a `MultipleReplace` from a tab-separated values (TSV) string.
    ///
    /// - Parameters:
    ///   - tabSeparatedText: The TSV-formatted source string.
    ///   - options: Parsing options.
    /// - Throws: `TSVParseError.invalidFormat` if an invalid line is encountered and `.failsOnInvalidValue` is specified.
    init(tabSeparatedText: String, options: TSVParseOptions = []) throws {
        
        let replacements = try tabSeparatedText.split(separator: /\R/)
            .filter { !$0.isEmpty }
            .compactMap {
                do {
                    return try Replacement(line: $0)
                } catch {
                    if options.contains(.failsOnInvalidValue) {
                        throw error
                    } else {
                        return nil
                    }
                }
            }
        
        self.init(replacements: replacements)
    }
}


extension MultipleReplace.Replacement {
    
    enum TSVParseError: Error {
        
        case invalidFormat
    }
    
    
    /// Creates a `Replacement` from a single TSV line.
    ///
    /// - Parameter line: A single line of TSV input.
    /// - Throws: `TSVParseError.invalidFormat`.
    init(line: any StringProtocol) throws(TSVParseError) {
        
        let items = line.split(separator: "\t")
        
        guard
            items.count >= 2,
            !items[0].isEmpty
        else { throw .invalidFormat }
        
        self.init(findString: String(items[0]), replacementString: String(items[1]))
    }
}
