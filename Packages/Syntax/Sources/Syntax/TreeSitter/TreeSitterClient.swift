//
//  TreeSitterClient.swift
//  Syntax
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2025-11-02.
//
//  ---------------------------------------------------------------------------
//
//  © 2025-2026 1024jp
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

import SwiftTreeSitter
import SwiftTreeSitterLayer

actor TreeSitterClient: HighlightParsing {
    
    private let layer: LanguageLayer
    
    
    init(languageConfig: LanguageConfiguration, languageProvider: @escaping LanguageLayer.LanguageProvider) throws {
        
        self.layer = try LanguageLayer(languageConfig: languageConfig,
                                       configuration: .init(languageProvider: languageProvider))
    }
    
    
    func parseHighlights(in string: String, range: NSRange) async throws -> [Highlight] {
        
        self.layer.replaceContent(with: string)
        
        try Task.checkCancellation()
        
        return try self.layer.highlights(in: range, provider: (string as NSString).predicateNSStringProvider)
            .compactMap { namedRange in
                guard
                    let baseName = namedRange.nameComponents.first,
                    let type = SyntaxType(rawValue: baseName)
                else { return nil }
                
                return ValueRange(value: type, range: namedRange.range)
            }
            .sorted(using: [KeyPathComparator(\.range.location),
                            KeyPathComparator(\.range.length)])
    }
}


private extension NSString {
    
    var predicateNSStringProvider: SwiftTreeSitter.Predicate.TextProvider {
        
        { nsRange, _ in self.substring(with: nsRange) }
    }
}
