//
//  String+Encodings.swift
//  FileEncoding
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-01-16.
//
//  ---------------------------------------------------------------------------
//
//  © 2004-2007 nakamuxu
//  © 2014-2026 1024jp
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

public import Foundation

public extension String {
    
    enum DecodingStrategy: Sendable {
        
        case automatic(String.DetectionOptions)
        case specific(String.Encoding)
    }
    
    
    struct DetectionOptions: Sendable {
        
        /// The list of encodings to test the encoding.
        public var candidates: [String.Encoding]
        
        /// The text encoding read from the file's extended attributes.
        public var xattrEncoding: String.Encoding?
        
        /// Whether to scan for and prioritize an encoding declaration in the contents.
        public var considersDeclaration: Bool
        
        
        public init(candidates: [String.Encoding], xattrEncoding: String.Encoding? = nil, considersDeclaration: Bool = false) {
            
            self.candidates = candidates
            self.xattrEncoding = xattrEncoding
            self.considersDeclaration = considersDeclaration
        }
    }
    
    
    /// An array of the encodings that strings support in the application’s environment. `nil` for section divider.
    static let sortedAvailableStringEncodings: [String.Encoding?] = Self.availableStringEncodings
        .sorted {
            String.localizedName(of: $0).localizedCaseInsensitiveCompare(String.localizedName(of: $1)) == .orderedAscending
        }
        .reduce(into: []) { encodings, encoding in
            if let last = encodings.last as? String.Encoding,
               let lastName = String.localizedName(of: last).prefixMatch(of: /\w+/),
               let name = String.localizedName(of: encoding).prefixMatch(of: /\w+/),
               lastName.output != name.output
            {
                encodings.append(nil)
            }
            encodings.append(encoding)
        }
    
    
    /// Reads file at the given URL and initialize.
    ///
    /// - Parameters:
    ///   - data: The content file.
    ///   - decodingStrategy: The text encoding to read the file.
    static func string(data: Data, decodingStrategy: String.DecodingStrategy) throws(CocoaError) -> (String, FileEncoding) {
        
        // decode Data to String
        let content: String
        let encoding: String.Encoding
        switch decodingStrategy {
            case .automatic(let options):
                (content, encoding) = try String.string(data: data, options: options)
            case .specific(let readingEncoding):
                guard let string = String(bomCapableData: data, encoding: readingEncoding) else {
                    throw CocoaError(.fileReadInapplicableStringEncoding, userInfo: [NSStringEncodingErrorKey: readingEncoding.rawValue])
                }
                content = string
                encoding = readingEncoding
        }
        
        let hasUTF8BOM = (encoding == .utf8) && data.starts(with: Unicode.BOM.utf8.sequence)
        let fileEncoding = FileEncoding(encoding: encoding, withUTF8BOM: hasUTF8BOM)
        
        return (content, fileEncoding)
    }
    
    
    /// Converts Yen signs (`U+00A5`) in consideration of the encoding.
    ///
    /// - Parameter encoding: The text encoding to keep compatibility.
    /// - Returns: A new string converted all Yen signs.
    func convertYenSign(for encoding: String.Encoding) -> String {
        
        "¥".canBeConverted(to: encoding) ? self : self.replacing("¥", with: "\\")
    }
}


extension String {
    
    /// Reads string from data by detecting the text encoding automatically.
    ///
    /// - Parameters:
    ///   - data: The data to encode.
    ///   - options: The options for encoding detection.
    /// - Returns: The decoded string and used encoding.
    static func string(data: Data, options: String.DetectionOptions) throws(CocoaError) -> (String, String.Encoding) {
        
        // try interpreting with xattr encoding
        if let xattrEncoding = options.xattrEncoding {
            // just trust xattr encoding if the content is empty
            if let string = data.isEmpty ? "" : String(bomCapableData: data, encoding: xattrEncoding) {
                return (string, xattrEncoding)
            }
        }
        
        // try reading encoding declaration and take priority of it if it seems well
        if options.considersDeclaration,
           let encoding = data.scanEncodingDeclaration(),
           options.candidates.contains(encoding),
           let string = String(bomCapableData: data, encoding: encoding)
        {
            return (string, encoding)
        }
        
        // detect encoding from data
        var usedEncoding: String.Encoding?
        let string = try String(data: data, suggestedEncodings: options.candidates, usedEncoding: &usedEncoding)
        if let encoding = usedEncoding {
            return (string, encoding)
        }
        
        throw CocoaError(.fileReadUnknownStringEncoding)
    }
    
    
    /// Returns a  `String` initialized by converting given `data` into Unicode characters using an intelligent encoding detection.
    ///
    /// - Parameters:
    ///   - data: The data object containing the string data.
    ///   - suggestedEncodings: The prioritized list of encoding candidates.
    ///   - usedEncoding: The encoding used to interpret the data.
    /// - Throws: `CocoaError(.fileReadUnknownStringEncoding)`
    init(data: Data, suggestedEncodings: [String.Encoding], usedEncoding: inout String.Encoding?) throws(CocoaError) {
        
        // check BOMs
        for bom in Unicode.BOM.allCases {
            guard
                data.starts(with: bom.sequence),
                let string = String(bomCapableData: data, encoding: bom.encoding)
            else { continue }
            
            usedEncoding = bom.encoding
            self = string
            return
        }
        
        // try encodings in order from the top of the encoding list
        for encoding in suggestedEncodings {
            guard let string = String(data: data, encoding: encoding) else { continue }
            
            usedEncoding = encoding
            self = string
            return
        }
        
        throw CocoaError(.fileReadUnknownStringEncoding)
    }
    
    
    /// Decodes data and remove UTF-8 BOM if exists.
    ///
    /// cf. <https://bugs.swift.org/browse/SR-10173>
    @available(macOS, deprecated: 26, message: "The issue has been resolved since macOS 26.")
    init?(bomCapableData data: Data, encoding: String.Encoding) {
        
        guard #unavailable(macOS 26) else {
            self.init(data: data, encoding: encoding)
            return
        }
        
        let bom = Unicode.BOM.utf8.sequence
        let hasUTF8WithBOM = (encoding == .utf8 && data.starts(with: bom))
        let bomFreeData = hasUTF8WithBOM ? data[bom.count...] : data
        
        self.init(data: bomFreeData, encoding: encoding)
    }
}


extension Data {
    
    /// Scans for a text encoding declaration.
    ///
    /// Supported declaration styles and their typical contexts:
    /// - CSS: `@charset`
    ///   - At the very beginning of the file.
    ///   - Uses an IANA charset name.
    /// - HTML: `charset=`
    ///   - Within the first 1,024 bytes.
    ///   - Uses an IANA charset name.
    /// - XML: `encoding=`
    ///   - Inside the `<?xml ...?>` declaration, which must appear at the beginning of the file.
    ///   - Uses an IANA charset name.
    /// - Python: `coding:`, `encoding:`, `coding=`
    ///   - Within the first 2 lines.
    ///   - Defined in PEP 263.
    ///   - `^[ \t\f]*#.*?coding[:=][ \t]*([-_.a-zA-Z0-9]+)`
    /// - Ruby: `coding: `  or `encoding: `
    ///   - Within the first 2 lines.
    /// - Emacs: `-*- ... coding: `
    ///   - Within the first 2 lines.
    /// - Vim: `fileencoding=`
    ///   - Within the first or last 5 lines (Only the first 2 lines are supported here).
    ///
    /// - Returns: The detected string encoding, or `nil` if none is found.
    func scanEncodingDeclaration() -> String.Encoding? {
        
        guard
            !self.isEmpty,
            // scan only the first 1024 bytes to fulfill the largest spec (HTML)
            let string = String(data: self.prefix(1024), encoding: .isoLatin1),
            let match = string.prefixMatch(of: /@charset "(?<encoding>[-_.a-zA-Z0-9]+)";/)
                ?? string
                    .split(separator: /\R/, maxSplits: 3, omittingEmptySubsequences: false)
                    .prefix(2)  // first 2 lines
                    .lazy
                    .compactMap({ $0.firstMatch(of: /coding[:=] *["']? *(?<encoding>[-_.a-zA-Z0-9]+)/) }).first
                ?? string.firstMatch(of: /^[\x00-\x7F]*\scharset\s*= *["'](?<encoding>[-_.a-zA-Z0-9]+)["']/.ignoresCase())
        else { return nil }
        
        let encodingName = match.encoding
        
        let cfEncoding = CFStringConvertIANACharSetNameToEncoding(encodingName as CFString)
        if cfEncoding != kCFStringEncodingInvalidId {
            return String.Encoding(cfEncoding: cfEncoding)
        }
        
        return nil
    }
}
