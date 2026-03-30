//
//  LicenseItem.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2025-11-02.
//
//  ---------------------------------------------------------------------------
//
//  © 2025-2026 1024jp
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

struct LicenseItem {
    
    var name: String
    var url: String
    var copyright: String
    var license: License
    var description: String?
    
    
#if SPARKLE
    static let items = Self.commonItems + [.sparkle]
#else
    static let items = Self.commonItems
#endif
    
    private static let commonItems = [
        Self(name: "swift-tree-sitter",
             url: "https://github.com/tree-sitter/swift-tree-sitter",
             copyright: "© 2021, Chime\nAll rights reserved.",
             license: .bsd3Clause),
        Self(name: "tree-sitter",
             url: "https://github.com/tree-sitter/tree-sitter",
             copyright: "© 2018-2024 Max Brunsfeld",
             license: .mit),
        Self(name: "tree-sitter-bash",
             url: "https://github.com/tree-sitter/tree-sitter-bash",
             copyright: "© 2017 Max Brunsfeld",
             license: .mit),
        Self(name: "tree-sitter-c",
             url: "https://github.com/tree-sitter/tree-sitter-c",
             copyright: "© 2014 Max Brunsfeld",
             license: .mit),
        Self(name: "tree-sitter-c-sharp",
             url: "https://github.com/tree-sitter/tree-sitter-c-sharp",
             copyright: "© 2014-2023 Max Brunsfeld, Damien Guard, Amaan Qureshi, and contributors",
             license: .mit),
        Self(name: "tree-sitter-css",
             url: "https://github.com/tree-sitter/tree-sitter-css",
             copyright: "© 2018 Max Brunsfeld",
             license: .mit),
        Self(name: "tree-sitter-cpp",
             url: "https://github.com/tree-sitter/tree-sitter-cpp",
             copyright: "© 2014 Max Brunsfeld",
             license: .mit),
        Self(name: "tree-sitter-go",
             url: "https://github.com/tree-sitter/tree-sitter-go",
             copyright: "© 2014 Max Brunsfeld",
             license: .mit),
        Self(name: "tree-sitter-html",
             url: "https://github.com/tree-sitter/tree-sitter-html",
             copyright: "© 2014 Max Brunsfeld",
             license: .mit),
        Self(name: "tree-sitter-java",
             url: "https://github.com/tree-sitter/tree-sitter-java",
             copyright: "© 2017 Ayman Nadeem",
             license: .mit),
        Self(name: "tree-sitter-javascript",
             url: "https://github.com/tree-sitter/tree-sitter-javascript",
             copyright: "© 2014 Max Brunsfeld",
             license: .mit),
        Self(name: "tree-sitter-kotlin",
             url: "https://github.com/fwcd/tree-sitter-kotlin",
             copyright: "© 2019 fwcd",
             license: .mit),
        Self(name: "tree-sitter-latex",
             url: "https://github.com/latex-lsp/tree-sitter-latex",
             copyright: "© 2021 Patrick Förster",
             license: .mit),
        Self(name: "tree-sitter-lua",
             url: "https://github.com/tree-sitter-grammars/tree-sitter-lua",
             copyright: "© 2021 Munif Tanjim",
             license: .mit),
        Self(name: "tree-sitter-make",
             url: "https://github.com/tree-sitter-grammars/tree-sitter-make",
             copyright: "© 2021 Alexandre A. Muller",
             license: .mit),
        Self(name: "tree-sitter-php",
             url: "https://github.com/tree-sitter/tree-sitter-php",
             copyright: """
                        © 2017 Josh Vera, GitHub
                        © 2019 Max Brunsfeld, Amaan Qureshi, Christian Frøystad, Caleb White
                        """,
             license: .mit),
        Self(name: "tree-sitter-markdown",
             url: "https://github.com/tree-sitter-grammars/tree-sitter-markdown",
             copyright: "© 2021 2021 Matthias Deiml",
             license: .mit),
        Self(name: "tree-sitter-python",
             url: "https://github.com/tree-sitter/tree-sitter-python",
             copyright: "© 2016 Max Brunsfeld",
             license: .mit),
        Self(name: "tree-sitter-ruby",
             url: "https://github.com/tree-sitter/tree-sitter-ruby",
             copyright: "© 2016 Rob Rix",
             license: .mit),
        Self(name: "tree-sitter-rust",
             url: "https://github.com/tree-sitter/tree-sitter-rust",
             copyright: "© 2017 Maxim Sokolov",
             license: .mit),
        Self(name: "tree-sitter-scala",
             url: "https://github.com/alex-pinkus/tree-sitter-scala",
             copyright: "© 2018 Max Brunsfeld and GitHub",
             license: .mit),
        Self(name: "tree-sitter-sql",
             url: "https://github.com/DerekStride/tree-sitter-sql",
             copyright: "© 2021 Derek Stride",
             license: .mit),
        Self(name: "tree-sitter-swift",
             url: "https://github.com/alex-pinkus/tree-sitter-swift",
             copyright: "© 2021 alex-pinkus",
             license: .mit),
        Self(name: "tree-sitter-typescript",
             url: "https://github.com/tree-sitter/tree-sitter-typescript",
             copyright: "© 2017 Max Brunsfeld",
             license: .mit),
        Self(name: "Yams",
             url: "https://github.com/jpsim/Yams",
             copyright: "© 2016 JP Simard",
             license: .mit),
        Self(name: "WFColorCode",
             url: "https://github.com/1024jp/WFColorCode",
             copyright: "© 2014-2024 1024jp",
             license: .mit),
    ]
    
    private static let sparkle = Self(
        name: "Sparkle",
        url: "https://sparkle-project.org",
        copyright: """
                                    © 2006-2013 Andy Matuschak.
                                    © 2009-2013 Elgato Systems GmbH.
                                    © 2011-2014 Kornel Lesiński.
                                    © 2015-2017 Mayur Pawashe.
                                    © 2014 C.W. Betts.
                                    © 2014 Petroules Corporation.
                                    © 2014 Big Nerd Ranch.
                                    All rights reserved.
                                    """,
        license: .custom("Sparkle"),
        description: String(localized: "only on non-AppStore version", table: "About",
                            comment: "annotation for the Sparkle framework license")
    )
}


enum License {
    
    case mit
    case bsd3Clause
    case custom(String)
    
    
    /// The name of the license.
    var name: String? {
        
        switch self {
            case .mit: "MIT license"
            case .bsd3Clause: "BSD 3-Clause License"
            case .custom: nil
        }
    }
    
    
    /// Full license text.
    ///
    /// - Throws: `CocoaError(.fileReadNoSuchFile)` if the custom license resource cannot be found.
    var content: String {
        
        get throws {
            switch self {
                case .mit:
                """
                Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
                
                The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
                
                THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
                """
                   
                case .bsd3Clause:
                """
                Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
                
                1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
                
                2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
                
                3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
                
                THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
                """
                    
                case .custom(let name):
                    try Self.load(name: name)
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
}
