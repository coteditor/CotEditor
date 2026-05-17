//
//  String+Encoding.swift
//  FolderFind
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-05-17.
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
import DocumentFile

extension String {
    
    /// Initializes a string by reading and decoding the contents of the file at the given URL.
    ///
    /// - Parameters:
    ///   - url: The file URL to read.
    ///   - decodingOptions: The decoding options.
    /// - Throws: A file read or decoding error.
    init(contentsOf url: URL, decodingOptions: String.DetectionOptions) throws {
        
        let data = try Data(contentsOf: url)
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path(percentEncoded: false))
        let extendedAttributes = ExtendedFileAttributes(dictionary: attributes)
        var decodingOptions = decodingOptions
        decodingOptions.xattrEncoding = extendedAttributes.encoding
        
        (self, _) = try String.string(data: data, decodingStrategy: .automatic(decodingOptions))
    }
}
