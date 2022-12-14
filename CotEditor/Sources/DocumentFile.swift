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
//  © 2018-2022 1024jp
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
    
    enum EncodingStorategy {
        
        case automatic(priority: [CFStringEncoding], refersToTag: Bool)
        case specific(String.Encoding)
    }
    
    
    /// Maximal length to scan encoding declaration
    private static let maxEncodingScanLength = 2000
    
    
    // MARK: Properties
    
    let data: Data
    let string: String
    let attributes: [FileAttributeKey: Any]
    let fileEncoding: FileEncoding
    let xattrEncoding: String.Encoding?
    let permissions: FilePermissions
    let isVerticalText: Bool
    let allowsInconsistentLineEndings: Bool
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    /// Read file at the given URL and initialize.
    ///
    /// - Parameters:
    ///   - fileURL: The location of the file to read.
    ///   - encodingStorategy: The file encoding to read the file.
    init(fileURL: URL, encodingStorategy: EncodingStorategy) throws {
        
        let data = try Data(contentsOf: fileURL, options: [.mappedIfSafe])  // FILE_READ
        let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)  // FILE_READ
        
        // check extended attributes
        let extendedAttributes = attributes[.extendedAttributes] as? [String: Data]
        self.xattrEncoding = extendedAttributes?[FileExtendedAttributeName.encoding]?.decodingXattrEncoding
        self.isVerticalText = (extendedAttributes?[FileExtendedAttributeName.verticalText] != nil)
        self.allowsInconsistentLineEndings = (extendedAttributes?[FileExtendedAttributeName.allowLineEndingInconsistency] != nil)
        
        // decode Data to String
        let content: String
        let encoding: String.Encoding
        switch encodingStorategy {
            case let .automatic(priority, refersToTag):
                (content, encoding) = try Self.string(data: data, xattrEncoding: self.xattrEncoding,
                                                      suggestedCFEncodings: priority,
                                                      refersToEncodingTag: refersToTag)
            case .specific(let readingEncoding):
                encoding = readingEncoding
                if !data.isEmpty {
                    guard let string = String(bomCapableData: data, encoding: encoding) else {
                        throw CocoaError.error(.fileReadInapplicableStringEncoding, userInfo: [NSStringEncodingErrorKey: encoding.rawValue], url: fileURL)
                    }
                    content = string
                } else {
                    content = ""
                }
        }
        
        // set properties
        self.data = data
        self.attributes = attributes
        self.string = content
        self.fileEncoding = FileEncoding(encoding: encoding,
                                         withUTF8BOM: (encoding == .utf8) && data.starts(with: Unicode.BOM.utf8.sequence))
        self.permissions = FilePermissions(mask: attributes[.posixPermissions] as? UInt16 ?? 0)
    }
    
    
    
    // MARK: Private Methods
    
    /// Read string from data by detecting the file encoding automatically.
    ///
    /// - Parameters:
    ///   - data: The data to encode.
    ///   - xattrEncoding: The file encoding read from the file's extended attributes.
    ///   - suggestedCFEncodings: The list of CSStringEncodings to test the encoding.
    ///   - refersToEncodingTag: The boolean whether to refer encoding tag in the file content.
    /// - Returns: The decoded string and used encoding.
    private static func string(data: Data, xattrEncoding: String.Encoding?, suggestedCFEncodings: [CFStringEncoding], refersToEncodingTag: Bool) throws -> (String, String.Encoding) {
        
        // try interpreting with xattr encoding
        if let xattrEncoding = xattrEncoding {
            // just trust xattr encoding if content is empty
            if let string = data.isEmpty ? "" : String(bomCapableData: data, encoding: xattrEncoding) {
                return (string, xattrEncoding)
            }
        }
        
        // detect encoding from data
        var usedEncoding: String.Encoding?
        let string = try String(data: data, suggestedCFEncodings: suggestedCFEncodings, usedEncoding: &usedEncoding)
        
        // try reading encoding declaration and take priority of it if it seems well
        if refersToEncodingTag,
            let scannedEncoding = string.scanEncodingDeclaration(upTo: self.maxEncodingScanLength, suggestedCFEncodings: suggestedCFEncodings),
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
