//
//  EditorCounterTests.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2020-01-25.
//
//  ---------------------------------------------------------------------------
//
//  © 2020-2026 1024jp
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
import LineEnding
@testable import CotEditor

@MainActor final class EditorCounterTests {
    
    final class Source: EditorCounter.Source {
        
        var string: String
        var selectedRanges: [NSValue]
        
        
        init(string: String, selectedRange: NSRange) {
            
            self.string = string
            self.selectedRanges = [selectedRange] as [NSValue]
        }
    }
    
    
    private let testString = """
        dog is 🐕.
        cow is 🐄.
        Both are 👍🏼.
        """
    
    @Test func noRequiredInfo() throws {
        
        let source = Source(string: self.testString, selectedRange: NSRange(0..<3))
        
        let counter = EditorCounter()
        counter.source = { source }
        counter.invalidateContent()
        counter.invalidateSelection()
        
        #expect(counter.result.lines.entire == nil)
        #expect(counter.result.characters.entire == nil)
        #expect(counter.result.words.entire == nil)
        #expect(counter.result.location == nil)
        #expect(counter.result.line == nil)
        #expect(counter.result.column == nil)
    }
    
    
    @Test func allRequiredInfo() async throws {
        
        let source = Source(string: self.testString, selectedRange: NSRange(11..<21))
        
        let counter = EditorCounter()
        defer { counter.cancel() }
        counter.source = { source }
        
        await withCheckedContinuation { continuation in
            withObservationTracking {
                _ = counter.result.column
            } onChange: {
                continuation.resume()
            }
            
            counter.updatesAll = true
        }
        
        #expect(counter.result.lines.entire == 3)
        #expect(counter.result.characters.entire == 31)
        #expect(counter.result.words.entire == 6)
        
        #expect(counter.result.characters.selected == 9)
        #expect(counter.result.lines.selected == 1)
        #expect(counter.result.words.selected == 2)
        
        #expect(counter.result.location == 10)
        #expect(counter.result.column == 0)
        #expect(counter.result.line == 2)
    }
    
    
    @Test func skipWholeText() async throws {
        
        let source = Source(string: self.testString, selectedRange: NSRange(11..<21))
        
        let counter = EditorCounter()
        defer { counter.cancel() }
        counter.source = { source }
        counter.updatesAll = true
        counter.cancel()
        
        await withCheckedContinuation { continuation in
            withObservationTracking {
                _ = counter.result.column
            } onChange: {
                continuation.resume()
            }
            
            counter.invalidateSelection()
        }
        
        #expect(counter.result.lines.entire == nil)
        #expect(counter.result.characters.entire == nil)
        #expect(counter.result.words.entire == nil)
        
        #expect(counter.result.lines.selected == 1)
        #expect(counter.result.characters.selected == 9)
        #expect(counter.result.words.selected == 2)
        
        #expect(counter.result.location == 10)
        #expect(counter.result.column == 0)
        #expect(counter.result.line == 2)
    }
    
    
    @Test func crlf() async throws {
        
        let source = Source(string: "a\r\nb", selectedRange: NSRange(1..<4))
        
        let counter = EditorCounter()
        defer { counter.cancel() }
        counter.source = { source }
        
        await withCheckedContinuation { continuation in
            withObservationTracking {
                _ = counter.result.column
            } onChange: {
                continuation.resume()
            }
            
            counter.updatesAll = true
        }
        
        #expect(counter.result.lines.entire == 2)
        #expect(counter.result.characters.entire == 3)
        #expect(counter.result.words.entire == 2)
        
        #expect(counter.result.lines.selected == 2)
        #expect(counter.result.characters.selected == 2)
        #expect(counter.result.words.selected == 1)
        
        #expect(counter.result.location == 1)
        #expect(counter.result.column == 1)
        #expect(counter.result.line == 1)
    }
    
    
    @Test func entireLineCountUsesLineRangeCalculator() async throws {
        
        let string = "a\nb\n"
        let lineCounter = LineCounter(string: string)
        let source = Source(string: string, selectedRange: NSRange(location: string.utf16.count, length: 0))
        
        let counter = EditorCounter()
        defer { counter.cancel() }
        counter.source = { source }
        counter.lineRangeCalculator = lineCounter
        
        await withCheckedContinuation { continuation in
            withObservationTracking {
                _ = counter.result.lines.entire
            } onChange: {
                continuation.resume()
            }
            
            counter.statusBarRequirements = [.lines]
        }
        
        #expect(counter.result.lines.entire == 2)
        #expect(!lineCounter.lineEndings.isEmpty)
    }
    
    
    @Test func currentLineUsesLineRangeCalculator() async throws {
        
        let string = "a\n🐕b\nc"
        let lineCounter = LineCounter(string: string)
        let source = Source(string: string, selectedRange: (string as NSString).range(of: "b"))
        
        let counter = EditorCounter()
        defer { counter.cancel() }
        counter.source = { source }
        counter.lineRangeCalculator = lineCounter
        
        await withCheckedContinuation { continuation in
            withObservationTracking {
                _ = counter.result.line
            } onChange: {
                continuation.resume()
            }
            
            counter.statusBarRequirements = [.line]
        }
        
        #expect(counter.result.line == 2)
        #expect(!lineCounter.lineEndings.isEmpty)
    }
    
    
    @Test func formatEditorCount() {
        
        var count = EditorCount()
        
        #expect(count.formatted == nil)
        
        count.entire = 1000
        #expect(count.formatted == "1,000")
        
        count.selected = 100
        #expect(count.formatted == "1,000 (100)")
        
        count.entire = nil
        #expect(count.formatted == nil)
    }
}
