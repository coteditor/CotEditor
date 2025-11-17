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
//  © 2016-2025 1024jp
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

public import Foundation.NSAttributedString

public extension NSAttributedString {
    
    /// The whole range.
    final var range: NSRange {
        
        NSRange(location: 0, length: self.length)
    }
    
    
    /// A mutable copy of the receiver.
    final var mutable: NSMutableAttributedString {
     
        self.mutableCopy() as! NSMutableAttributedString
    }
    
    
    /// Concatenates two attributed strings.
    static func + (lhs: NSAttributedString, rhs: NSAttributedString) -> NSAttributedString {
        
        let result = NSMutableAttributedString(attributedString: lhs)
        result.append(rhs)
        
        return result.copy() as! NSAttributedString
    }
    
    
    /// Appends another attributed string to the left-hand value.
    static func += (lhs: inout NSAttributedString, rhs: NSAttributedString) {
        
        let result = NSMutableAttributedString(attributedString: lhs)
        result.append(rhs)
        
        lhs = result.copy() as! NSAttributedString
    }
    
    
    /// Enumerates the ranges and values for the given attribute key.
    ///
    /// - Parameters:
    ///   - attrName: The name of the attribute to enumerate.
    ///   - type: The expected value type.
    ///   - enumerationRange: The range over which to enumerate attribute values.
    ///   - options: The options used during enumeration. For possible values, see NSAttributedString.EnumerationOptions.
    ///   - block: A closure applied to each range of the specified attribute.
    ///   - value: The value for the specified attribute.
    ///   - range: The range of the attribute value in the receiver.
    ///   - stop: A reference to a Boolean value that you can set to true within the closure to stop further processing.
    final func enumerateAttribute<T>(_ attrName: NSAttributedString.Key, type: T.Type, in enumerationRange: NSRange, options: EnumerationOptions = [], using block: (_ value: T, _ range: NSRange, _ stop: UnsafeMutablePointer<ObjCBool>) -> Void) {
        
        unsafe self.enumerateAttribute(attrName, in: enumerationRange, options: options) { value, range, stop in
            guard let value = value as? T else { return }
            unsafe block(value, range, stop)
        }
    }
    
    
    /// Returns the full range over which the value of the specified attribute name is the same as at the given index.
    ///
    /// - Parameters:
    ///   - attrName: The name of an attribute.
    ///   - index: The index at which to test for `attrName`. This value must not exceed the bounds of the receiver.
    /// - Returns: The maximum range over which the attribute’s value applies, clipped to the receiver’s bounds; or `nil` if no value exists at `index`.
    func longestEffectiveRange(of attrName: NSAttributedString.Key, at index: Int) -> NSRange? {
        
        var effectiveRange = NSRange.notFound
        
        guard unsafe self.attribute(attrName, at: index, longestEffectiveRange: &effectiveRange, in: self.range) != nil else { return nil }
        
        return effectiveRange
    }
    
    
    /// Checks whether at least one attribute exists for the given attribute key.
    ///
    /// - Parameters:
    ///   - attrName: The attribute key to check.
    ///   - range: The range where to check. When `nil`, searches the entire range.
    /// - Returns: `true` if an attribute with the given key exists; otherwise, `false`.
    final func hasAttribute(_ attrName: NSAttributedString.Key, in range: NSRange? = nil) -> Bool {
        
        guard self.length > 0 else { return false }
        
        let range = range ?? self.range
        
        assert(range.upperBound <= self.length)
        
        var effectiveRange: NSRange = .notFound
        let value = unsafe self.attribute(attrName, at: range.location, longestEffectiveRange: &effectiveRange, in: range)
        
        return value != nil || effectiveRange.upperBound < range.upperBound
    }
    
    
    /// Truncates the head with an ellipsis until the specified `location` if the length before `location` exceeds `offset`.
    ///
    /// - Parameters:
    ///   - location: The character index at which truncation should start.
    ///   - offset: The maximum number of composed characters to leave to the left of `location`.
    final func truncatedHead(until location: Int, offset: Int) -> NSAttributedString {
        
        let mutable = self.mutable
        mutable.truncateHead(until: location, offset: offset)
        
        return mutable
    }
}


public extension NSMutableAttributedString {
    
    /// Appends another attributed string to the left-hand value.
    static func += (lhs: inout NSMutableAttributedString, rhs: NSAttributedString) {
        
        lhs.append(rhs)
    }
    
    
    /// Truncates the head with an ellipsis until the specified `location` if the length before `location` exceeds `offset`.
    ///
    /// - Parameters:
    ///   - location: The character index at which truncation should start.
    ///   - offset: The maximum number of composed characters to leave to the left of `location`.
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
    
    /// Returns a new attributed string by concatenating the elements of the sequence, inserting the given separator between each element.
    ///
    /// - Parameter separator: An attributed string to insert between each element of the sequence.
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
    
    
    /// Returns a new attributed string by concatenating the elements of the sequence, inserting the given separator between each element.
    ///
    /// - Parameter separator: A string to insert between each element of the sequence.
    /// - Returns: A single, concatenated attributed string.
    func joined(separator: String) -> Element {
        
        self.joined(separator: .init(string: separator))
    }
}
