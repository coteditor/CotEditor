//
//  FileManager.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2022-03-17.
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

extension FileManager {
    
    /// Create a unique directory in a user temporary directory and return the URL created.
    ///
    /// - Returns: The URL of the temporary directory created.
    func createTemporaryDirectory() -> URL {
        
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
        
        try! self.createDirectory(at: url, withIntermediateDirectories: true)
        
        return url
    }
    
}
