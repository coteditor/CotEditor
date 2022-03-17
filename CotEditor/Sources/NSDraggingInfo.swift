//
//  NSDraggingInfo.swift
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

import AppKit
import UniformTypeIdentifiers

extension NSDraggingInfo {
    
    /// Obtain file URL type dragging items.
    ///
    /// - Parameters:
    ///   - type: The UTType to restrict the results.
    ///   - view: The view used as the base coordinate system for the NSDraggingItem instances.
    /// - Returns: An array fo file URLs.
    func fileURLs(with type: UTType, for view: NSView? = nil) -> [URL]? {
        
        var urls: [URL] = []
        self.enumerateDraggingItems(for: view, classes: [NSURL.self],
                                    searchOptions: [.urlReadingFileURLsOnly: true,
                                                    .urlReadingContentsConformToTypes: [type.identifier]])
        { (draggingItem, _, _) in
            guard let fileURL = draggingItem.item as? URL else { return }
            
            urls.append(fileURL)
        }
        
        return urls.isEmpty ? nil : urls
    }
    
}
