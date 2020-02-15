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
//  © 2018-2020 1024jp
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
}



struct DocumentFile {
    
    /// Maximal length to scan encoding declaration
    private static let maxEncodingScanLength = 2000
    
    
    // MARK: Properties
    
    let data: Data
    let string: String
    let attributes: [FileAttributeKey: Any]
    let lineEnding: LineEnding?
    let encoding: String.Encoding
    let hasUTF8BOM: Bool
    let xattrEncoding: String.Encoding?
    let isVerticalText: Bool
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    init(fileURL: URL, readingEncoding: String.Encoding, defaults: UserDefaults = .standard) throws {
        
        let data = try Data(contentsOf: fileURL)  // FILE_READ
        let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)  // FILE_READ
        
        // check extended attributes
        let extendedAttributes = attributes[.extendedAttributes] as? [String: Data]
        self.xattrEncoding = extendedAttributes?[FileExtendedAttributeName.encoding]?.decodingXattrEncoding
        self.isVerticalText = (extendedAttributes?[FileExtendedAttributeName.verticalText] != nil)
        
        // decode Data to String
        let content: String
        let encoding: String.Encoding
        switch readingEncoding {
        case .autoDetection:
            (content, encoding) = try Self.string(data: data, xattrEncoding: self.xattrEncoding,
                                                  suggestedCFEncodings: defaults[.encodingList],
                                                  refersToEncodingTag: defaults[.referToEncodingTag])
        default:
            encoding = readingEncoding
            if !data.isEmpty {
                content = try String(contentsOf: fileURL, encoding: encoding)  // FILE_READ
            } else {
                content = ""
            }
        }
        
        // set properties
        self.data = data
        self.attributes = attributes
        self.string = content
        self.encoding = encoding
        self.hasUTF8BOM = (encoding == .utf8) && data.starts(with: UTF8.bom)
        self.lineEnding = content.detectedLineEnding
    }
    
    
    
    // MARK: Private Methods
    
    /// read String from Dada detecting file encoding automatically
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
