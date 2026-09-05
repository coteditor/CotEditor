//
//  URL+Binary.swift
//  FolderFind
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-09-05.
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
import FileEncoding

extension URL {
    
    /// Whether the file at the URL looks like binary.
    ///
    /// A file is treated as binary if it is a binary property list,
    /// or if its leading bytes contain a NUL byte unless it starts with a Unicode byte order mark.
    ///
    /// - Throws: An error if the file cannot be opened or read.
    var isBinary: Bool {
        
        get throws {
            // read first 8 KiB
            let head = try self.leadingBytes(upToCount: 8_192)
            
            if head.starts(with: Data("bplist".utf8)) { return true }
            
            // -> Same heuristic as grep and Git: a NUL byte within the first 8 KiB.
            guard head.contains(0) else { return false }
            
            return !Unicode.BOM.allCases.contains { head.starts(with: $0.sequence) }
        }
    }
    
    
    /// Reads the leading bytes of the file at the URL.
    ///
    /// - Parameter count: The maximum number of bytes to read.
    /// - Returns: The leading bytes, which can be shorter than `count` for a small file.
    /// - Throws: An error if the file cannot be opened or read.
    private func leadingBytes(upToCount count: Int) throws -> Data {
        
        let fileHandle = try FileHandle(forReadingFrom: self)
        defer { try? fileHandle.close() }
        
        return try fileHandle.read(upToCount: count) ?? Data()
    }
}
