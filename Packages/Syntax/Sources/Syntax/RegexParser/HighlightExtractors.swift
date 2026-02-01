//
//  HighlightExtractors.swift
//  Syntax
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-04-30.
//
//  ---------------------------------------------------------------------------
//
//  © 2018-2026 1024jp
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

protocol HighlightExtractable: Sendable, Equatable {
    
    func ranges(in string: String, range: NSRange) throws -> [NSRange]
}


extension Syntax.Highlight {
    
    var extractor: any HighlightExtractable {
        
        get throws {
            switch (self.isRegularExpression, self.end) {
                case (true, .some(let end)):
                    try BeginEndRegularExpressionExtractor(beginPattern: self.begin, endPattern: end, ignoresCase: self.ignoreCase, isMultiline: self.isMultiline)
                    
                case (true, .none):
                    try RegularExpressionExtractor(pattern: self.begin, ignoresCase: self.ignoreCase, isMultiline: self.isMultiline)
                    
                case (false, .some(let end)):
                    BeginEndStringExtractor(begin: self.begin, end: end, ignoresCase: self.ignoreCase, isMultiline: self.isMultiline)
                    
                case (false, .none):
                    preconditionFailure("non-regex words should be preprocessed at Syntax.init()")
            }
        }
    }
}


struct BeginEndStringExtractor: HighlightExtractable {
    
    private var begin: String
    private var end: String
    private var options: String.CompareOptions
    private var isMultiline: Bool
    
    
    init(begin: String, end: String, ignoresCase: Bool, isMultiline: Bool) {
        
        self.begin = begin
        self.end = end
        self.options = ignoresCase ? [.literal, .caseInsensitive] : [.literal]
        self.isMultiline = isMultiline
    }
    
    
    func ranges(in string: String, range: NSRange) throws -> [NSRange] {
        
        var ranges: [NSRange] = []
        
        var location = range.lowerBound
        while location != NSNotFound {
            // find start string
            let beginRange = (string as NSString).range(of: self.begin, options: self.options, range: NSRange(location..<range.upperBound))
            location = beginRange.upperBound
            
            guard beginRange.location != NSNotFound else { break }
            
            // find end string
            let upperBound = self.isMultiline
                ? range.upperBound
                : min(range.upperBound, (string as NSString).lineContentsEndIndex(at: beginRange.upperBound))
            let endRange = (string as NSString).range(of: self.end, options: self.options, range: NSRange(location..<upperBound))
            location = endRange.upperBound
            
            guard endRange.location != NSNotFound else { continue }
            
            ranges.append(NSRange(beginRange.lowerBound..<endRange.upperBound))
            
            try Task.checkCancellation()
        }
        
        return ranges
    }
}


struct RegularExpressionExtractor: HighlightExtractable {
    
    private var regex: NSRegularExpression
    
    
    init(pattern: String, ignoresCase: Bool, isMultiline: Bool) throws {
        
        let options: NSRegularExpression.Options = .anchorsMatchLines
            .union(ignoresCase ? .caseInsensitive : [])
            .union(isMultiline ? .dotMatchesLineSeparators : [])
        
        self.regex = try NSRegularExpression(pattern: pattern, options: options)
    }
    
    
    func ranges(in string: String, range: NSRange) throws -> [NSRange] {
        
        try self.regex.cancellableMatches(in: string, options: [.withTransparentBounds, .withoutAnchoringBounds], range: range)
            .map(\.range)
    }
}


struct BeginEndRegularExpressionExtractor: HighlightExtractable {
    
    private var beginRegex: NSRegularExpression
    private var endRegex: NSRegularExpression
    private var isMultiline: Bool
    
    
    init(beginPattern: String, endPattern: String, ignoresCase: Bool, isMultiline: Bool) throws {
        
        let options: NSRegularExpression.Options = .anchorsMatchLines
            .union(ignoresCase ? .caseInsensitive : [])
        
        self.beginRegex = try NSRegularExpression(pattern: beginPattern, options: options)
        self.endRegex = try NSRegularExpression(pattern: endPattern, options: options)
        self.isMultiline = isMultiline
    }
    
    
    func ranges(in string: String, range: NSRange) throws -> [NSRange] {
        
        let options: NSRegularExpression.MatchingOptions = [.withTransparentBounds, .withoutAnchoringBounds]
        
        var ranges: [NSRange] = []
        var location = range.lowerBound
        
        while location < range.upperBound {
            // find start pattern
            let beginRange = self.beginRegex.rangeOfFirstMatch(in: string, options: options, range: NSRange(location..<range.upperBound))
            
            guard beginRange.location != NSNotFound else { break }
            
            // -> forwarding-guarantee in case beginRegex may match zero characters
            let searchStartIndex = max(beginRange.upperBound, beginRange.location + 1)
            
            let upperBound = self.isMultiline
                ? range.upperBound
                : min(range.upperBound, (string as NSString).lineContentsEndIndex(at: beginRange.upperBound))
            
            // find end pattern
            let endRange = self.endRegex.rangeOfFirstMatch(in: string, options: options, range: NSRange(searchStartIndex..<upperBound))
            
            guard endRange.location != NSNotFound else {
                location = searchStartIndex
                continue
            }
            
            location = max(endRange.upperBound, endRange.location + 1)
            
            ranges.append(beginRange.union(endRange))
            
            try Task.checkCancellation()
        }
        
        return ranges
    }
}
