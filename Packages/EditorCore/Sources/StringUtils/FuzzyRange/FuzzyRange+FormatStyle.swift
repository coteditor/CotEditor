//
//  FuzzyRange+FormatStyle.swift
//  StringUtils
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2015-12-25.
//
//  ---------------------------------------------------------------------------
//
//  © 2015-2025 1024jp
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

extension FuzzyRange {
    
    /// Gets a formatted string from a format style.
    ///
    /// - Parameter style: The fuzzy range format style.
    /// - Returns: A formatted string.
    public func formatted(_ style: FormatStyle = .init()) -> FormatStyle.FormatOutput {
        
        style.format(self)
    }
}


public extension FormatStyle where Self == FuzzyRange.FormatStyle {
    
    static var fuzzyRange: FuzzyRange.FormatStyle {
        
        FuzzyRange.FormatStyle()
    }
}


extension FuzzyRange {
    
    public struct FormatStyle: ParseableFormatStyle {
        
        public var parseStrategy: ParseStrategy {
            
            ParseStrategy()
        }
        
        
        public func format(_ value: FuzzyRange) -> String {
            
            (0...1).contains(value.length)
                ? String(value.location)
                : String(value.location) + ":" + String(value.length)
        }
        
        
        public init() { }
    }
}


extension FuzzyRange {
    
    public struct ParseStrategy: Foundation.ParseStrategy {
        
        public enum ParseError: Error {
            
            case invalidValue
        }
        
        
        /// Creates an instance of the `ParseOutput` type from `value`.
        ///
        /// - Parameter value: The string representation of `FuzzyRange` instance.
        /// - Returns: A `FuzzyRange` instance.
        public func parse(_ value: String) throws(ParseError) -> FuzzyRange {
            
            let components = value.split(separator: ":").map(String.init).map(Int.init)
            
            guard
                (1...2).contains(components.count),
                let location = components[0],
                let length = (components.count > 1) ? components[1] : 0
            else { throw .invalidValue }
            
            return FuzzyRange(location: location, length: length)
        }
    }
}
