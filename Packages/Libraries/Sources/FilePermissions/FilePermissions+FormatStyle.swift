//
//  FilePermissions+FormatStyle.swift
//  FilePermissions
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2023-01-20.
//
//  ---------------------------------------------------------------------------
//
//  © 2023-2024 1024jp
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

public extension FilePermissions {
    
    struct FormatStyle: Codable, Sendable {
        
        public enum Style: Codable, Sendable {
            
            /// Octal presentation like `644`
            case octal
            
            /// Symbolic presentation like `-rw-r--r-`
            case symbolic
            
            /// Both octal and symbolic presentations like `644 (-rw-r--r-)`
            case full
        }
        
        
        var style: Style
        
        
        init(_ style: Style = .full) {
            
            self.style = style
        }
    }
}


extension FilePermissions.FormatStyle: FormatStyle {
    
    /// Formats permission number to human readable permission expression.
    public func format(_ value: FilePermissions) -> String {
        
        switch self.style {
            case .octal:
                value.octal
            case .symbolic:
                "-\(value.symbolic)"
            case .full:
                "\(value.octal) (-\(value.symbolic))"
        }
    }
}


public extension FilePermissions {
    
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
    func formatted<F: Foundation.FormatStyle>(_ style: F) -> F.FormatOutput where F.FormatInput == FilePermissions {
        
        style.format(self)
    }
}


public extension FormatStyle where Self == FilePermissions.FormatStyle {
    
    /// Format POSIX permission mask in String.
    static var filePermissions: FilePermissions.FormatStyle { self.filePermissions() }
    
    
    /// Formats POSIX permission mask in String.
    ///
    /// - Parameters:
    ///   - style: The format style.
    /// - Returns: A FilePermissions.FormatStyle.
    static func filePermissions(_ style: FilePermissions.FormatStyle.Style = .full) -> FilePermissions.FormatStyle {
        
        FilePermissions.FormatStyle(style)
    }
}
