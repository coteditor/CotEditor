//
//  Highlight.swift
//  Syntax
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-07-11.
//
//  ---------------------------------------------------------------------------
//
//  © 2022-2024 1024jp
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
import ValueRange

public typealias Highlight = ValueRange<SyntaxType>


extension Highlight {
    
    /// Converts a syntax highlight dictionary to sorted Highlights.
    ///
    /// - Note:
    /// This sanitization reduces the performance time of `LayoutManager.apply(highlights:theme:range:)` significantly.
    ///
    /// - Parameter dictionary: The syntax highlight dictionary.
    /// - Returns: An array of sorted Highlight structs.
    /// - Throws: CancellationError
    static func highlights(dictionary: [SyntaxType: [NSRange]]) throws -> [Highlight] {
        
        try SyntaxType.allCases.reversed()
            .reduce(into: [SyntaxType: IndexSet]()) { (dict, type) in
                guard let ranges = dictionary[type] else { return }
                
                try Task.checkCancellation()
                
                let indexes = IndexSet(integersIn: ranges)
                
                dict[type] = dict.values.reduce(into: indexes) { $0.subtract($1) }
            }
            .mapValues { $0.rangeView.map(NSRange.init) }
            .flatMap { (type, ranges) in ranges.map { ValueRange(value: type, range: $0) } }
            .sorted(using: KeyPathComparator(\.range.location))
    }
}
