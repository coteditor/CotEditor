//
//  RegexOutlineParser.swift
//  Syntax
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-01-18.
//
//  ---------------------------------------------------------------------------
//
//  © 2026 1024jp
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
import StringUtils

actor RegexOutlineParser: OutlineParsing {
    
    // MARK: Private Properties
    
    private let extractors: [OutlineExtractor]
    private let policy: OutlinePolicy
    private var identityResolver: OutlineItem.IdentityResolver = .init()
    
    
    // MARK: Lifecycle
    
    init(extractors: [OutlineExtractor], policy: OutlinePolicy = .init()) {
        
        self.extractors = extractors
        self.policy = policy
    }
    
    
    // MARK: OutlineParsing Methods
    
    /// Parses and returns outline items from the given source string using all configured outline extractors.
    ///
    /// - Parameters:
    ///   - string: The full source text to analyze.
    /// - Returns: An array of `OutlineItem`.
    /// - Throws: `CancellationError`.
    func parseOutline(in string: String) async throws -> [OutlineItem] {
        
        let normalizedItems = try await withThrowingTaskGroup { [extractors, policy] group in
            for extractor in extractors {
                group.addTask { try extractor.items(in: string, range: string.range) }
            }
            
            let items = try await group.reduce(into: []) { $0 += $1 }
                .sorted(using: [KeyPathComparator(\.range.location),
                                KeyPathComparator(\.range.length)])
            
            return policy.normalize(items)
        }
        
        return self.identityResolver.resolve(normalizedItems)
            .removingDuplicateIDs
    }
}
