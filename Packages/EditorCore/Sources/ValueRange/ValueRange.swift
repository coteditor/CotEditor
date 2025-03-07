//
//  ValueRange.swift
//  ValueRange
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2022-04-16.
//
//  ---------------------------------------------------------------------------
//
//  © 2022-2024 1024jp
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

import struct Foundation.NSRange

public struct ValueRange<Value> {
    
    public var value: Value
    public var range: NSRange
    
    public var lowerBound: Int  { self.range.lowerBound }
    public var upperBound: Int  { self.range.upperBound }
    
    
    public init(value: Value, range: NSRange) {
        
        self.value = value
        self.range = range
    }
    
    
    /// Returns a copy by shifting the range location toward the given offset.
    ///
    /// - Parameter offset: The offset to shift.
    /// - Returns: A new ValueRange.
    public func shifted(by offset: Int) -> Self {
        
        Self(value: self.value, range: self.range.shifted(by: offset))
    }
    
    
    /// Shifts the range location toward the given offset.
    ///
    /// - Parameter offset: The offset to shift.
    public mutating func shift(by offset: Int) {
        
        self.range.location += offset
    }
}


extension ValueRange: Equatable where Value: Equatable { }
extension ValueRange: Hashable where Value: Hashable { }
extension ValueRange: Sendable where Value: Sendable { }


// MARK: - Private

private extension NSRange {
    
    /// Returns a copied NSRange but whose location is shifted toward the given `offset`.
    ///
    /// - Parameter offset: The offset to shift.
    /// - Returns: A new NSRange.
    func shifted(by offset: Int) -> NSRange {
        
        NSRange(location: self.location + offset, length: self.length)
    }
}
