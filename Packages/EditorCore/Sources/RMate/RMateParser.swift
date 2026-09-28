//
//  RMateParser.swift
//  RMate
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-09-28.
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

/// A parser for `rmate` requests received in chunks.
struct RMateParser {
    
    enum ParseError: Error {
        
        case invalidMessage
        case headerTooLarge
        case fileTooLarge
    }
    
    
    // MARK: Constants
    
    static let maximumDataLength = 100 * 1024 * 1024
    private static let maximumHeaderLength = 64 * 1024
    
    
    // MARK: Internal Properties
    
    private(set) var isFinished = false
    
    
    // MARK: Private Properties
    
    private var buffer = Data()
    private var message: RMateMessage?
    private var remainingDataLength = 0
    private var headerLength = 0
    
    
    // MARK: Public Methods
    
    /// Parses the received data.
    ///
    /// - Parameter data: The data to append to the receive buffer.
    /// - Returns: The complete messages, in the order received.
    /// - Throws: `ParseError` if the data is invalid or exceeds the size limit.
    mutating func append(_ data: Data) throws(ParseError) -> [RMateMessage] {
        
        guard !self.isFinished else {
            guard data.isEmpty else { throw .invalidMessage }
            
            return []
        }
        
        self.buffer.append(data)
        var messages: [RMateMessage] = []
        
        while !self.buffer.isEmpty {
            if self.remainingDataLength > 0 {
                let count = min(self.remainingDataLength, self.buffer.count)
                self.message!.data.append(self.buffer.prefix(count))
                self.buffer.removeFirst(count)
                self.remainingDataLength -= count
                continue
            }
            
            guard let newline = self.buffer.firstIndex(of: 0x0A) else {
                guard self.buffer.count <= Self.maximumHeaderLength else { throw .headerTooLarge }
                break
            }
            
            let bytes = self.buffer[..<newline]
            
            guard
                bytes.count <= Self.maximumHeaderLength,
                var line = String(data: bytes, encoding: .utf8)
            else { throw ParseError.invalidMessage }
            
            self.buffer.removeSubrange(...newline)
            if line.last == "\r" {
                line.removeLast()
            }
            
            if self.message == nil {
                if line.isEmpty { continue }
                
                if line == "." {
                    guard self.buffer.isEmpty else { throw .invalidMessage }
                    
                    self.isFinished = true
                    break
                }
                
                guard line == "open" else { throw .invalidMessage }
                
                self.message = RMateMessage(command: line)
                self.headerLength = 0
                
                continue
            }
            
            if line.isEmpty {
                messages.append(self.message!)
                self.message = nil
                continue
            }
            
            try self.readHeader(line)
        }
        
        return messages
    }
    
    
    // MARK: Private Methods
    
    /// Parses a header line.
    ///
    /// - Parameter line: A header without its line terminator.
    /// - Throws: `ParseError` if the header is invalid or exceeds the size limit.
    private mutating func readHeader(_ line: String) throws(ParseError) {
        
        self.headerLength += line.utf8.count
        
        guard self.headerLength <= Self.maximumHeaderLength else { throw .headerTooLarge }
        
        guard let separator = line.range(of: ": ") else { throw .invalidMessage }
        
        let key = String(line[..<separator.lowerBound])
        let value = String(line[separator.upperBound...])
        
        if key == "data" {
            guard let length = Int(value), length >= 0 else { throw .invalidMessage }
            guard length <= Self.maximumDataLength - self.message!.data.count else { throw .fileTooLarge }
            
            self.remainingDataLength = length
        } else {
            guard !key.isEmpty, !value.contains("\r"), !value.contains("\0") else { throw .invalidMessage }
            
            self.message!.headers[key] = value
        }
    }
}
