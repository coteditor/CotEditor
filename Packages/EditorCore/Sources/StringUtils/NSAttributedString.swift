//
//  NSAttributedString.swift
//  StringUtils
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-07-20.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2024 1024jp
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

import Foundation.NSAttributedString

public extension NSAttributedString {
    
    /// Whole range.
    final var range: NSRange {
        
        NSRange(location: 0, length: self.length)
    }
    
    
    /// The mutable object of the receiver.
    final var mutable: NSMutableAttributedString {
     
        self.mutableCopy() as! NSMutableAttributedString
    }
    
    
    /// Concatenates attributed strings.
    static func + (lhs: NSAttributedString, rhs: NSAttributedString) -> NSAttributedString {
        
        let result = NSMutableAttributedString(attributedString: lhs)
        result.append(rhs)
        
        return result.copy() as! NSAttributedString
    }
    
    
    /// Appends another attributed string.
    static func += (lhs: inout NSAttributedString, rhs: NSAttributedString) {
        
        let result = NSMutableAttributedString(attributedString: lhs)
        result.append(rhs)
        
        lhs = result.copy() as! NSAttributedString
    }
    
    
    /// Enumerates range and value of the given temporary attribute key.
    ///
    /// - Parameters:
    ///   - attrName: The name of the temporary attribute to enumerate.
    ///   - Type:The type of the value.
    ///   - enumerationRange: The range over which the attribute values are enumerated.
    ///   - options: The options used by the enumeration. For possible values, see NSAttributedString.EnumerationOptions.
    ///   - block: A closure to apply to ranges of the specified attribute in the receiver.
    ///   - value: The value for the specified attribute.
    ///   - range: The range of the attribute value in the receiver.
    ///   - stop: A reference to a Boolean value, which you can set to true within the closure to stop further processing of the attribute enumeration.
    final func enumerateAttribute<T>(_ attrName: NSAttributedString.Key, type: T.Type, in enumerationRange: NSRange, options: EnumerationOptions = [], using block: (_ value: T, _ range: NSRange, _ stop: UnsafeMutablePointer<ObjCBool>) -> Void) {
        
        self.enumerateAttribute(attrName, in: enumerationRange, options: options) { (value, range, stop) in
            guard let value = value as? T else { return }
            block(value, range, stop)
        }
    }
    
    
    /// Checks if at least one attribute for the given attribute key exists.
    ///
    /// - Parameters:
    ///   - attrName: The name of the attribute key to check.
    ///   - range: The range where to check. When `nil`, search the entire range.
    /// - Returns: Whether the attribute for the given attribute key exists.
    final func hasAttribute(_ attrName: NSAttributedString.Key, in range: NSRange? = nil) -> Bool {
        
        guard self.length > 0 else { return false }
        
        let range = range ?? self.range
        
        assert(range.upperBound <= self.length)
        
        var effectiveRange: NSRange = .notFound
        let value = self.attribute(attrName, at: range.location, longestEffectiveRange: &effectiveRange, in: range)
        
        return value != nil || effectiveRange.upperBound < range.upperBound
    }
    
    
    /// Truncates head with an ellipsis symbol until the specific `location` if the length before the location is the longer than the `offset`.
    ///
    /// - Parameters:
    ///   - location: The character index to start truncation.
    ///   - offset: The maximum number of composed characters to leave on the left of the `location`.
    final func truncatedHead(until location: Int, offset: Int) -> NSAttributedString {
        
        let mutable = self.mutable
        mutable.truncateHead(until: location, offset: offset)
        
        return mutable
    }
}


public extension NSMutableAttributedString {
    
    /// Appends another attributed string.
    static func += (lhs: inout NSMutableAttributedString, rhs: NSAttributedString) {
        
        lhs.append(rhs)
    }
    
    
    /// Truncates head with an ellipsis symbol until the specific `location` if the length before the location is the longer than the `offset`.
    ///
    /// - Parameters:
    ///   - location: The character index to start truncation.
    ///   - offset: The maximum number of composed characters to leave on the left of the `location`.
    final func truncateHead(until location: Int, offset: Int) {
        
        assert(location >= 0)
        assert(offset >= 0)
        
        guard location > offset else { return }
        
        let truncationIndex = (self.string as NSString)
            .lowerBoundOfComposedCharacterSequence(location, offsetBy: offset)
        
        guard truncationIndex > 0 else { return }
        
        self.replaceCharacters(in: NSRange(..<truncationIndex), with: "…")
    }
}


public extension Sequence<NSAttributedString> {
    
    /// Returns a new attributed string by concatenating the elements of the sequence, adding the given separator between each element.
    ///
    /// - Parameter separator: An attributed string to insert between each of the elements in this sequence.
    /// - Returns: A single, concatenated attributed string.
    func joined(separator: Element? = nil) -> Element {
        
        let result = NSMutableAttributedString()
        var iterator = self.makeIterator()
        
        if let first = iterator.next() {
            result.append(first)
            
            while let next = iterator.next() {
                if let separator {
                    result.append(separator)
                }
                result.append(next)
            }
        }
        
        return result.copy() as! NSAttributedString
    }
    
    
    /// Returns a new attributed string by concatenating the elements of the sequence, adding the given separator between each element.
    ///
    /// - Parameter separator: A string to insert between each of the elements in this sequence.
    /// - Returns: A single, concatenated attributed string.
    func joined(separator: String) -> Element {
        
        self.joined(separator: .init(string: separator))
    }
}
