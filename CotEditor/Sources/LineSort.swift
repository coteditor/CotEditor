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
//  © 2018-2020 1024jp
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

protocol SortPattern: AnyObject {
    
    func sortKey(for line: String) -> String?
    func range(for line: String) -> Range<String.Index>?
    func validate() throws
}


extension SortPattern {
    
    /// Sort given lines with the receiver's parttern.
    ///
    /// - Parameters:
    ///   - string: The string to sort.
    ///   - options: Compare options for sort.
    /// - Returns: Sorted string.
    func sort(_ string: String, options: SortOptions = SortOptions()) -> String {
        
        let compareOptions = options.compareOptions
        
        var lines = string.components(separatedBy: .newlines)
        let firstLine = options.keepsFirstLine ? lines.removeFirst() : nil
        
        lines = lines
            .map { (line: $0, key: self.sortKey(for: $0)) }
            .sorted {
                switch ($0.key, $1.key) {
                    case let (.some(key0), .some(key1)):
                        return key0.compare(key1, options: compareOptions, locale: options.locale) == .orderedAscending
                    case (.none, .some):
                        return false
                    case (.some, .none), (.none, .none):
                        return true
                }
            }
            .map(\.line)
        
        if options.decending {
            lines.reverse()
        }
        
        if let firstLine = firstLine {
            lines.insert(firstLine, at: 0)
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
        
        assert(self.column > 0)
        
        let delimiter = self.delimiter.isEmpty ? "," : self.delimiter.unescaped
        let index = self.column - 1  // column number is 1-based
        
        return line.components(separatedBy: delimiter)[safe: index]?
            .trimmingCharacters(in: .whitespaces)
    }
    
    
    func range(for line: String) -> Range<String.Index>? {
        
        assert(self.column > 0)
        
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
            if let trimmedStart = component.firstIndex(where: { !$0.isWhitespace }) {
                let offset = component.distance(from: component.startIndex, to: trimmedStart)
                range = line.index(start, offsetBy: offset)..<range.upperBound
            }
            if let trimmedEnd = component.lastIndex(where: { $0.isWhitespace }) {
                let offset = component.distance(from: component.startIndex, to: trimmedEnd)
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
    @objc dynamic var usesCaptureGroup: Bool = false
    @objc dynamic var group: Int = 1
    
    @objc dynamic private(set) var numberOfCaptureGroups: Int = 0
    
    
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
        
        if self.usesCaptureGroup {
            guard match.numberOfRanges > self.group else { return nil }
            return Range(match.range(at: self.group), in: line)
        } else {
            return Range(match.range, in: line)
        }
    }
    
    
    /// test regex pattern is valid
    func validate() throws {
        
        let options: NSRegularExpression.Options = self.ignoresCase ? [.caseInsensitive] : []
        let regex: NSRegularExpression
        do {
            regex = try NSRegularExpression(pattern: self.searchPattern, options: options)
        } catch {
            self.regex = nil
            self.numberOfCaptureGroups = 0
            
            throw error
        }
        
        self.regex = regex
        self.numberOfCaptureGroups = regex.numberOfCaptureGroups
    }
    
}



// MARK: -

final class SortOptions: NSObject {
    
    @objc dynamic var ignoresCase: Bool = true
    @objc dynamic var numeric: Bool = true
    
    @objc dynamic var isLocalized: Bool = true
    @objc dynamic var keepsFirstLine: Bool = false
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
    
    
    var locale: Locale? {
        
        return self.isLocalized ? .current: nil
    }
    
}
