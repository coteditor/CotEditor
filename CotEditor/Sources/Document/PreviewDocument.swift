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
//  © 2024-2025 1024jp
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
import AVFoundation

protocol FileContentAttributes: Sendable, Equatable { }


@Observable final class PreviewDocument: DataDocument {
    
    // MARK: Public Properties
    
    private(set) var isAlias = false
    private(set) var isFolderAlias = false
    
    private(set) var previewSize: CGSize?
    private(set) var contentAttributes: (any FileContentAttributes)?
    
    
    // MARK: Document Methods
    
    override nonisolated static var autosavesInPlace: Bool {
        
        true
    }
    
    
    override nonisolated func read(from url: URL, ofType typeName: String) throws {
        
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path(percentEncoded: false))
        let fileAttributes = FileAttributes(dictionary: attributes)
        let isAlias = try url.resourceValues(forKeys: [.isAliasFileKey]).isAliasFile == true
        let isFolderAlias = if isAlias {
            (try? URL(resolvingAliasFileAt: url).resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
        } else {
            false
        }
        
        if let type = UTType(typeName) {
            if let rep = NSImageRep(contentsOf: url) {
                let previewSize = rep.size
                let attributes = rep.attributes
                
                Task { @MainActor in
                    self.previewSize = previewSize
                    self.contentAttributes = attributes.dotsPerInch.isZero ? nil : attributes
                }
                
            } else if type.conforms(to: .movie) {
                Task {
                    let attributes = try await AVURLAsset(url: url).movieAttributes
                    
                    await MainActor.run {
                        self.previewSize = attributes.dimensions
                        self.contentAttributes = attributes
                    }
                }
                
            } else if type.conforms(to: .audio) {
                Task {
                    let attributes = try await AVURLAsset(url: url).audioAttributes
                    
                    await MainActor.run {
                        self.contentAttributes = attributes
                    }
                }
            }
        }
        
        self.continueAsynchronousWorkOnMainActor {
            self.fileAttributes = fileAttributes
            self.isAlias = isAlias
            self.isFolderAlias = isFolderAlias
        }
    }
}


// MARK: QLPreviewItem Protocol

extension PreviewDocument: @MainActor QLPreviewItem {
    
    var previewItemURL: URL! {
        
        self.fileURL
    }
    
    
    var previewItemTitle: String! {
        
        self.fileURL?.lastPathComponent
    }
}
