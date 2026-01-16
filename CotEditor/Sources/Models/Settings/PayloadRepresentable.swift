//
//  Persistable.swift
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

protocol PayloadRepresentable: Sendable {
    
    associatedtype Payload: Persistable
    
    
    /// The default uniform type identifier for files representing this type.
    nonisolated static var fileType: UTType { get }
    
    
    /// Creates an instance from a persistable payload and file type.
    init(payload: any Persistable, type: UTType) throws
    
    /// Loads the persisted payload from a file.
    nonisolated static func payload(at fileURL: URL) throws -> Payload
    
    /// Produces a persistable payload that represents the current value.
    func makePayload() throws -> any Persistable
}


extension PayloadRepresentable {
    
    /// Creates an instance by loading contents from a file.
    ///
    /// - Parameter fileURL: The location of the file to read.
    /// - Throws: An error if reading or decoding the file fails.
    init(contentsOf fileURL: URL) throws {
        
        let payload = try Self.payload(at: fileURL)
        
        try self.init(payload: payload, type: UTType(filenameExtension: fileURL.pathExtension) ?? Self.fileType)
    }
}


// MARK: -

protocol Persistable: Equatable, Sendable {
    
    /// The `FileWrapper` representation.
    var fileWrapper: FileWrapper { get }
    
    
    /// Writes the contents to the specified file location.
    ///
    /// - Parameter fileURL: The destination URL to write the persisted data to.
    /// - Throws: An error if writing the contents fails.
    func write(to fileURL: URL) throws
}


extension Data: Persistable {
    
    var fileWrapper: FileWrapper {
        
        FileWrapper(regularFileWithContents: self)
    }
    
    
    func write(to fileURL: URL) throws {
        
        try self.write(to: fileURL, options: [])
    }
}
