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

public struct IncompatibleCharacter: Equatable, Hashable, Sendable {
    
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
    func charactersIncompatible(with encoding: String.Encoding) throws -> [ValueRange<IncompatibleCharacter>] {
        
        guard self.length > 0 else { return [] }
        
        var results: [ValueRange<IncompatibleCharacter>] = []
        results.reserveCapacity(64)
        
        let chunkLength = 1024 * 8
        var location = 0
        
        // check compatibility chunk by chunk
        while location < self.length {
            try Task.checkCancellation()
            
            let length = min(chunkLength, self.length - location)
            let rawRange = NSRange(location: location, length: length)
            let range = self.rangeOfComposedCharacterSequences(for: rawRange)
            
            // avoid infinite loop
            guard range.length > 0 else {
                location = max(location + length, location + 1)
                continue
            }
            
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
    func findIncompatibles(in range: NSRange, encoding: String.Encoding) throws -> [ValueRange<IncompatibleCharacter>] {
        
        assert(range == self.rangeOfComposedCharacterSequences(for: range),
               "Range is expected to be already normalized to composed boundaries.")
        
        try Task.checkCancellation()
        
        let converted = self.roundTripLossy(in: range, encoding: encoding)
        
        if let converted {
            let originalChunk = self.substring(with: range)
            guard converted != originalChunk else { return [] }
            
            if self.isSingleComposedCharacter(in: range) {
                let incompatible = IncompatibleCharacter(character: originalChunk.first, converted: converted)
                return [ValueRange(value: incompatible, range: range)]
            }
            
        } else if self.isSingleComposedCharacter(in: range) {
            let originalChunk = self.substring(with: range)
            let incompatible = IncompatibleCharacter(character: originalChunk.first, converted: nil)
            return [ValueRange(value: incompatible, range: range)]
        }
        
        // split and recurse
        let (left, right) = self.splitRangeOnComposedBoundary(in: range)
        
        var results: [ValueRange<IncompatibleCharacter>] = []
        results.reserveCapacity(8)
        
        if left.length > 0 {
            results.append(contentsOf: try self.findIncompatibles(in: left, encoding: encoding))
        }
        if right.length > 0 {
            results.append(contentsOf: try self.findIncompatibles(in: right, encoding: encoding))
        }
        
        return results
    }
    
    
    /// Attempts a lossy round-trip conversion of the substring in `range` using the given encoding, without using `Data`.
    ///
    /// - Parameters:
    ///   - range: The range of the string to convert.
    ///   - encoding: The encoding to use.
    /// - Returns: The decoded string after round-trip, or `nil` if it could not be produced.
    func roundTripLossy(in range: NSRange, encoding: String.Encoding) -> String? {
        
        // encode range -> bytes (lossy allowed), then decode bytes -> String (same encoding).
        // avoid Data by reusing a byte buffer, growing if needed.
        var capacity = max(256, range.length * 8)  // heuristic
        let maxCapacity = 4 * 1024 * 1024  // 4MB cap for a single chunk
        
        while capacity <= maxCapacity {
            var buffer = [UInt8](repeating: 0, count: capacity)
            var usedLength = 0
            var remaining: NSRange = .notFound
            
            let ok = unsafe buffer.withUnsafeMutableBytes { raw -> Bool in
                guard let base = raw.baseAddress else { return false }
                
                return unsafe self.getBytes(base, maxLength: raw.count, usedLength: &usedLength, encoding: encoding.rawValue, options: .allowLossy, range: range, remaining: &remaining)
            }
            
            guard ok else { return nil }
            
            // grow and retry, as buffer was too small
            if remaining.length > 0 {
                capacity *= 2
                continue
            }
            
            // decode back
            return unsafe buffer.withUnsafeBytes { raw -> String? in
                guard
                    let base = raw.baseAddress,
                    let decoded = unsafe NSString(bytes: base, length: usedLength, encoding: encoding.rawValue)
                else { return nil }
                
                return decoded as String
            }
        }
        
        // -> Buffer growth cap was reached.
        return nil
    }
    
    
    /// Returns `true` if the given range spans exactly one composed character sequence.
    ///
    /// - Parameters:
    ///   - range: The range to check.
    /// - Returns: `true` if the range is a single composed character sequence; otherwise, `false`.
    func isSingleComposedCharacter(in range: NSRange) -> Bool {
        
        guard range.length > 0 else { return false }
        
        let single = self.rangeOfComposedCharacterSequence(at: range.location)
        
        return single == range
    }
    
    
    /// Splits the given range roughly in half, snapping to composed character boundaries.
    ///
    /// - Parameters:
    ///   - range: The range to split.
    /// - Returns: A tuple of two ranges, left and right, such that both are on composed boundaries and together span the original range.
    func splitRangeOnComposedBoundary(in range: NSRange) -> (NSRange, NSRange) {
        
        // split near middle, then snap to composed character boundary
        let mid = range.location + (range.length / 2)
        
        // ensure mid is within bounds
        let clampedMid = min(max(mid, range.location), range.upperBound - 1)
        let midChar = self.rangeOfComposedCharacterSequence(at: clampedMid)
        
        // prefer splitting at the start of the composed character that contains mid
        var split = midChar.location
        
        // avoid empty left
        if split <= range.lowerBound {
            split = midChar.upperBound
        }
        
        // avoid empty right
        if split >= range.upperBound {
            split = midChar.lowerBound
        }
        
        // If still degenerate, force a 1-code-unit split (should be rare due to composed normalization).
        if split <= range.location || split >= range.upperBound {
            split = range.location + max(1, range.length / 2)
        }
        
        let left = NSRange(location: range.location, length: split - range.location)
        let right = NSRange(location: split, length: range.upperBound - split)
        
        return (self.rangeOfComposedCharacterSequences(for: left),
                self.rangeOfComposedCharacterSequences(for: right))
    }
}


private extension NSRange {
    
    /// A not-found value for NSRange.
    static let notFound = NSRange(location: NSNotFound, length: 0)
}
