//
//  Syntax+PayloadRepresentable.swift
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
import Syntax

extension UTType {
    
    static let cotSyntax = UTType(exportedAs: "com.coteditor.CotEditor.syntax")
}


extension Syntax: PayloadRepresentable {
    
    nonisolated static let fileType: UTType = .cotSyntax
    
    
    init(payload: any Persistable, type: UTType) throws {
        
        switch payload {
            case let fileWrapper as FileWrapper where type.conforms(to: .cotSyntax):
                try self.init(fileWrapper: fileWrapper)
            case let data as Data where type.conforms(to: .yaml):
                try self.init(yamlData: data)
                
            default:
                throw CocoaError(.fileReadUnsupportedScheme)
        }
    }
    
    
    nonisolated static func payload(at fileURL: URL) throws -> some Persistable {
        
        try FileWrapper(url: fileURL, options: .immediate)
    }
    
    
    func makePayload() throws -> any Persistable {
        
        try self.fileWrapper
    }
}
