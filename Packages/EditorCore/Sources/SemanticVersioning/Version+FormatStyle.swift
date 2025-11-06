//
//  Version+FormatStyle.swift
//  SemanticVersioning
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2025-11-05.
//
//  ---------------------------------------------------------------------------
//
//  © 2025 1024jp
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

public extension Version {
    
    struct FormatStyle: Codable, Sendable {
        
        public enum Part: Codable, Sendable {
            
            case minor
            case patch
            case prerelease
        }
        
        
        var part: Part
        
        
        init(_ part: Part = .prerelease) {
            
            self.part = part
        }
    }
}


extension Version.FormatStyle: FormatStyle {
    
    /// Formats version number.
    public func format(_ value: Version) -> String {
        
        switch self.part {
            case .minor:
                "\(value.major).\(value.minor)"
            case .patch:
                "\(value.major).\(value.minor).\(value.patch)"
            case .prerelease:
                if let prerelease = value.prereleaseIdentifier {
                    "\(value.major).\(value.minor).\(value.patch)-\(prerelease)"
                } else {
                    "\(value.major).\(value.minor).\(value.patch)"
                }
        }
    }
}


extension Version {
    
    public struct ParseStrategy: Foundation.ParseStrategy {
        
        public enum ParseError: Error {
            
            case invalidValue
        }
        
        
        /// Creates an instance of the `ParseOutput` type from `value`.
        ///
        /// - Parameter value: The string representation of `Version` instance.
        /// - Returns: A `Version` instance.
        public func parse(_ value: String) throws(ParseError) -> Version {
            
            guard let version = Version(value) else {
                throw .invalidValue
            }
            
            return version
        }
    }
}


public extension Version {
    
    /// Converts `self` to its textual representation.
    ///
    /// - Returns: String
    func formatted() -> String {
        
        Self.FormatStyle().format(self)
    }
    
    
    /// Converts `self` to another representation.
    ///
    /// - Parameter style: The format for formatting `self`.
    /// - Returns: A representations of `self` using the given `style`.
    func formatted<F: Foundation.FormatStyle>(_ style: F) -> F.FormatOutput where F.FormatInput == Self {
        
        style.format(self)
    }
}


public extension FormatStyle where Self == Version.FormatStyle {
    
    /// Format Version in String.
    static var version: Version.FormatStyle { self.version() }
    
    
    /// Formats Version in String.
    ///
    /// - Parameters:
    ///   - part: The format style.
    /// - Returns: A Version.FormatStyle.
    static func version(part: Version.FormatStyle.Part = .prerelease) -> Version.FormatStyle {
        
        Version.FormatStyle(part)
    }
}


extension Version: CustomStringConvertible {
    
    public var description: String {
        
        self.formatted()
    }
}
