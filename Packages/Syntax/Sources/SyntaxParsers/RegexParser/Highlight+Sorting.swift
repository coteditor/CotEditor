//
//  Highlight+Sorting.swift
//  Syntax
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-07-11.
//
//  ---------------------------------------------------------------------------
//
//  © 2022-2026 1024jp
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
import SyntaxFormat
import StringUtils
import ValueRange

extension ValueRange<SyntaxType> {
    
    /// Converts a syntax highlight dictionary to sorted Highlights.
    ///
    /// - Note: This sanitization significantly reduces the performance time of attribute application.
    ///
    /// - Parameter dictionary: The syntax highlight dictionary.
    /// - Returns: An array of sorted Highlight structs.
    /// - Throws: `CancellationError`.
    static func highlights(dictionary: [SyntaxType: [NSRange]]) throws -> [ValueRange<SyntaxType>] {
        
        var occupied: [NSRange] = []
        
        return try SyntaxType.allCases.reversed()
            .reduce(into: [ValueRange<SyntaxType>]()) { highlights, type in
                guard let ranges = dictionary[type] else { return }
                
                try Task.checkCancellation()
                
                let merged = ranges
                    .filter { !$0.isEmpty }
                    .merged
                
                highlights += merged
                    .subtracting(occupied)
                    .map { ValueRange(value: type, range: $0) }
                occupied = (occupied + merged).merged
            }
            .sorted { $0.range.location < $1.range.location }
    }
}
