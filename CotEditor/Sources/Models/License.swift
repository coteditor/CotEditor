//
//  License.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2025-11-02.
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

import Foundation

enum License {
    
    case mit(copyright: String)
    case custom(license: String, filename: String)
    
    
    /// The name of the license.
    var name: String {
        
        switch self {
            case .mit: "MIT license"
            case .custom(let license, _): license
        }
    }
    
    
    /// Full license text.
    ///
    /// - Throws: `CocoaError(.fileReadNoSuchFile)` if the custom license resource cannot be found.
    var content: String {
        
        get throws {
            switch self {
                case .mit(let copyright):
                    copyright + "\n\n" + self.boilerplate
                case .custom(_, let content):
                    try Self.load(name: content)
            }
        }
    }
    
    
    /// Loads a text resource from the app bundle under the `Licenses` subdirectory.
    ///
    /// - Parameter name: Filename without extension.
    /// - Returns: The file content as a `String`.
    /// - Throws: `CocoaError(.fileReadNoSuchFile)` if the resource is missing, or file read errors.
    private static func load(name: String) throws -> String {
        
        guard let url = Bundle.main.url(forResource: name, withExtension: "txt", subdirectory: "Licenses") else {
            throw CocoaError(.fileReadNoSuchFile)
        }
        return try String(contentsOf: url, encoding: .utf8)
    }
    
    
    /// The license boilerplate text.
    private var boilerplate: String {
        
        switch self {
            case .mit:
                """
                Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
                
                The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
                
                THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
                """
                
            case .custom:
                fatalError()
        }
    }
}
