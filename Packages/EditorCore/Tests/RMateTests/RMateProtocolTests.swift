//
//  RMateProtocolTests.swift
//  RMateTests
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
import Testing
@testable import RMate

struct RMateProtocolTests {
    
    @Test(arguments: [1, 2, 7, 64 * 1024]) func fragmentedRequests(chunkSize: Int) throws {
        
        let content = Data([0, 10, 13, 255]) + Data("日本語\n.\nopen\n".utf8)
        var wire = Data("open\r\ndisplay-name: host:file.txt\r\ntoken: /tmp/file.txt\r\nnew: yes\r\ndata-on-save: yes\r\ndata: \(content.count)\r\n".utf8)
        wire.append(content)
        wire.append(Data("\r\n\nopen\ntoken: empty\ndata-on-save: yes\ndata: 0\n\n.\n".utf8))
        var parser = RMateParser()
        var messages: [RMateMessage] = []
        for offset in stride(from: 0, to: wire.count, by: chunkSize) {
            messages += try parser.append(wire.subdata(in: offset..<min(offset + chunkSize, wire.count)))
        }
        #expect(parser.isFinished)
        #expect(messages.count == 2)
        
        let first = try #require(messages.first)
        #expect(first.headers["token"] == "/tmp/file.txt")
        #expect(first.data == content)
        #expect(messages.last?.data.isEmpty == true)
    }
    
    
    /// Tests that file type hints are passed to the editor without interpreting their names.
    ///
    /// - Parameter fileType: The requested file type, or `nil` if omitted.
    /// - Throws: An error if parsing the open request fails.
    @Test(arguments: [nil, "", "Python", "Plain Text", "source.python", "py"] as [String?])
    func openRequestFileType(fileType: String?) throws {
        
        let header = fileType.map { "file-type: \($0)\n" } ?? ""
        var parser = RMateParser()
        let messages = try parser.append(Data("open\ntoken: file\n\(header)data: 0\n\n.\n".utf8))
        let request = RMateOpenRequest(message: try #require(messages.first))
        
        #expect(request.fileType == fileType)
    }
    
    
    @Test func multipleDataBlocks() throws {
        
        var parser = RMateParser()
        let messages = try parser.append(Data("open\ntoken: f\ndata: 3\nabcdata: 2\nde\n.\n".utf8))
        #expect(messages.first?.data == Data("abcde".utf8))
        #expect(parser.isFinished)
    }
    
    
    @Test(arguments: ["data: -1", "data: nope", "broken", "token: bad\rvalue"])
    func invalidHeaders(header: String) {
        
        var parser = RMateParser()
        
        #expect(throws: RMateParser.ParseError.invalidMessage) {
            try parser.append(Data("open\n\(header)\n".utf8))
        }
    }
    
    
    /// Tests that data exceeding the cumulative size limit is discarded without affecting the following requests.
    ///
    /// - Parameter initialDataLength: The length of a preceding data block.
    /// - Throws: An error if parsing the requests fails.
    @Test(arguments: [0, 1]) func dataSizeLimit(initialDataLength: Int) throws {
        
        /// Appends a data block of the given length in chunks.
        ///
        /// - Parameters:
        ///   - length: The length of the data block.
        ///   - parser: The parser to append to.
        /// - Returns: The complete messages.
        func appendData(length: Int, to parser: inout RMateParser) throws -> [RMateMessage] {
            
            let chunk = Data(repeating: 65, count: 1024 * 1024)
            var messages = try parser.append(Data("data: \(length)\n".utf8))
            for offset in stride(from: 0, to: length, by: chunk.count) {
                messages += try parser.append(chunk.prefix(length - offset))
            }
            return messages
        }
        
        let remainingLength = RMateParser.maximumDataLength - initialDataLength
        
        for (length, isTooLarge) in [(remainingLength, false), (remainingLength + 1, true)] {
            var parser = RMateParser()
            var messages = try parser.append(Data("open\ntoken: a\ndata-on-save: yes\n".utf8))
            messages += try appendData(length: initialDataLength, to: &parser)
            messages += try appendData(length: length, to: &parser)
            messages += try parser.append(Data("\nopen\ntoken: b\ndata-on-save: yes\ndata: 1\nB\n\n.\n".utf8))
            
            #expect(parser.isFinished)
            #expect(messages.map { $0.headers["token"] } == ["a", "b"])
            #expect(messages.first?.isTooLarge == isTooLarge)
            #expect(messages.first?.data.count == (isTooLarge ? 0 : RMateParser.maximumDataLength))
            #expect(messages.last?.isTooLarge == false)
            #expect(messages.last?.data == Data("B".utf8))
        }
    }
    
    
    @Test func oversizedHeader() {
        
        var parser = RMateParser()
        
        #expect(throws: RMateParser.ParseError.headerTooLarge) {
            try parser.append(Data(repeating: 65, count: 65537))
        }
    }
    
    
    @Test func responseUsesByteLength() {
        
        let message = RMateMessage(command: "save", headers: ["token": "/tmp/a"], data: Data("あ\n".utf8))
        #expect(message.encoded() == Data("save\ntoken: /tmp/a\ndata: 4\nあ\n\n".utf8))
        #expect(RMateMessage(command: "close", headers: ["token": "x"]).encoded() == Data("close\ntoken: x\n\n".utf8))
    }
}
