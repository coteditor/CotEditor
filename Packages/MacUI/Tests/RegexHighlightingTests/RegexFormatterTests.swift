//
//  RegexFormatterTests.swift
//  RegexHighlightingTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-02-08.
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
@testable import RegexHighlighting

struct RegexFormatterTests {
    
    private let theme = RegexTheme<NSColor>(
        character: .systemRed,
        backReference: .systemGreen,
        symbol: .systemBlue,
        quantifier: .systemOrange,
        anchor: .systemPurple,
        invisible: .systemGray
    )
    
    
    @Test func highlightCharacter() {
        
        let formatter = RegexFormatter(theme: self.theme)
        let attributed = formatter.attributedString(for: ".")
        
        #expect(unsafe (attributed?.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? NSColor) == NSColor.systemRed)
    }
    
    
    @Test func replacesInvisiblesWhenParsingDisabled() {
        
        let formatter = RegexFormatter(theme: self.theme)
        formatter.parsesRegularExpression = false
        
        let attributed = formatter.attributedString(for: "a\n\t\u{3000}")
        
        #expect(attributed?.string == "a↩→□")
    }
    
    
    @Test func invalidRegexSkipsInvisibleReplacement() {
        
        let formatter = RegexFormatter(theme: self.theme)
        let attributed = formatter.attributedString(for: "(\n")
        
        #expect(attributed?.string == "(\n")
    }
}
