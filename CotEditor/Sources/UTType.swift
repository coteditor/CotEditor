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
//  © 2022 1024jp
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
import UniformTypeIdentifiers

extension UTType {
    
    var filenameExtensions: [String] {
        
        self.tags[.filenameExtension] ?? []
    }
}


extension URL {
    
    /// Test whether the receiver conforms to the given file URL.
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
