//
//  OpenOptions.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-04-25.
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
import Synchronization

struct OpenOptions {
    
    var encoding: String.Encoding?
    var isReadOnly = false
}


enum PendingOpenOptions {
    
    private static let optionsByURL = Mutex<[URL: OpenOptions]>([:])
    
    
    /// Returns the options selected in the open panel for the given document URL.
    ///
    /// - Parameter url: The document URL.
    /// - Returns: The options registered for the document URL, or `nil` if the document was not selected in the open panel.
    static func options(for url: URL) -> OpenOptions? {
        
        self.optionsByURL.withLock {
            $0[url.standardizedFileURL]
        }
    }
    
    
    /// Registers the options selected in the open panel for the URLs selected in that panel.
    ///
    /// - Parameters:
    ///   - options: The open panel options.
    ///   - urls: The document URLs selected in the open panel.
    static func register(_ options: OpenOptions, for urls: [URL]) {
        
        self.optionsByURL.withLock {
            for url in urls {
                $0[url.standardizedFileURL] = options
            }
        }
    }
    
    
    /// Removes the options registered for the given document URL after its opening flow finishes.
    ///
    /// - Parameter url: The document URL.
    static func remove(for url: URL) {
        
        self.optionsByURL.withLock {
            _ = $0.removeValue(forKey: url.standardizedFileURL)
        }
    }
}
