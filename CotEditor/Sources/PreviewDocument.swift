//
//  PreviewDocument.swift
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

import AppKit
import QuickLookUI

@Observable final class PreviewDocument: NSDocument {
    
    private(set) var previewSize: CGSize?
    
    
    override nonisolated static var autosavesInPlace: Bool {
        
        true
    }
    
    
    override nonisolated func read(from url: URL, ofType typeName: String) throws {
        
        let previewSize = NSImageRep(contentsOf: url)?.size
        
        Task { @MainActor in
            self.previewSize = previewSize
        }
    }
}


extension PreviewDocument: @preconcurrency QLPreviewItem {
    
    var previewItemURL: URL! {
        
        self.fileURL
    }
    
    
    var previewItemTitle: String! {
        
        self.fileURL?.lastPathComponent
    }
}
