//
//  LayoutManagerTests.swift
//  Tests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-05-08.
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
import LineEnding
@testable import CotEditor

struct LayoutManagerTests {
    
    @Test func noLineBreakAfterLeadingIndentAtDocumentStart() {
        
        let textStorage = NSTextStorage(string: "    dog")
        let layoutManager = LayoutManager(lineEndingScanner: LineEndingScanner(textStorage: textStorage, lineEnding: .lf))
        textStorage.addLayoutManager(layoutManager)
        
        #expect(!layoutManager.layoutManager(layoutManager, shouldBreakLineByWordBeforeCharacterAt: 4))
    }
    
    
    @MainActor @Test func changingHangingIndentAttributesKeepsExtraLineFragmentInEmptyDocument() {
        
        let textStorage = NSTextStorage(string: "")
        let layoutManager = LayoutManager(lineEndingScanner: LineEndingScanner(textStorage: textStorage, lineEnding: .lf))
        let textContainer = TextContainer()
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        layoutManager.ensureLayout(for: textContainer)
        
        #expect(!layoutManager.extraLineFragmentRect.isEmpty)
        
        textContainer.spaceWidth = 4
        textContainer.isHangingIndentEnabled = true
        textContainer.hangingIndentWidth = 2
        
        #expect(!layoutManager.extraLineFragmentRect.isEmpty)
    }
}
