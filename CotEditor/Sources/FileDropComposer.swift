//
//  FileDropComposer.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-06-09.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2020 1024jp
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

final class FileDropComposer {
    
    /// keys for dicts in DefaultKey.fileDropArray
    enum SettingKey {
        
        static let extensions = "extensions"
        static let formatString = "formatString"
        static let scope = "scope"
        static let description = "description"
    }
    
    
    enum Token: String, TokenRepresentable {
        
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
        
        static let pathTokens: [Token] = [.absolutePath, .relativePath, .filename, .filenameWithoutExtension, .fileExtension, .fileExtensionLowercase, .fileExtensionUppercase, .directory]
        static let textTokens: [Token] = [.fileContent]
        static let imageTokens: [Token] = [.imageWidth, .imageHeight]
        
        
        var description: String {
            
            switch self {
                case .absolutePath:
                    return "The dropped file absolute path."
                case .relativePath:
                    return "The relative path between the dropped file and the document."
                case .filename:
                    return "The dropped file’s name including extension (if exists)."
                case .filenameWithoutExtension:
                    return "The dropped file’s name without extension."
                case .fileExtension:
                    return "The dropped file’s extension."
                case .fileExtensionLowercase:
                    return "The dropped file’s extension (converted to lowercase)."
                case .fileExtensionUppercase:
                    return "The dropped file’s extension (converted to uppercase)."
                case .directory:
                    return "The parent directory name of dropped file."
                case .fileContent:
                    return "(If the dropped file is a text file) file content."
                case .imageWidth:
                    return "(If the dropped file is an image) image width."
                case .imageHeight:
                    return "(If the dropped file is an image) image height."
            }
        }
        
    }
    
    
    private let definitions: [[String: String]]
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    init(definitions: [[String: String]]) {
        
        self.definitions = definitions
    }
    
    
    
    // MARK: Public Methods
    
    /// create file drop text
    ///
    /// - Parameters:
    ///   - droppedFileURL: The file URL of dropped file to insert.
    ///   - documentURL: The file URL of the document or nil if it's not yet saved.
    ///   - syntaxStyle: The document syntax style or nil if style is not specified.
    /// - Returns: The text to insert.
    func dropText(forFileURL droppedFileURL: URL, documentURL: URL?, syntaxStyle: String?) -> String? {
        
        let pathExtension = droppedFileURL.pathExtension
        
        guard let template = self.template(forExtension: pathExtension, syntaxStyle: syntaxStyle) else { return nil }
        
        // replace template
        var dropText = template
            .replacingOccurrences(of: Token.absolutePath.token, with: droppedFileURL.path)
            .replacingOccurrences(of: Token.relativePath.token, with: droppedFileURL.path(relativeTo: documentURL) ?? droppedFileURL.path)
            .replacingOccurrences(of: Token.filename.token, with: droppedFileURL.lastPathComponent)
            .replacingOccurrences(of: Token.filenameWithoutExtension.token, with: droppedFileURL.deletingPathExtension().lastPathComponent)
            .replacingOccurrences(of: Token.fileExtension.token, with: pathExtension)
            .replacingOccurrences(of: Token.fileExtensionLowercase.token, with: pathExtension.lowercased())
            .replacingOccurrences(of: Token.fileExtensionUppercase.token, with: pathExtension.uppercased())
            .replacingOccurrences(of: Token.directory.token, with: droppedFileURL.deletingLastPathComponent().lastPathComponent)
        
        // get image dimension if needed
        // -> Use NSImageRep because NSImage's `size` returns a DPI applied size.
        if template.contains(Token.imageWidth.token) || template.contains(Token.imageHeight.token) {
            var imageRep: NSImageRep?
            NSFileCoordinator().coordinate(readingItemAt: droppedFileURL, options: [.withoutChanges, .resolvesSymbolicLink], error: nil) { (newURL: URL) in
                imageRep = NSImageRep(contentsOf: newURL)
            }
            if let imageRep = imageRep {
                dropText = dropText
                    .replacingOccurrences(of: Token.imageWidth.token, with: String(imageRep.pixelsWide))
                    .replacingOccurrences(of: Token.imageHeight.token, with: String(imageRep.pixelsHigh))
            }
        }
        
        // get text content if needed
        // -> Replace this at last because the file content can contain other tokens.
        if template.contains(Token.fileContent.token) {
            let content = try? String(contentsOf: droppedFileURL)
            dropText = dropText.replacingOccurrences(of: Token.fileContent.token, with: content ?? "")
        }
        
        return dropText
    }
    
    
    
    // MARK: Private Methods
    
    /// find matched template for path extension and scope
    ///
    /// - Parameters:
    ///   - fileExtension: The extension of file to drop.
    ///   - syntaxStyle: The document syntax style or nil if style is not specified.
    /// - Returns: A matched template string for file drop or nil if not found.
    private func template(forExtension fileExtension: String, syntaxStyle: String?) -> String? {
        
        guard !fileExtension.isEmpty else { return nil }
        
        let definition = self.definitions.first { definition in
            // check scope
            if let scope = definition[SettingKey.scope], !scope.isEmpty,
                syntaxStyle != scope
            {
                return false
            }
            
            // check extensions
            if let extensions = definition[SettingKey.extensions]?.components(separatedBy: ", "),
                !extensions.contains(where: { $0.compare(fileExtension, options: .caseInsensitive) == .orderedSame })
            {
                return false
            }
            
            return true
        }
        
        return definition?[SettingKey.formatString]
    }
    
}
