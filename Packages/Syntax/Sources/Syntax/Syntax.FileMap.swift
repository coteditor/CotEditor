//
//  Syntax.FileMap.swift
//  Syntax
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-01-09.
//
//  ---------------------------------------------------------------------------
//
//  © 2026 1024jp
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

public extension Syntax.FileMap {
    
    /// Parses a shebang (#!) at the beginning of the given string and returns the interpreter name.
    ///
    /// - Parameter source: The source text to scan.
    /// - Returns: The interpreter name if found; otherwise `nil`.
    static func scanInterpreterInShebang(_ source: String) -> String? {
        
        guard
            let shebang = source.firstMatch(of: /^#!\s*(?<first>\S+)\s*(?<second>\S+)?/),
            let interpreter = shebang.first.split(separator: "/").last
        else { return nil }
        
        // use first arg if the path targets env
        if interpreter == "env", let second = shebang.second {
            return String(second)
        }
        
        return String(interpreter)
    }
}
