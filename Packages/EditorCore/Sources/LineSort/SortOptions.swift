//
//  SortOptions.swift
//  LineSort
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-06-27.
//
//  ---------------------------------------------------------------------------
//
//  © 2018-2024 1024jp
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

public struct SortOptions: Equatable, Sendable {
    
    public var ignoresCase: Bool
    public var numeric: Bool
    
    public var isLocalized: Bool
    public var keepsFirstLine: Bool
    public var descending: Bool
    
    var locale: Locale
    
    public init(ignoresCase: Bool = true, numeric: Bool = true, isLocalized: Bool = true, keepsFirstLine: Bool = false, descending: Bool = false, locale: Locale = .current) {
        
        self.ignoresCase = ignoresCase
        self.numeric = numeric
        self.isLocalized = isLocalized
        self.keepsFirstLine = keepsFirstLine
        self.descending = descending
        self.locale = locale
    }
    
    
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
    /// - Returns: The numeric value or `nil` if failed.
    func parse(_ value: String) -> Double? {
        
        guard self.numeric else { return nil }
        
        let locale = self.usedLocale ?? .init(identifier: "en")
        let numberParser = FloatingPointFormatStyle<Double>(locale: locale).parseStrategy
        
        return try? numberParser.parse(value)
    }
}
