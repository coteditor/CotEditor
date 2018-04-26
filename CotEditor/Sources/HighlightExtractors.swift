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
//  © 2018 1024jp
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
    
    func ranges(in: String, range: NSRange) -> [NSRange]
}


extension HighlightDefinition {
    
    func extractor() throws -> HighlightExtractable {
        
        if self.isRegularExpression {
            if let endString = self.endString {
                return try BeginEndRegularExpressionExtractor(beginPattern: self.beginString, endPattern: endString, ignoresCase: self.ignoreCase)
            } else {
                return try RegularExpressionExtractor(pattern: self.beginString, ignoresCase: self.ignoreCase)
            }
        } else {
            if let endString = self.endString {
                return BeginEndStringExtractor(beginString: self.beginString, endString: endString, ignoresCase: self.ignoreCase)
            } else {
                preconditionFailure("non-regex words should be preprocessed at SyntaxStyle.init()")
            }
        }
    }
    
}



private struct BeginEndStringExtractor: HighlightExtractable {
    
    var beginString: String
    var endString: String
    var ignoresCase: Bool
    
    
    func ranges(in string: String, range: NSRange) -> [NSRange] {
        
        var ranges = [NSRange]()
        
        let scanner = Scanner(string: string)
        scanner.charactersToBeSkipped = nil
        scanner.caseSensitive = !self.ignoresCase
        scanner.scanLocation = range.location
        
        let endLength = self.endString.utf16.count
        
        while !scanner.isAtEnd && (scanner.scanLocation < range.upperBound) {
            scanner.scanUpTo(self.beginString, into: nil)
            let startLocation = scanner.scanLocation
            
            guard scanner.scanString(self.beginString, into: nil) else { break }
            guard !string.isCharacterEscaped(at: startLocation) else { continue }
            
            // find end string
            while !scanner.isAtEnd && (scanner.scanLocation < range.upperBound) {
                scanner.scanUpTo(self.endString, into: nil)
                guard scanner.scanString(self.endString, into: nil) else { break }
                
                let endLocation = scanner.scanLocation
                
                guard !string.isCharacterEscaped(at: endLocation - endLength) else { continue }
                
                ranges.append(NSRange(startLocation..<endLocation))
                
                break
            }
        }
        
        return ranges
    }
    
}



private struct RegularExpressionExtractor: HighlightExtractable {
    
    var regex: NSRegularExpression
    
    
    init(pattern: String, ignoresCase: Bool) throws {
        
        var options: NSRegularExpression.Options = .anchorsMatchLines
        if ignoresCase {
            options.update(with: .caseInsensitive)
        }
        
        self.regex = try NSRegularExpression(pattern: pattern, options: options)
    }
    
    
    func ranges(in string: String, range: NSRange) -> [NSRange] {
        
        return self.regex.matches(in: string, options: [.withTransparentBounds, .withoutAnchoringBounds], range: range).lazy
            .map { $0.range }
    }
    
}



private struct BeginEndRegularExpressionExtractor: HighlightExtractable {
    
    var beginRegex: NSRegularExpression
    var endRegex: NSRegularExpression
    
    
    init(beginPattern: String, endPattern: String, ignoresCase: Bool) throws {
        
        var options: NSRegularExpression.Options = .anchorsMatchLines
        if ignoresCase {
            options.update(with: .caseInsensitive)
        }
        
        self.beginRegex = try NSRegularExpression(pattern: beginPattern, options: options)
        self.endRegex = try NSRegularExpression(pattern: endPattern, options: options)
    }
    
    
    func ranges(in string: String, range: NSRange) -> [NSRange] {
        
        return self.beginRegex.matches(in: string, options: [.withTransparentBounds, .withoutAnchoringBounds], range: range).lazy
            .map { $0.range }
            .compactMap { beginRange in
                let endRange = self.endRegex.rangeOfFirstMatch(in: string, options: [.withTransparentBounds, .withoutAnchoringBounds],
                                                               range: NSRange(beginRange.upperBound..<range.upperBound))
                
                guard endRange.location != NSNotFound else { return nil }
                
                return beginRange.union(endRange)
        }
    }
    
}
