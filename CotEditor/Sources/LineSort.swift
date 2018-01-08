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

protocol SortPattern: class {
    
    func sortKey(for line: String) -> String?
    func range(for line: String) -> Range<String.Index>?
    func validate() throws
}


extension SortPattern {
    
    /// Sort given lines with the receiver's parttern.
    ///
    /// When .widthInsensitive is specified in `options`, Hiragana/Katakana difference is also ignored.
    ///
    /// - Parameters:
    ///   - string: The string to sort.
    ///   - options: Compare options for sort.
    /// - Returns: Sorted string.
    func sort(_ string: String, options: SortOptions = SortOptions()) -> String {
        
        let compareOptions = options.compareOptions
        
        var lines = string.components(separatedBy: .newlines)
            .map { (line: String) -> (line: String, key: String?) in
                var key = self.sortKey(for: line)
                if compareOptions.contains(.widthInsensitive) {
                    key = key?.applyingTransform(.hiraganaToKatakana, reverse: false) ?? key
                }
                return (line: line, key: key)
            }
            .sorted {
                switch ($0.key, $1.key) {
                case let (.some(key0), .some(key1)):
                    let result: ComparisonResult = {
                        if options.localized, options.ignoresCase {
                            return key0.localizedCaseInsensitiveCompare(key1)
                        } else if options.localized {
                            return key0.localizedCompare(key1)
                        } else {
                            return key0.compare(key1, options: compareOptions)
                        }
                    }()
                    return result == .orderedAscending
                case (.none, .some):
                    return false
                default:
                    return true
                }
            }
            .map { $0.line }
        
        if options.decending {
            lines.reverse()
        }
        
        return lines.joined(separator: "\n")
    }
    
}



// MARK: -

final class EntireLineSortPattern: NSObject, SortPattern {
    
    func sortKey(for line: String) -> String? {
        
        return line
    }
    
    
    func range(for line: String) -> Range<String.Index>? {
        
        return line.startIndex..<line.endIndex
    }
    
    
    func validate() throws { }
}



final class CSVSortPattern: NSObject, SortPattern {
    
    @objc dynamic var delimiter: String = ","
    @objc dynamic var column: Int = 1
    
    
    func sortKey(for line: String) -> String? {
        
        let delimiter = self.delimiter.isEmpty ? "," : self.delimiter.unescaped
        let index = self.column - 1  // column number is 1-based
        
        return line.components(separatedBy: delimiter)[safe: index]?
            .trimmingCharacters(in: .whitespaces)
    }
    
    
    func range(for line: String) -> Range<String.Index>? {
        
        let delimiter = self.delimiter.isEmpty ? "," : self.delimiter.unescaped
        let components = line.components(separatedBy: delimiter)
        
        guard components.count >= self.column else { return nil }
        
        var start = line.startIndex
        var end = line.endIndex
        var range = start..<end
        for (index, component) in components.enumerated() {
            guard index != self.column else { break }
            
            if index > 0 {
                start = line.index(end, offsetBy: delimiter.count)
            }
            end = line.index(start, offsetBy: component.count)
            
            range = start..<end
            if let trimmedStart = component.index(where: { $0 != " " }) {
                let offset = component.distance(from: component.startIndex, to: trimmedStart)
                range = line.index(start, offsetBy: offset)..<range.upperBound
            }
            if let trimmedEnd = component.reversed().index(where: { $0 != " " }) {
                let offset = component.distance(from: component.startIndex, to: trimmedEnd.base)
                range = range.lowerBound..<line.index(start, offsetBy: offset)
            }
        }
        
        return range
    }
    
    
    func validate() throws { }
}


final class RegularExpressionSortPattern: NSObject, SortPattern {
    
    @objc dynamic var searchPattern: String = ""
    @objc dynamic var ignoresCase: Bool = true
    @objc dynamic var usesCapturedGroup: Bool = false
    @objc dynamic var group: Int = 1
    
    
    private var regex: NSRegularExpression?
    
    
    func sortKey(for line: String) -> String? {
        
        guard let range = self.range(for: line) else { return nil }
        
        return String(line[range])
    }
    
    
    func range(for line: String) -> Range<String.Index>? {
        
        if self.regex == nil {
            try? self.validate()
        }
        
        guard
            let regex = self.regex,
            let match = regex.firstMatch(in: line, range: line.nsRange)
            else { return nil }
        
        if self.usesCapturedGroup {
            guard match.numberOfRanges > self.group else { return nil }
            return Range(match.range(at: self.group), in: line)!
        } else {
            return Range(match.range, in: line)!
        }
    }
    
    
    /// test regex pattern is valid
    func validate() throws {
        
        self.regex = nil
        
        let options: NSRegularExpression.Options = self.ignoresCase ? [.caseInsensitive] : []
        
        self.regex = try NSRegularExpression(pattern: self.searchPattern, options: options)
    }
    
}



// MARK: -

final class SortOptions: NSObject {
    
    @objc dynamic var ignoresCase: Bool = true
    @objc dynamic var numeric: Bool = true
    
    @objc dynamic var localized: Bool = true
    @objc dynamic var decending: Bool = false
    
    
    var compareOptions: String.CompareOptions {
        
        var options: String.CompareOptions = [.forcedOrdering]
        
        if self.ignoresCase {
            options.formUnion(.caseInsensitive)
        }
        if self.numeric {
            options.formUnion(.numeric)
        }
        
        return options
    }
    
}
