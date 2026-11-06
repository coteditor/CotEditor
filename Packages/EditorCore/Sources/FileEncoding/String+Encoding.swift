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
        
        /// The list of encodings to test decoding.
        public var candidates: [String.Encoding]
        
        /// The text encoding read from the file's extended attributes.
        public var xattrEncoding: String.Encoding?
        
        /// Whether to scan for and prioritize an encoding declaration in the contents.
        public var respectsDeclaration: Bool
        
        
        public init(candidates: [String.Encoding], xattrEncoding: String.Encoding? = nil, respectsDeclaration: Bool = false) {
            
            self.candidates = candidates
            self.xattrEncoding = xattrEncoding
            self.respectsDeclaration = respectsDeclaration
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
    /// - Returns: The decoded string and detected file encoding.
    static func string(data: Data, decodingStrategy: String.DecodingStrategy) throws(CocoaError) -> (String, FileEncoding) {
        
        // decode Data to String
        let content: String
        let encoding: String.Encoding
        switch decodingStrategy {
            case .automatic(let options):
                (content, encoding) = try String.string(data: data, options: options)
            case .specific(let readingEncoding):
                guard let string = String(data: data, encoding: readingEncoding) else {
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
    /// - Returns: A new string with all Yen signs converted.
    func convertYenSign(for encoding: String.Encoding) -> String {
        
        "¥".canBeConverted(to: encoding) ? self : self.replacingOccurrences(of: "¥", with: "\\", options: .literal)
    }
    
    
    /// Encodes the string in the given encoding, replacing the characters that the encoding cannot represent.
    ///
    /// - Note: Use this method for arbitrary text to workaround the issue that `data(using:allowLossyConversion:)` can raise an exception,
    ///         return `nil`, or never return, for example, with a combining mark after a composed character (2026-11, macOS 27).
    ///
    /// - Parameters:
    ///   - encoding: The text encoding to convert to.
    /// - Returns: The encoded data.
    func lossyData(using encoding: String.Encoding) -> Data {
        
        // -> `String` converts these encodings by itself, and the conversion always reaches the end.
        //    `.ascii` is not one of them to workaround `String` writing 0xFF for the characters out of ASCII (2026-11, macOS 27).
        if encoding.isUnicodeEncoding || encoding == .nonLossyASCII,
           let data = self.data(using: encoding, allowLossyConversion: true)
        {
            return data
        }
        
        let string = self as NSString
        
        // workaround the issue that the conversion may never return when the buffer gets full (2026-11, macOS 27)
        // -> Neither `maximumLengthOfBytes(using:)` nor counting the bytes in advance is enough for all encodings.
        //    Thus, reserve the size for the longest output.
        return withUnsafeTemporaryAllocation(of: UInt8.self, capacity: (string.length + 10) * 8) { buffer in
            // workaround the issue that the conversion can report more bytes than it wrote in some encodings,
            // which never exceed the maximum length (2026-11, macOS 27)
            unsafe buffer.prefix(string.maximumLengthOfBytes(using: encoding.rawValue)).initialize(repeating: 0)
            
            var data = Data()
            var options: NSString.EncodingConversionOptions = [.allowLossy, .externalRepresentation]
            var location = 0
            
            // workaround the issue that `getBytes(...)` can stop before the end even with `.allowLossy` (2026-11, macOS 27)
            while location < string.length {
                var usedLength = 0
                var remaining = NSRange()
                
                unsafe string.getBytes(buffer.baseAddress, maxLength: buffer.count, usedLength: &usedLength, encoding: encoding.rawValue, options: options, range: NSRange(location..<string.length), remaining: &remaining)
                unsafe data.append(contentsOf: buffer[..<usedLength])
                options.remove(.externalRepresentation)
                
                if remaining.location > location {
                    location = remaining.location
                } else {
                    // replace the character that cannot be converted at all
                    data.append(contentsOf: "?".utf8)
                    location += 1
                }
            }
            
            return data
        }
    }
}


extension String {
    
    /// Reads string from data by detecting the text encoding based on the detection options.
    ///
    /// - Parameters:
    ///   - data: The data to encode.
    ///   - options: The options for encoding detection.
    /// - Returns: The decoded string and used encoding.
    /// - Throws: `CocoaError(.fileReadUnknownStringEncoding)`
    static func string(data: Data, options: String.DetectionOptions) throws(CocoaError) -> (String, String.Encoding) {
        
        // check BOMs
        for bom in Unicode.BOM.allCases {
            if options.candidates.contains(where: bom.candidateEncodings.contains),
               data.starts(with: bom.sequence),
               let string = String(data: data, encoding: bom.encoding)
            {
                return (string, bom.encoding)
            }
        }
        
        // try interpreting with xattr encoding
        if let xattrEncoding = options.xattrEncoding {
            // just trust xattr encoding if the content is empty
            if let string = data.isEmpty ? "" : String(data: data, encoding: xattrEncoding) {
                return (string, xattrEncoding)
            }
        }
        
        // try reading encoding declaration and take priority of it if it seems well
        if options.respectsDeclaration,
           let encoding = data.scanEncodingDeclaration(),
           options.candidates.contains(encoding),
           let string = String(data: data, encoding: encoding)
        {
            return (string, encoding)
        }
        
        // try applying encodings in order from the top of the candidates
        for encoding in options.candidates {
            if let string = String(data: data, encoding: encoding) {
                return (string, encoding)
            }
        }
        
        throw CocoaError(.fileReadUnknownStringEncoding)
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
        
        struct EncodingDeclaration {
            
            var range: Range<String.Index>
            var encodingName: Substring
        }
        
        guard
            !self.isEmpty,
            // scan only the first 1024 bytes to fulfill the largest spec (HTML)
            let string = String(data: self.prefix(1024), encoding: .isoLatin1)
        else { return nil }
        
        let cssDeclaration = string.prefixMatch(of: /@charset "(?<encoding>[-_.a-zA-Z0-9]+)";/)
            .map { EncodingDeclaration(range: $0.range, encodingName: $0.encoding) }
        
        let commentDeclaration = string
            .split(maxSplits: 3, omittingEmptySubsequences: false, whereSeparator: \.isNewline)
            .prefix(2)  // first 2 lines
            .lazy
            .compactMap { line in
                line.firstMatch(of: /(?:(?:file)?encoding|coding)[:=] *["']? *(?<encoding>[-_.a-zA-Z0-9]+)/)
                    .map { EncodingDeclaration(range: $0.range, encodingName: $0.encoding) }
            }
            .first
        
        let htmlDeclaration = string.firstMatch(of: /\scharset\s*= *["'](?<encoding>[-_.a-zA-Z0-9]+)["']/.ignoresCase())
            .flatMap { match in
                string[..<match.range.lowerBound].unicodeScalars.allSatisfy(\.isASCII)
                    ? EncodingDeclaration(range: match.range, encodingName: match.encoding)
                    : nil
            }
        
        guard let encodingName = [cssDeclaration, commentDeclaration, htmlDeclaration]
            .compactMap(\.self)
            .min(by: { $0.range.lowerBound < $1.range.lowerBound })?
            .encodingName
        else { return nil }
        
        let cfEncoding = CFStringConvertIANACharSetNameToEncoding(encodingName as CFString)
        
        guard cfEncoding != kCFStringEncodingInvalidId else { return nil }
        
        let encoding = String.Encoding(cfEncoding: cfEncoding)
        
        // -> The declaration was found by reading the data as ASCII. An encoding that reads it differently,
        //    such as UTF-16, cannot be the actual encoding of the data.
        guard String(data: Data(encodingName.utf8), encoding: encoding) == String(encodingName) else { return nil }
        
        return encoding
    }
}
