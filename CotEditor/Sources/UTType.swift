//
//  UTType.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2022-03-15.
//
//  ---------------------------------------------------------------------------
//
//  © 2022-2024 1024jp
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

import UniformTypeIdentifiers

extension UTType {
    
    /// All filename extensions.
    var filenameExtensions: [String] {
        
        self.tags[.filenameExtension] ?? []
    }
    
    
    /// Whether the type should be handled as plain-text in this app.
    ///
    /// - RTF also conforms to public.text, but it is OK in CotEditor.
    /// - SVG conforms both .text and .image (except SVGZ).
    /// - The parent of `.propertyList` is not text but `.data` (It can not be determined only from UTI whether the file is binary or XML).
    /// - "ts" extension conflicts between MPEG-2 transport stream and TypeScript.
    ///
    /// - Note: This judge is valid only in CotEditor.
    var isPlainText: Bool {
        
        self.conforms(to: .text) || self.conforms(to: .propertyList) || self == .mpeg2TransportStream
    }
}


extension URL {
    
    /// Tests whether the receiver conforms to the given file URL.
    ///
    /// This method checks only the conformance of the file extension.
    ///
    /// - Parameter type: A UTType of the file.
    /// - Returns: `true` if the receiver conforms to the type, otherwise `false`.
    func conforms(to type: UTType) -> Bool {
        
        type.filenameExtensions
            .map { $0.lowercased() }
            .contains(self.pathExtension.lowercased())
    }
}
