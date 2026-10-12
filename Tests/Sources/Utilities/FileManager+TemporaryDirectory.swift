//
//  FileManager+TemporaryDirectory.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-10-12.
//
//  ---------------------------------------------------------------------------
//
//  © 2026 1024jp
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

extension FileManager {
    
    /// Creates a unique temporary directory for a test.
    ///
    /// - Returns: The created directory URL.
    /// - Throws: An error if creating the directory fails.
    func makeTemporaryDirectory() throws -> URL {
        
        let url = self.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try self.createDirectory(at: url, withIntermediateDirectories: true)
        
        return url
    }
}
