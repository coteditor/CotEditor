//
//  UUID+Transferable.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-05-08.
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
import UniformTypeIdentifiers
import CoreTransferable

extension UTType {
    
    nonisolated static let uuid = UTType(exportedAs: "com.coteditor.uuid")
}


extension UUID: @retroactive Transferable {
    
    public static var transferRepresentation: some TransferRepresentation {
        
        CodableRepresentation(for: UUID.self, contentType: .uuid)
    }
}


extension UUID {
    
    var itemProvider: NSItemProvider {
        
        let provider = NSItemProvider()
        provider.register(self)
        return provider
    }
}


// MARK: Item Provider

extension NSItemProvider {
    
    func load<T: Transferable & Sendable>(type: T.Type) async throws -> sending T {
        
        try await withCheckedThrowingContinuation { continuation in
            _ = self.loadTransferable(type: T.self) { result in
                switch result {
                    case .success(let success):
                        continuation.resume(returning: success)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                }
            }
        }
    }
}
