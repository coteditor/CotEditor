//
//  SyntaxControllerTests.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-02-16.
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

import AppKit
import Testing
import ValueRange
import Syntax
@testable import CotEditor

@MainActor struct SyntaxControllerTests {
    
    @Test func highlightApplies() async throws {
        
        let (controller, layoutManager, _) = self.makeController(
            text: "foo bar",
            syntax: Syntax(highlights: [.keywords: [Syntax.Highlight(begin: "foo")]])
        )
        
        controller.setupParser()
        
        let didHighlight = await self.waitFor {
            !layoutManager.syntaxHighlights().isEmpty
        }
        
        #expect(didHighlight)
        
        let highlights = layoutManager.syntaxHighlights()
        let highlight = try #require(highlights.first)
        #expect(highlights.count == 1)
        #expect(highlight.value == .keywords)
        #expect(highlight.range == NSRange(0..<3))
    }
    
    
    @Test func updateClearsHighlights() async {
        
        let (controller, layoutManager, _) = self.makeController(
            text: "foo bar",
            syntax: Syntax(highlights: [.keywords: [Syntax.Highlight(begin: "foo")]])
        )
        
        controller.setupParser()
        
        let didHighlight = await self.waitFor {
            !layoutManager.syntaxHighlights().isEmpty
        }
        #expect(didHighlight)
        
        controller.update(syntax: Syntax(), name: "UnitTest-Empty")
        
        let didClear = await self.waitFor {
            layoutManager.syntaxHighlights().isEmpty
        }
        
        #expect(didClear)
        #expect(controller.syntaxName == "UnitTest-Empty")
    }
    
    
    @Test func outlineItemsUpdate() async throws {
        
        let syntax = Syntax(outlines: [
            Syntax.Outline(pattern: "^##\\s+(.+)$", template: "$1", kind: .heading),
        ])
        
        let (controller, _, _) = self.makeController(
            text: "## Heading\nBody",
            syntax: syntax
        )
        
        controller.setupParser()
        
        let didParseOutline = await self.waitFor {
            controller.outlineItems?.isEmpty == false
        }
        
        #expect(didParseOutline)
        
        let outlineItems = controller.outlineItems ?? []
        let item = try #require(outlineItems.first)
        #expect(outlineItems.count == 1)
        #expect(item.title == "Heading")
        #expect(item.range == NSRange(0..<10))
        #expect(item.kind == .heading)
        #expect(item.style.isEmpty)
    }
    
    
    // MARK: Private Methods
    
    private func makeController(text: String, syntax: Syntax) -> (SyntaxController, NSLayoutManager, NSTextStorage) {
        
        let textStorage = NSTextStorage(string: text)
        let layoutManager = TestLayoutManager()
        textStorage.addLayoutManager(layoutManager)
        
        let controller = SyntaxController(textStorage: textStorage, syntax: syntax, name: "mock")
        
        return (controller, layoutManager, textStorage)
    }
    
    
    private func waitFor(timeout: Duration = .seconds(2), interval: Duration = .milliseconds(20), _ condition: @escaping () -> Bool) async -> Bool {
        
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: timeout)
        
        while clock.now < deadline {
            if condition() { return true }
            try? await Task.sleep(for: interval)
        }
        
        return condition()
    }
}


private final class TestLayoutManager: NSLayoutManager, ValidationIgnorable {
    
    var ignoresDisplayValidation = false
    
    
    override func invalidateDisplay(forCharacterRange charRange: NSRange) {
        
        guard !self.ignoresDisplayValidation else { return }
        super.invalidateDisplay(forCharacterRange: charRange)
    }
}
