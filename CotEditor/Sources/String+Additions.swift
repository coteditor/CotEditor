//
//  String+Additions.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-05-27.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2019 1024jp
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

private let kMaxEscapesCheckLength = 8

extension StringProtocol where Self.Index == String.Index {

    // workaround for NSBigMutableString + range subscript bug (2019-10 Xcode 11.1)
    subscript(workaround range: Range<Index>) -> SubSequence {
        
        if #available(macOS 10.15, *) { return self[range] }
        
        guard range.upperBound == self.endIndex else { return self[range] }
        
        return (range.lowerBound == self.endIndex)
            ? self[self.endIndex...]
            : self[range.lowerBound...]
    }
    
}



extension String {
    
    /// return copied string to make sure the string is not a kind of NSMutableString.
    var immutable: String {
        
        return NSString(string: self) as String
    }
    
    
    /// unescape backslashes
    var unescaped: String {
        
        // -> According to the following sentence in the Swift 3 documentation, these are the all combinations with backslash.
        //    > The escaped special characters \0 (null character), \\ (backslash), \t (horizontal tab), \n (line feed), \r (carriage return), \" (double quote) and \' (single quote)
        let entities = ["\0": "0",
                        "\t": "t",
                        "\n": "n",
                        "\r": "r",
                        "\"": "\"",
                        "\'": "'",
                        ]
        
        return entities
            .mapValues { try! NSRegularExpression(pattern: "(?<!\\\\)(?:\\\\\\\\)*(\\\\" + $0 + ")") }
            .reduce(self) { (string, entity) in
                entity.value.matches(in: string, range: string.nsRange)
                    .map { $0.range(at: 1) }
                    .compactMap { Range($0, in: string) }
                    .reversed()
                    .reduce(string) { $0.replacingCharacters(in: $1, with: entity.key) }
            }
    }
    
}



extension StringProtocol where Self.Index == String.Index {
    
    /// range of the line containing a given index
    func lineRange(at index: Index) -> Range<Index> {
        
        return self.lineRange(for: index..<index)
    }
    
    
    /// range of the line containing a given index
    func lineContentsRange(at index: Index) -> Range<Index> {
        
        return self.lineContentsRange(for: index..<index)
    }
    
    
    /// Return line range excluding last line ending character if exists.
    ///
    /// - Parameters:
    ///   - range: A range within the receiver.
    /// - Returns: The range of characters representing the line or lines containing a given range.
    func lineContentsRange(for range: Range<Index>) -> Range<Index> {
        
        var start = self.startIndex
        var end = self.startIndex
        var contentsEnd = self.startIndex
        self.getLineStart(&start, end: &end, contentsEnd: &contentsEnd, for: range)
        
        return start..<contentsEnd
    }
    
    
    /// check if character at the index is escaped with backslash
    func isCharacterEscaped(at index: Index) -> Bool {
        
        let escapes = self[workaround: self.startIndex..<index].suffix(kMaxEscapesCheckLength).reversed().prefix { $0 == "\\" }
        
        return !escapes.count.isMultiple(of: 2)
    }
    
}



// MARK: NSRange based

extension String {
    
    /// Divide the given range into logical line contents ranges.
    ///
    /// - Parameter range: The range to divide or `nil`.
    /// - Returns: Logical line ranges.
    func lineContentsRanges(for range: NSRange? = nil) -> [NSRange] {
        
        let range = range ?? self.nsRange
        let regex = try! NSRegularExpression(pattern: "^.*", options: [.anchorsMatchLines])
        
        return regex.matches(in: self, range: range).map { $0.range }
    }
    
    
    /// check if character at the location in UTF16 is escaped with backslash
    func isCharacterEscaped(at location: Int) -> Bool {
        
        let locationIndex = String.Index(utf16Offset: location, in: self)
        
        return self.isCharacterEscaped(at: locationIndex)
    }
    
}
