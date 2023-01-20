//
//  FilePermissionsFormatStyle.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2023-01-20.
//
//  ---------------------------------------------------------------------------
//
//  © 2023 1024jp
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

struct FilePermissionsFormatStyle: Codable {
    
    enum Style: Codable {
        
        /// Octal presentaion like `644`
        case octal
        
        /// Symbolic presentation like `-rw-r--r-`
        case symbolic
        
        /// Both octal and symbolic presentations like `644 (-rw-r--r-)`
        case full
    }
    
    
    var style: Style
    
    
    init(_ style: Style) {
        
        self.style = style
    }
}


extension FilePermissionsFormatStyle: FormatStyle {
    
    /// Format permission number to human readable permission expression.
    func format(_ value: UInt16) -> String {
        
        let permissions = FilePermissions(mask: value)
        
        switch self.style {
            case .octal:
                return permissions.octal
            case .symbolic:
                return "-\(permissions.symbolic)"
            case .full:
                return "\(permissions.octal) (-\(permissions.symbolic))"
        }
    }
}


extension FormatStyle where Self == FilePermissionsFormatStyle {
    
    /// Format POSIX permission mask in String.
    static var filePermissions: FilePermissionsFormatStyle { self.filePermissions() }
    
    
    /// Format POSIX permission mask in String.
    ///
    /// - Parameters:
    ///   - style: The format style.
    /// - Returns: A FilePermissionsFormatStyle.
    static func filePermissions(_ style: FilePermissionsFormatStyle.Style = .full) -> FilePermissionsFormatStyle {
        
        FilePermissionsFormatStyle(style)
    }
}
