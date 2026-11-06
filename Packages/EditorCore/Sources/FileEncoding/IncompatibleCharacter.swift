//
//  IncompatibleCharacter.swift
//  FileEncoding
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-05-28.
//
//  ---------------------------------------------------------------------------
//
//  © 2004-2007 nakamuxu
//  © 2014-2026 1024jp
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

public import Foundation
public import ValueRange

public struct IncompatibleCharacter: Hashable, Sendable {
    
    public var character: Character
    public var converted: String?
    
    
    /// Creates a new `IncompatibleCharacter` instance.
    ///
    /// - Parameters:
    ///   - character: The incompatible character. Pass `nil` to use U+FFFD.
    ///   - converted: The conversion result, or `nil` if conversion failed.
    public init(character: Character?, converted: String?) {
        
        self.character = character ?? Character("\u{FFFD}")  // � REPLACEMENT CHARACTER
        self.converted = converted
    }
}


public extension NSString {
    
    /// Lists characters that don’t round-trip under the passed-in encoding.
    ///
    /// It detects both:
    /// - characters that cannot be encoded (lossy replacement occurs)
    /// - characters that can be encoded but change to a different character after round-trip (e.g., Shift-JIS "\" -> "＼")
    ///
    /// - Parameters:
    ///   - encoding: The string encoding to test compatibility.
    /// - Returns: An array of `ValueRange<IncompatibleCharacter>`.
    /// - Throws: `CancellationError` if the task is cancelled.
    func charactersIncompatible(with encoding: String.Encoding) throws(CancellationError) -> [ValueRange<IncompatibleCharacter>] {
        
        guard self.length > 0 else { return [] }
        
        var results: [ValueRange<IncompatibleCharacter>] = []
        results.reserveCapacity(64)
        
        let chunkLength = 1024 * 8
        var location = 0
        
        // check compatibility chunk by chunk
        while location < self.length {
            guard !Task.isCancelled else { throw CancellationError() }
            
            let length = min(chunkLength, self.length - location)
            let rawRange = NSRange(location: location, length: length)
            
            // -> Keep the lower bound since the previous chunk has already covered the characters before it.
            let upperBound = self.rangeOfComposedCharacterSequences(for: rawRange).upperBound
            let range = NSRange(location..<max(upperBound, rawRange.upperBound))
            
            results.append(contentsOf: try self.findIncompatibles(in: range, encoding: encoding))
            
            location = range.upperBound
        }
        
        return results
    }
}


private extension NSString {
    
    /// Recursively searches the given subrange for incompatible characters.
    ///
    /// - Parameters:
    ///   - range: The range to inspect for incompatibility.
    ///   - encoding: The encoding to check.
    /// - Returns: An array of value/range pairs for each incompatible character found.
    /// - Throws: `CancellationError` if the task is cancelled.
    func findIncompatibles(in range: NSRange, encoding: String.Encoding) throws(CancellationError) -> [ValueRange<IncompatibleCharacter>] {
        
        guard !Task.isCancelled else { throw CancellationError() }
        
        var converted = self.roundTrip(in: range, encoding: encoding)
        let originalChunk = self.substring(with: range)
        
        // -> Use strict comparison instead of `==` to detect Unicode-normalized conversions.
        // -> `String.compare(_:options: .literal)` is significantly slower here than
        //    `NSString.isEqual(to:)`, which provides the same strict equality.
        if let converted, (converted as NSString).isEqual(to: originalChunk) { return [] }
        
        // split and recurse
        guard let split = self.composedCharacterBoundary(in: range) else {
            // -> Saving replaces the yen signs that the encoding cannot represent in advance.
            if originalChunk.unicodeScalars.contains("¥") {
                let saved = originalChunk.convertYenSign(for: encoding) as NSString
                converted = saved.roundTrip(in: NSRange(0..<saved.length), encoding: encoding)
            }
            
            let incompatible = IncompatibleCharacter(character: originalChunk.first, converted: converted)
            
            return [ValueRange(value: incompatible, range: range)]
        }
        
        return try self.findIncompatibles(in: NSRange(range.lowerBound..<split), encoding: encoding)
            + self.findIncompatibles(in: NSRange(split..<range.upperBound), encoding: encoding)
    }
    
    
    /// Attempts a lossy round-trip conversion of the substring in `range` using the given encoding, without using `Data`.
    ///
    /// Encode range -> bytes (lossy allowed), then decode bytes -> String (same encoding).
    ///
    /// - Parameters:
    ///   - range: The range of the string to convert.
    ///   - encoding: The encoding to use.
    /// - Returns: The decoded string after round-trip, or `nil` if it could not be produced.
    func roundTrip(in range: NSRange, encoding: String.Encoding) -> String? {
        
        var capacity = max(256, range.length * 8)  // heuristic
        let maxCapacity = 4 * 1024 * 1024  // 4MB cap for a single chunk
        
        while capacity <= maxCapacity {
            var needsMoreCapacity = false
            let decoded = withUnsafeTemporaryAllocation(of: UInt8.self, capacity: capacity) { buffer -> String? in
                var usedLength = 0
                var remaining = NSRange(location: NSNotFound, length: 0)
                
                guard unsafe self.getBytes(buffer.baseAddress, maxLength: buffer.count, usedLength: &usedLength, encoding: encoding.rawValue, options: .allowLossy, range: range, remaining: &remaining) else { return nil }
                
                if remaining.length > 0 {
                    needsMoreCapacity = true
                    return nil
                }
                
                // decode back
                guard let decoded = unsafe NSString(bytes: buffer.baseAddress!, length: usedLength, encoding: encoding.rawValue) else { return nil }
                
                return decoded as String
            }
            
            guard needsMoreCapacity else { return decoded }
            
            // grow and retry, as buffer was too small
            capacity *= 2
        }
        
        return nil  // -> Buffer growth cap was reached.
    }
    
    
    /// Finds a composed character boundary near the middle of the given range.
    ///
    /// - Parameters:
    ///   - range: The range to split.
    /// - Returns: A location strictly inside the range, or `nil` if the first composed character sequence reaches the end of the range.
    func composedCharacterBoundary(in range: NSRange) -> Int? {
        
        // workaround the issue that `rangeOfComposedCharacterSequence(at:)` can return different ranges
        // for the indexes in a sequence (2026-11, macOS 27)
        // -> Take a location inside the range without expanding it so that the recursion always narrows the range.
        let first = self.rangeOfComposedCharacterSequence(at: range.location)
        
        guard first.upperBound < range.upperBound else { return nil }
        
        let middle = self.rangeOfComposedCharacterSequence(at: range.location + range.length / 2)
        
        return [middle.upperBound, middle.lowerBound]
            .first { range.lowerBound < $0 && $0 < range.upperBound } ?? first.upperBound
    }
}
