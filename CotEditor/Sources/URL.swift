//
//  URL.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-07-03.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2022 1024jp
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

extension URL {
    
    /// Simply check the reachability of the URL by ignoring errors.
    var isReachable: Bool {
        
        (try? self.checkResourceIsReachable()) == true
    }
    
    
    /// Return relative-path string.
    ///
    /// - Parameter baseURL: The URL the relative path based on.
    /// - Returns: A path string.
    func path(relativeTo baseURL: URL?) -> String? {
        
        assert(self.isFileURL)
        assert(baseURL?.isFileURL != false)
        
        guard let baseURL = baseURL else { return nil }
        
        if baseURL == self {
            return self.lastPathComponent
        }
        
        let pathComponents = self.pathComponents
        let basePathComponents = baseURL.pathComponents
        
        let sameCount = zip(basePathComponents, pathComponents).countPrefix { $0.0 == $0.1 }
        let parentCount = basePathComponents.count - sameCount - 1
        let parentComponents = [String](repeating: "..", count: parentCount)
        let diffComponents = pathComponents[sameCount...]
        
        return (parentComponents + diffComponents).joined(separator: "/")
    }
}



// MARK: Sandboxing

extension URL {
    
    private static let homeDirectory = getpwuid(getuid())?.pointee.pw_dir.flatMap { String(cString: $0) } ?? NSHomeDirectory()
    
    
    /// A path string that replaces the user's home directory with a tilde (~) character.
    var pathAbbreviatingWithTilde: String {
        
        self.path.replacingOccurrences(of: Self.homeDirectory, with: "~", options: .anchored)
    }
}
