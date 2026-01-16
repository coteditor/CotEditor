//
//  TransferableFile.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-01-16.
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
import CoreTransferable
import UniformTypeIdentifiers

protocol TransferableFile: Transferable {
    
    nonisolated static var fileType: UTType { get }
    
    var name: String { get }
    var url: URL? { get }
    
    init(name: String, url: URL?)
}


extension TransferableFile {
    
    static var transferRepresentation: some TransferRepresentation {
        
        FileRepresentation(contentType: Self.fileType) { item in
            guard let url = item.url else { throw CocoaError(.fileNoSuchFile) }
            return SentTransferredFile(url)
            
        } importing: { received throws -> Self in
            let name = received.file.deletingPathExtension().lastPathComponent
            let destination = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(received.file.pathExtension)
            try FileManager.default.copyItem(at: received.file, to: destination)
            
            return Self(name: name, url: destination)
        }
        .suggestedFileName(\.name)
        .exportingCondition { $0.url != nil }
    }
}
