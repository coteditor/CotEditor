//
//  Collection+String.swift
//  StringBasics
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2017-03-19.
//
//  ---------------------------------------------------------------------------
//
//  © 2017-2024 1024jp
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

// MARK: Sort

public struct StringComparisonOptions: OptionSet, Equatable, Sendable {
    
    public let rawValue: Int
    
    public static let localized       = Self(rawValue: 1 << 0)
    public static let caseInsensitive = Self(rawValue: 1 << 1)
    
    
    public init(rawValue: Int) {
        
        self.rawValue = rawValue
    }
}


public extension MutableCollection where Self: RandomAccessCollection {
    
    /// Sorts the collection in place, using the string value that the given key path refers as the comparison between elements.
    ///
    /// - Parameters:
    ///   - keyPath: The key path to the string to compare.
    ///   - options: The strategy to compare strings.
    mutating func sort(_ keyPath: KeyPath<Element, String>, options: StringComparisonOptions) {
        
        let compare = compareFunction(options: options)
        
        self.sort { compare($0[keyPath: keyPath], $1[keyPath: keyPath]) == .orderedAscending }
    }
    
    
    /// Sorts the collection, using the desired string comparison strategy.
    ///
    /// - Parameters:
    ///   - options: The strategy to compare strings.
    mutating func sort(options: StringComparisonOptions) where Element == String {
        
        let compare = compareFunction(options: options)
        
        self.sort { compare($0, $1) == .orderedAscending }
    }
}


public extension Sequence {
    
    /// Returns the elements of the sequence, sorted using the string value that the given key path refers with the desired string comparison strategy.
    ///
    /// - Parameters:
    ///   - keyPath: The key path to the string to compare.
    ///   - options: The strategy to compare strings.
    /// - Returns: A sorted array of the sequence’s elements.
    func sorted(_ keyPath: KeyPath<Element, String>, options: StringComparisonOptions) -> [Element] {
        
        let compare = compareFunction(options: options)
        
        return self.sorted { compare($0[keyPath: keyPath], $1[keyPath: keyPath]) == .orderedAscending }
    }
    
    
    /// Returns the elements of the sequence, sorted with the desired string comparison strategy.
    ///
    /// - Parameters:
    ///   - options: The strategy to compare strings.
    /// - Returns: A sorted array of the sequence’s elements.
    func sorted(options: StringComparisonOptions) -> [Element] where Element == String {
        
        let compare = compareFunction(options: options)
        
        return self.sorted { compare($0, $1) == .orderedAscending }
    }
}


private func compareFunction(options: StringComparisonOptions) -> (String, String) -> ComparisonResult {
    
    switch options {
        case [.localized, .caseInsensitive]:
            { $0.localizedCaseInsensitiveCompare($1) }
        case [.localized]:
            { $0.localizedCompare($1) }
        case [.caseInsensitive]:
            { $0.caseInsensitiveCompare($1) }
        case []:
            { $0.compare($1) }
        default:
            fatalError()
    }
}
