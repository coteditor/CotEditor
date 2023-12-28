//
//  LineSort.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-01-05.
//
//  ---------------------------------------------------------------------------
//
//  © 2018-2023 1024jp
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

enum SortPatternError: LocalizedError {
    
    case emptyPattern
    case invalidRegularExpressionPattern
    
    var errorDescription: String? {
        
        switch self {
            case .emptyPattern:
                String(localized: "Empty pattern")
            case .invalidRegularExpressionPattern:
                String(localized: "Invalid pattern")
        }
    }
}


protocol SortPattern: Equatable {
    
    func sortKey(for line: String) -> String?
    func range(for line: String) -> Range<String.Index>?
    func validate() throws
}


extension SortPattern {
    
    /// Sorts given lines with the receiver's pattern.
    ///
    /// - Parameters:
    ///   - string: The string to sort.
    ///   - options: Compare options for sort.
    /// - Returns: Sorted string.
    func sort(_ string: String, options: SortOptions = SortOptions()) -> String {
        
        guard let lineEnding = string.firstLineEnding else { return string }
        
        var lines = string.components(separatedBy: .newlines)
        let firstLine = options.keepsFirstLine ? lines.removeFirst() : nil
        
        lines = lines
            .map { (line: $0, key: self.sortKey(for: $0)) }
            .sorted {
                switch ($0.key, $1.key) {
                    case let (.some(key0), .some(key1)):
                        // sort items by evaluating values as numbers
                        // -> This code still ignores numbers in the middle of keys.
                        if let number0 = options.parse(key0),
                           let number1 = options.parse(key1),
                           number0 != number1
                        {
                            return number0 < number1
                        }
                        return key0.compare(key1, options: options.compareOptions, locale: options.usedLocale) == .orderedAscending
                        
                    case (.none, .some):
                        return false
                        
                    case (.some, .none), (.none, .none):
                        return true
                }
            }
            .map(\.line)
        
        if options.descending {
            lines.reverse()
        }
        
        if let firstLine {
            lines.insert(firstLine, at: 0)
        }
        
        return lines.joined(separator: String(lineEnding))
    }
}



// MARK: -

struct EntireLineSortPattern: SortPattern {
    
    func sortKey(for line: String) -> String? {
        
        line
    }
    
    
    func range(for line: String) -> Range<String.Index>? {
        
        line.startIndex..<line.endIndex
    }
    
    
    func validate() throws { }
}



struct CSVSortPattern: SortPattern {
    
    var delimiter: String = ","
    var column: Int = 1
    
    
    func sortKey(for line: String) -> String? {
        
        assert(self.column > 0)
        
        let delimiter = self.delimiter.isEmpty ? "," : self.delimiter.unescaped
        let index = self.column - 1  // column number is 1-based
        
        return line.components(separatedBy: delimiter)[safe: index]?
            .trimmingCharacters(in: .whitespaces)
    }
    
    
    func range(for line: String) -> Range<String.Index>? {
        
        assert(self.column > 0)
        
        let delimiter = self.delimiter.isEmpty ? "," : self.delimiter.unescaped
        let index = self.column - 1  // column number is 1-based
        let components = line.components(separatedBy: delimiter)
        
        guard let component = components[safe: index] else { return nil }
        
        let offset = components[..<index].map { $0 + delimiter }.joined().count
        let start = line.index(line.startIndex, offsetBy: offset)
        let end = line.index(start, offsetBy: component.count)
        
        // trim whitespaces
        let headTrim = component.countPrefix(while: \.isWhitespace)
        let endTrim = component.reversed().countPrefix(while: \.isWhitespace)
        let trimmedStart = line.index(start, offsetBy: headTrim)
        let trimmedEnd = line.index(end, offsetBy: -endTrim)
        
        return trimmedStart..<trimmedEnd
    }
    
    
    func validate() throws { }
}


struct RegularExpressionSortPattern: SortPattern {
    
    var searchPattern: String = ""
    var ignoresCase: Bool = true
    var usesCaptureGroup: Bool = false
    var group: Int = 1
    
    var numberOfCaptureGroups: Int  { (try? self.regex)?.numberOfCaptureGroups ?? 0 }
    
    
    func sortKey(for line: String) -> String? {
        
        guard let range = self.range(for: line) else { return nil }
        
        return String(line[range])
    }
    
    
    func range(for line: String) -> Range<String.Index>? {
        
        guard
            let regex = try? self.regex,
            let match = regex.firstMatch(in: line, range: line.nsRange)
        else { return nil }
        
        if self.usesCaptureGroup {
            guard match.numberOfRanges > self.group else { return nil }
            return Range(match.range(at: self.group), in: line)
        } else {
            return Range(match.range, in: line)
        }
    }
    
    
    /// Tests the regular expression pattern is valid.
    func validate() throws {
        
        if self.searchPattern.isEmpty {
            throw SortPatternError.emptyPattern
        }
        
        do {
            _ = try self.regex
        } catch {
            throw SortPatternError.invalidRegularExpressionPattern
        }
    }
    
    
    private var regex: NSRegularExpression? {
        
        get throws {
            try NSRegularExpression(pattern: self.searchPattern, options: self.ignoresCase ? [.caseInsensitive] : [])
        }
    }
}



// MARK: -

struct SortOptions: Equatable {
    
    var ignoresCase: Bool = true
    var numeric: Bool = true
    
    var isLocalized: Bool = true
    var keepsFirstLine: Bool = false
    var descending: Bool = false
    
    var locale: Locale = .current  // open for unit test
    
    
    var compareOptions: String.CompareOptions {
        
        .forcedOrdering
            .union(self.ignoresCase ? .caseInsensitive : [])
            .union(self.numeric ? .numeric : [])
    }
    
    
    var usedLocale: Locale? {
        
        self.isLocalized ? self.locale : nil
    }
    
    
    /// Interprets the given string as numeric value using the receiver's parsing strategy.
    ///
    /// If the receiver's `.numeric` property is `false`, it certainly returns `nil`.
    ///
    /// - Parameter value: The string to parse.
    /// - Returns: The numerical value or `nil` if failed.
    func parse(_ value: String) -> Double? {
        
        guard self.numeric else { return nil }
        
        let locale = self.usedLocale ?? .init(identifier: "en")
        let numberParser = FloatingPointFormatStyle<Double>(locale: locale).parseStrategy
        
        return try? numberParser.parse(value)
    }
}
