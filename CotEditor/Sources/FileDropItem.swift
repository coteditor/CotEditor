//
//  FileDropItem.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-06-09.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2023 1024jp
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
import AppKit.NSImageRep

struct FileDropItem {
    
    var format: String = ""
    var extensions: [String] = [] {
        
        didSet {
            self.extensions = extensions
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
        }
    }
    var scope: String?
    var description: String?
    
    
    
    // MARK: Public Methods
    
    /// Test whether the given conditions are supported.
    ///
    /// - Parameters:
    ///   - pathExtension: The file extension.
    ///   - scope: The syntax scope.
    /// - Returns: `True` if the given values supported.
    func supports(extension pathExtension: String?, scope: String?) -> Bool {
        
        guard self.scope == nil || self.scope == scope else { return false }
        
        return self.extensions.isEmpty
            ? true
            : self.extensions.contains { $0.lowercased() == pathExtension?.lowercased() }
    }
}



// MARK: Coding

extension FileDropItem {
    
    enum CodingKeys: String, CodingKey {
        
        case format = "formatString"
        case extensions
        case scope
        case description
    }
    
    
    init(dictionary: [String: String]) {
        
        self.format = dictionary[CodingKeys.format] ?? ""
        
        if let extensions = dictionary[CodingKeys.extensions]?.components(separatedBy: ", ") {
            self.extensions = extensions
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
        }
        if let scope = dictionary[CodingKeys.scope], !scope.isEmpty {
            self.scope = scope
        }
        self.description = dictionary[CodingKeys.description] ?? ""
    }
    
    
    var dictionary: [String: String] {
        
        [
            CodingKeys.format: self.format,
            CodingKeys.extensions: self.extensions.isEmpty ? nil : self.extensions.joined(separator: ", "),
            CodingKeys.scope: self.scope,
            CodingKeys.description: self.description,
        ]
        .mapKeys(\.rawValue)
        .compactMapValues { $0 }
    }
}



// MARK: Composition

extension FileDropItem {
    
    enum Variable: String, TokenRepresentable {
        
        static let prefix = "<<<"
        static let suffix = ">>>"
        
        case absolutePath = "ABSOLUTE-PATH"
        case relativePath = "RELATIVE-PATH"
        case filename = "FILENAME"
        case filenameWithoutExtension = "FILENAME-NOSUFFIX"
        case fileExtension = "FILEEXTENSION"
        case fileExtensionLowercase = "FILEEXTENSION-LOWER"
        case fileExtensionUppercase = "FILEEXTENSION-UPPER"
        case directory = "DIRECTORY"
        case fileContent = "FILECONTENT"
        case imageWidth = "IMAGEWIDTH"
        case imageHeight = "IMAGEHEIGHT"
        
        static let pathTokens: [Self] = [.absolutePath, .relativePath, .filename, .filenameWithoutExtension, .fileExtension, .fileExtensionLowercase, .fileExtensionUppercase, .directory]
        static let textTokens: [Self] = [.fileContent]
        static let imageTokens: [Self] = [.imageWidth, .imageHeight]
        
        
        var localizedDescription: String {
            
            switch self {
                case .absolutePath:
                    String(localized: "The dropped file absolute path.")
                case .relativePath:
                    String(localized: "The relative path between the dropped file and the document.")
                case .filename:
                    String(localized: "The dropped file’s name including extension (if exists).")
                case .filenameWithoutExtension:
                    String(localized: "The dropped file’s name without extension.")
                case .fileExtension:
                    String(localized: "The dropped file’s extension.")
                case .fileExtensionLowercase:
                    String(localized: "The dropped file’s extension (converted to lowercase).")
                case .fileExtensionUppercase:
                    String(localized: "The dropped file’s extension (converted to uppercase).")
                case .directory:
                    String(localized: "The parent directory name of dropped file.")
                case .fileContent:
                    String(localized: "(If the dropped file is a text file) file content.")
                case .imageWidth:
                    String(localized: "(If the dropped file is an image) image width.")
                case .imageHeight:
                    String(localized: "(If the dropped file is an image) image height.")
            }
        }
    }
    
    
    
    // MARK: Public Methods
    
    /// Create file drop text.
    ///
    /// - Parameters:
    ///   - droppedFileURL: The file URL of dropped file to insert.
    ///   - documentURL: The file URL of the document or nil if it's not yet saved.
    /// - Returns: The text to insert.
    func dropText(forFileURL droppedFileURL: URL, documentURL: URL?) -> String {
        
        // replace template
        var dropText = self.format
            .replacing(Variable.absolutePath.token, with: droppedFileURL.path)
            .replacing(Variable.relativePath.token, with: droppedFileURL.path(relativeTo: documentURL) ?? droppedFileURL.path)
            .replacing(Variable.filename.token, with: droppedFileURL.lastPathComponent)
            .replacing(Variable.filenameWithoutExtension.token, with: droppedFileURL.deletingPathExtension().lastPathComponent)
            .replacing(Variable.fileExtension.token, with: droppedFileURL.pathExtension)
            .replacing(Variable.fileExtensionLowercase.token, with: droppedFileURL.pathExtension.lowercased())
            .replacing(Variable.fileExtensionUppercase.token, with: droppedFileURL.pathExtension.uppercased())
            .replacing(Variable.directory.token, with: droppedFileURL.deletingLastPathComponent().lastPathComponent)
        
        // get image dimension if needed
        // -> Use NSImageRep because NSImage's `size` returns a DPI applied size.
        if self.format.contains(Variable.imageWidth.token) || self.format.contains(Variable.imageHeight.token) {
            var imageRep: NSImageRep?
            NSFileCoordinator().coordinate(readingItemAt: droppedFileURL, options: [.withoutChanges, .resolvesSymbolicLink], error: nil) { (newURL: URL) in
                imageRep = NSImageRep(contentsOf: newURL)
            }
            if let imageRep {
                dropText = dropText
                    .replacing(Variable.imageWidth.token, with: String(imageRep.pixelsWide))
                    .replacing(Variable.imageHeight.token, with: String(imageRep.pixelsHigh))
            }
        }
        
        // get text content if needed
        // -> Replace this at last because the file content can contain other tokens.
        if self.format.contains(Variable.fileContent.token) {
            let content = try? String(contentsOf: droppedFileURL)
            dropText = dropText.replacing(Variable.fileContent.token, with: content ?? "")
        }
        
        return dropText
    }
}
