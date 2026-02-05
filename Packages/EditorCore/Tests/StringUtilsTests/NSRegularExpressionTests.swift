//
//  NSRegularExpressionTests.swift
//  StringUtilsTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-02-05.
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
//

import Foundation
import Testing
@testable import StringUtils

struct NSRegularExpressionTests {
    
    @Test func cancellableMatches() throws {
        
        let regex = try NSRegularExpression(pattern: "ab")
        let string = "abxxabxab"
        let range = NSRange(location: 0, length: string.utf16.count)
        
        let matches = try regex.cancellableMatches(in: string, range: range)
        
        #expect(matches.count == 3)
        #expect(matches.map(\.range) == [
            NSRange(location: 0, length: 2),
            NSRange(location: 4, length: 2),
            NSRange(location: 7, length: 2),
        ])
    }
    
    
    @Test func cancellableMatchesRange() throws {
        
        let regex = try NSRegularExpression(pattern: "ab")
        let string = "abxxabxab"
        let range = NSRange(location: 2, length: 5)
        
        let matches = try regex.cancellableMatches(in: string, range: range)
        
        #expect(matches.count == 1)
        #expect(matches.first?.range == NSRange(location: 4, length: 2))
    }
    
    
    @Test func cancellableMatchesCancellation() async throws {
        
        let regex = try NSRegularExpression(pattern: "a")
        let string = String(repeating: "a", count: 100_000_000)
        
        let task = Task {
            _ = try regex.cancellableMatches(in: string, range: string.nsRange)
        }
        await Task.yield()
        task.cancel()
        
        await #expect(throws: CancellationError.self) { try await task.value }
    }
}
