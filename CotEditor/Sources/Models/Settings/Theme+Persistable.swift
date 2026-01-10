//
//  Theme+Persistable.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by imanishi on 1/10/26.
//
//  ---------------------------------------------------------------------------
//
//  © 2026 CotEditor Project
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


extension Theme: PersistableConvertible, @unchecked Sendable {
    
    typealias Persistent = Data
    
    
    nonisolated static let fileType: UTType = .cotTheme
    
    
    init(persistence: any Persistable, type: UTType) throws {
        
        switch persistence {
            case let data as Data where type.conforms(to: UTType.cotTheme):
                self = try JSONDecoder().decode(Self.self, from: data)
                
            default:
                throw CocoaError(.fileReadUnsupportedScheme)
        }
    }
    
    
    nonisolated static func persistence(at fileURL: URL) throws -> Persistent {
        
        try Data(contentsOf: fileURL)
    }
    
    
    func makePersistable() throws -> any Persistable {
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        return try encoder.encode(self)
    }
}
