//
//  RMateOpenRequest.swift
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

public import Foundation

/// The content and options of an `rmate` open request.
public struct RMateOpenRequest: Sendable {
    
    public let data: Data
    public let lineNumber: Int?
    public let fileType: String?
    
    
    /// Initializes an open request from a message.
    ///
    /// - Parameter message: The open message.
    init(message: RMateMessage) {
        
        self.data = message.data
        self.lineNumber = message.headers["selection"].flatMap(Int.init).flatMap { $0 > 0 ? $0 : nil }
        self.fileType = message.headers["file-type"]
    }
}
