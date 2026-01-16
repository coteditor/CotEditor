//
//  Theme+PayloadRepresentable.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-01-10.
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
import UniformTypeIdentifiers

extension UTType {
    
    static let cotTheme = UTType(exportedAs: "com.coteditor.CotEditor.theme")
}


extension Theme: PayloadRepresentable, @unchecked Sendable {
    
    typealias Payload = Data
    
    
    nonisolated static let fileType: UTType = .cotTheme
    
    
    init(payload: any Persistable, type: UTType) throws {
        
        switch payload {
            case let data as Data where type.conforms(to: UTType.cotTheme):
                self = try JSONDecoder().decode(Self.self, from: data)
                
            default:
                throw CocoaError(.fileReadUnsupportedScheme)
        }
    }
    
    
    nonisolated static func payload(at fileURL: URL) throws -> Payload {
        
        try Data(contentsOf: fileURL)
    }
    
    
    func makePayload() throws -> any Persistable {
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        return try encoder.encode(self)
    }
}
