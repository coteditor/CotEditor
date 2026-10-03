//
//  RMateMessage.swift
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

/// A message in the TextMate remote editing protocol.
struct RMateMessage: Equatable, Sendable {
    
    var command: String
    var headers: [String: String] = [:]
    var data = Data()
    
    
    /// Encodes the message for sending to the client.
    ///
    /// - Returns: The encoded message.
    func encoded() -> Data {
        
        var result = Data("\(self.command)\n".utf8)
        
        for (key, value) in self.headers.sorted(by: { $0.key < $1.key }) {
            result.append(Data("\(key): \(value)\n".utf8))
        }
        
        if self.command == "save" {
            // data lengths are measured in bytes
            result.append(Data("data: \(self.data.count)\n".utf8))
            result.append(self.data)
        }
        result.append(0x0A)
        
        return result
    }
}
