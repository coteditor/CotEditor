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
//  © 2016-2026 1024jp
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
import ImageIO
import URLUtils

struct FileDropItem: Equatable, Identifiable {
    
    let id = UUID()
    
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
    
    /// Tests whether the given conditions are supported.
    ///
    /// - Parameters:
    ///   - pathExtension: The file extension.
    ///   - scope: The syntax scope.
    /// - Returns: `true` if the given values are supported.
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
        
        if let extensions = dictionary[CodingKeys.extensions] {
            self.extensions = extensions
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
        }
        if let scope = dictionary[CodingKeys.scope], !scope.isEmpty {
            self.scope = scope
        }
        if let description = dictionary[CodingKeys.description], !description.isEmpty {
            self.description = description
        }
    }
    
    
    var dictionary: [String: String] {
        
        [
            CodingKeys.format: self.format,
            CodingKeys.extensions: self.extensions.isEmpty ? nil : self.extensions.joined(separator: ", "),
            CodingKeys.scope: self.scope,
            CodingKeys.description: self.description,
        ]
        .mapKeys(\.rawValue)
        .compactMapValues(\.self)
    }
}


// MARK: Composition

extension FileDropItem {
    
    enum Variable: String, CaseIterable, TokenRepresentable {
        
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
        
        
        var descriptionResource: LocalizedStringResource {
            
            switch self {
                case .absolutePath:
                    .init("FileDropItem.Variable.absolutePath.description",
                          defaultValue: "The absolute path of the dropped file.")
                case .relativePath:
                    .init("FileDropItem.Variable.relativePath.description",
                          defaultValue: "The relative path between the dropped file and the document.")
                case .filename:
                    .init("FileDropItem.Variable.filename.description",
                          defaultValue: "The dropped file’s name including the extension, if any.")
                case .filenameWithoutExtension:
                    .init("FileDropItem.Variable.filenameWithoutExtension.description",
                          defaultValue: "The dropped file’s name without extension.")
                case .fileExtension:
                    .init("FileDropItem.Variable.fileExtension.description",
                          defaultValue: "The dropped file’s extension.")
                case .fileExtensionLowercase:
                    .init("FileDropItem.Variable.fileExtensionLowercase.description",
                          defaultValue: "The dropped file’s extension (converted to lowercase).")
                case .fileExtensionUppercase:
                    .init("FileDropItem.Variable.fileExtensionUppercase.description",
                          defaultValue: "The dropped file’s extension (converted to uppercase).")
                case .directory:
                    .init("FileDropItem.Variable.directory.description",
                          defaultValue: "The parent directory name of the dropped file.")
                case .fileContent:
                    .init("FileDropItem.Variable.fileContent.description",
                          defaultValue: "The file content.")
                case .imageWidth:
                    .init("FileDropItem.Variable.imageWidth.description",
                          defaultValue: "The image width.")
                case .imageHeight:
                    .init("FileDropItem.Variable.imageHeight.description",
                          defaultValue: "The image height.")
            }
        }
    }
    
    
    // MARK: Public Methods
    
    /// Creates file drop text.
    ///
    /// - Parameters:
    ///   - droppedFileURL: The URL of the dropped item to insert.
    ///   - documentURL: The file URL of the document or nil if it's not yet saved.
    /// - Returns: The text to insert.
    func dropText(forFileURL droppedFileURL: URL, documentURL: URL?) -> String {
        
        var tokens: [(variable: Variable, range: NSRange)] = []
        Variable.makeTokenizer().tokenize(self.format) { token, range, _ in
            guard let variable = Variable(rawValue: token) else { return assertionFailure() }
            tokens.append((variable, range))
        }
        let variables = Set(tokens.map(\.variable))
        
        let absolutePath = droppedFileURL.isFileURL
            ? droppedFileURL.path(percentEncoded: false)
            : droppedFileURL.absoluteString
        let relativePath = if let documentURL, droppedFileURL.isFileURL {
            droppedFileURL.path(relativeTo: documentURL)
        } else {
            absolutePath
        }
        
        var values: [Variable: String] = [
            .absolutePath: absolutePath,
            .relativePath: relativePath,
            .filename: droppedFileURL.lastPathComponent,
            .filenameWithoutExtension: droppedFileURL.deletingPathExtension().lastPathComponent,
            .fileExtension: droppedFileURL.pathExtension,
            .fileExtensionLowercase: droppedFileURL.pathExtension.lowercased(),
            .fileExtensionUppercase: droppedFileURL.pathExtension.uppercased(),
            .directory: droppedFileURL.deletingLastPathComponent().lastPathComponent,
        ]
        
        // get image dimension if needed
        if !variables.isDisjoint(with: Variable.imageTokens) {
            var pixelWidth: Int?
            var pixelHeight: Int?
            NSFileCoordinator().coordinate(readingItemAt: droppedFileURL, options: [.withoutChanges, .resolvesSymbolicLink], error: nil) { newURL in
                guard
                    let source = CGImageSourceCreateWithURL(newURL as CFURL, nil),
                    let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
                else { return }
                
                pixelWidth = properties[kCGImagePropertyPixelWidth] as? Int
                pixelHeight = properties[kCGImagePropertyPixelHeight] as? Int
                
                // swap for the orientations rotated by 90 degrees
                if let orientation = (properties[kCGImagePropertyOrientation] as? UInt32).flatMap(CGImagePropertyOrientation.init(rawValue:)),
                   [.leftMirrored, .right, .rightMirrored, .left].contains(orientation)
                {
                    swap(&pixelWidth, &pixelHeight)
                }
            }
            if let pixelWidth, let pixelHeight {
                values[.imageWidth] = String(pixelWidth)
                values[.imageHeight] = String(pixelHeight)
            }
        }
        
        // get text content if needed
        if variables.contains(.fileContent) {
            values[.fileContent] = (try? String(contentsOf: droppedFileURL, encoding: .utf8)) ?? ""
        }
        
        // replace the tokens in a single pass, so that tokens contained in the values are kept as is
        let dropText = NSMutableString(string: self.format)
        for (variable, range) in tokens.reversed() {
            guard let value = values[variable] else { continue }
            
            dropText.replaceCharacters(in: range, with: value)
        }
        
        return dropText as String
    }
}
