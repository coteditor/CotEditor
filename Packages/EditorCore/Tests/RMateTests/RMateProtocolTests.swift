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
    
    
    /// Tests the cumulative data size limit before receiving the file content.
    ///
    /// - Parameter initialDataLength: The length of a preceding data block.
    /// - Throws: An error if a valid request header is rejected.
    @Test(arguments: [0, 1]) func dataSizeLimit(initialDataLength: Int) throws {
        
        var parser = RMateParser()
        var wire = Data("open\ndata: \(initialDataLength)\n".utf8)
        wire.append(Data(repeating: 65, count: initialDataLength))
        #expect(try parser.append(wire).isEmpty)
        var oversizedParser = parser
        
        let remainingLength = RMateParser.maximumDataLength - initialDataLength
        #expect(try parser.append(Data("data: \(remainingLength)\n".utf8)).isEmpty)
        #expect(throws: RMateParser.ParseError.fileTooLarge) {
            try oversizedParser.append(Data("data: \(remainingLength + 1)\n".utf8))
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
