//
//  HighlightExtractors.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-04-30.
//
//  ---------------------------------------------------------------------------
//
//  © 2018-2022 1024jp
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

protocol HighlightExtractable {
    
    func ranges(in: String, range: NSRange) async throws -> [NSRange]
}


extension HighlightDefinition {
    
    func extractor() throws -> HighlightExtractable {
        
        switch (self.isRegularExpression, self.endString) {
            case (true, .some(let endString)):
                return try BeginEndRegularExpressionExtractor(beginPattern: self.beginString, endPattern: endString, ignoresCase: self.ignoreCase)
            
            case (true, .none):
                return try RegularExpressionExtractor(pattern: self.beginString, ignoresCase: self.ignoreCase)
            
            case (false, .some(let endString)):
                return BeginEndStringExtractor(beginString: self.beginString, endString: endString, ignoresCase: self.ignoreCase)
            
            case (false, .none):
                preconditionFailure("non-regex words should be preprocessed at SyntaxStyle.init()")
            
        }
    }
    
}



private struct BeginEndStringExtractor: HighlightExtractable {
    
    var beginString: String
    var endString: String
    var options: String.CompareOptions
    
    
    init(beginString: String, endString: String, ignoresCase: Bool) {
        
        self.beginString = beginString
        self.endString = endString
        self.options = ignoresCase ? [.literal, .caseInsensitive] : [.literal]
    }
    
    
    func ranges(in string: String, range: NSRange) async throws -> [NSRange] {
        
        var ranges: [NSRange] = []
        
        var location = range.lowerBound
        while location != NSNotFound {
            // find start string
            let beginRange = (string as NSString).range(of: self.beginString, options: self.options, range: NSRange(location..<range.upperBound))
            location = beginRange.upperBound
            
            guard beginRange.location != NSNotFound else { break }
            guard !string.isCharacterEscaped(at: beginRange.lowerBound) else { continue }
            
            while location != NSNotFound {
                // find end string
                let endRange = (string as NSString).range(of: self.endString, options: self.options, range: NSRange(location..<range.upperBound))
                location = endRange.upperBound
                
                guard endRange.location != NSNotFound else { break }
                guard !string.isCharacterEscaped(at: endRange.lowerBound) else { continue }
                
                ranges.append(NSRange(beginRange.lowerBound..<endRange.upperBound))
                
                break
            }
            
            try Task.checkCancellation()
        }
        
        return ranges
    }
    
}



private struct RegularExpressionExtractor: HighlightExtractable {
    
    private var regex: NSRegularExpression
    
    
    init(pattern: String, ignoresCase: Bool) throws {
        
        var options: NSRegularExpression.Options = .anchorsMatchLines
        if ignoresCase {
            options.formUnion(.caseInsensitive)
        }
        
        self.regex = try NSRegularExpression(pattern: pattern, options: options)
    }
    
    
    func ranges(in string: String, range: NSRange) async throws -> [NSRange] {
        
        try await self.regex.matches(in: string, options: [.withTransparentBounds, .withoutAnchoringBounds], range: range)
            .map(\.range)
    }
    
}



private struct BeginEndRegularExpressionExtractor: HighlightExtractable {
    
    var beginRegex: NSRegularExpression
    var endRegex: NSRegularExpression
    
    
    init(beginPattern: String, endPattern: String, ignoresCase: Bool) throws {
        
        var options: NSRegularExpression.Options = .anchorsMatchLines
        if ignoresCase {
            options.formUnion(.caseInsensitive)
        }
        
        self.beginRegex = try NSRegularExpression(pattern: beginPattern, options: options)
        self.endRegex = try NSRegularExpression(pattern: endPattern, options: options)
    }
    
    
    func ranges(in string: String, range: NSRange) async throws -> [NSRange] {
        
        try await self.beginRegex.matches(in: string, options: [.withTransparentBounds, .withoutAnchoringBounds], range: range)
            .map(\.range)
            .compactMap { beginRange in
                let endRange = self.endRegex.rangeOfFirstMatch(in: string, options: [.withTransparentBounds, .withoutAnchoringBounds],
                                                               range: NSRange(beginRange.upperBound..<range.upperBound))
                
                guard endRange.location != NSNotFound else { return nil }
                
                return beginRange.union(endRange)
            }
    }
    
}
