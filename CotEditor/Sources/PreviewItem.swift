//
//  PreviewItem.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-09-02.
//
//  ---------------------------------------------------------------------------
//
//  © 2024 1024jp
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
import QuickLookUI

@Observable final class PreviewItem: NSObject {
    
    private(set) var fileURL: URL
    private(set) var previewSize: CGSize?
    
    
    init(contentsOf url: URL) throws {
        
        self.fileURL = url
        
        var size: CGSize?
        var error: NSError?
        NSFileCoordinator().coordinate(readingItemAt: url, options: [.withoutChanges, .resolvesSymbolicLink], error: &error) { newURL in
            // -> Use NSImageRep because NSImage's `size` returns a DPI applied size.
            let imageRep = NSImageRep(contentsOf: newURL)
            size = imageRep?.size
        }
        if let error {
            throw error
        }
        
        self.previewSize = size
    }
}


extension PreviewItem: QLPreviewItem {
    
    var previewItemURL: URL! {
        
        self.fileURL
    }
    
    
    var previewItemTitle: String! {
        
        self.fileURL.lastPathComponent
    }
}
