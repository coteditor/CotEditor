//
//  DocumentFile.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-03-05.
//
//  ---------------------------------------------------------------------------
//
//  © 2018-2024 1024jp
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

extension FileAttributeKey {
    
    static let extendedAttributes = FileAttributeKey("NSFileExtendedAttributes")
}


enum FileExtendedAttributeName {
    
    static let encoding = "com.apple.TextEncoding"
    static let verticalText = "com.coteditor.VerticalText"
    static let allowLineEndingInconsistency = "com.coteditor.AllowLineEndingInconsistency"
}



struct DocumentFile {
    
    enum EncodingStrategy {
        
        case automatic(priority: [String.Encoding], refersToTag: Bool)
        case specific(String.Encoding)
    }
    
    
    struct Attributes {
        
        var creationDate: Date?
        var modificationDate: Date?
        var size: Int64
        var permissions: FilePermissions
        var owner: String?
    }
    
    
    /// Maximal length to scan encoding declaration
    private static let maxEncodingScanLength = 2000
    
    
    // MARK: Properties
    
    var data: Data
    var string: String
    var attributes: Attributes
    var fileEncoding: FileEncoding
    var xattrEncoding: String.Encoding?
    var isVerticalText: Bool
    var allowsInconsistentLineEndings: Bool
    
    
    
    // MARK: Lifecycle
    
    /// Reads file at the given URL and initialize.
    ///
    /// - Parameters:
    ///   - fileURL: The location of the file to read.
    ///   - encodingStrategy: The text encoding to read the file.
    init(fileURL: URL, encodingStrategy: EncodingStrategy) throws {
        
        guard fileURL.isFileURL else { throw CocoaError.error(.fileReadUnknown, url: fileURL) }
        
        let data = try Data(contentsOf: fileURL)  // FILE_READ
        let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)  // FILE_READ
        
        // check extended attributes
        let extendedAttributes = attributes[.extendedAttributes] as? [String: Data]
        self.xattrEncoding = extendedAttributes?[FileExtendedAttributeName.encoding]?.decodingXattrEncoding
        self.isVerticalText = (extendedAttributes?[FileExtendedAttributeName.verticalText] != nil)
        self.allowsInconsistentLineEndings = (extendedAttributes?[FileExtendedAttributeName.allowLineEndingInconsistency] != nil)
        
        // decode Data to String
        let content: String
        let encoding: String.Encoding
        switch encodingStrategy {
            case .automatic(let priority, let refersToTag):
                (content, encoding) = try Self.string(data: data, xattrEncoding: self.xattrEncoding,
                                                      suggestedEncodings: priority,
                                                      refersToEncodingTag: refersToTag)
            case .specific(let readingEncoding):
                guard let string = String(bomCapableData: data, encoding: readingEncoding) else {
                    throw CocoaError.error(.fileReadInapplicableStringEncoding, userInfo: [NSStringEncodingErrorKey: readingEncoding.rawValue])
                }
                content = string
                encoding = readingEncoding
        }
        
        // set properties
        self.data = data
        self.string = content
        self.attributes = Attributes(dictionary: attributes)
        self.fileEncoding = FileEncoding(encoding: encoding,
                                         withUTF8BOM: (encoding == .utf8) && data.starts(with: Unicode.BOM.utf8.sequence))
    }
    
    
    
    // MARK: Private Methods
    
    /// Reads string from data by detecting the text encoding automatically.
    ///
    /// - Parameters:
    ///   - data: The data to encode.
    ///   - xattrEncoding: The text encoding read from the file's extended attributes.
    ///   - suggestedEncodings: The list of encodings to test the encoding.
    ///   - refersToEncodingTag: The boolean whether to refer encoding tag in the file content.
    /// - Returns: The decoded string and used encoding.
    private static func string(data: Data, xattrEncoding: String.Encoding?, suggestedEncodings: [String.Encoding], refersToEncodingTag: Bool) throws -> (String, String.Encoding) {
        
        // try interpreting with xattr encoding
        if let xattrEncoding {
            // just trust xattr encoding if content is empty
            if let string = data.isEmpty ? "" : String(bomCapableData: data, encoding: xattrEncoding) {
                return (string, xattrEncoding)
            }
        }
        
        // detect encoding from data
        var usedEncoding: String.Encoding?
        let string = try String(data: data, suggestedEncodings: suggestedEncodings, usedEncoding: &usedEncoding)
        
        // try reading encoding declaration and take priority of it if it seems well
        if refersToEncodingTag,
           let scannedEncoding = string.scanEncodingDeclaration(upTo: self.maxEncodingScanLength),
           suggestedEncodings.contains(scannedEncoding),
           scannedEncoding != usedEncoding,
           let string = String(bomCapableData: data, encoding: scannedEncoding)
        {
            return (string, scannedEncoding)
        }
        
        guard let encoding = usedEncoding else {
            throw CocoaError(.fileReadUnknownStringEncoding)
        }
        
        return (string, encoding)
    }
}


extension DocumentFile.Attributes {
    
    init(dictionary: [FileAttributeKey: Any]) {
        
        self.creationDate = dictionary[.creationDate] as? Date
        self.modificationDate = dictionary[.modificationDate] as? Date
        self.size = dictionary[.size] as? Int64 ?? 0
        self.permissions = FilePermissions(mask: dictionary[.posixPermissions] as? Int16 ?? 0)
        self.owner = dictionary[.ownerAccountName] as? String
    }
}
