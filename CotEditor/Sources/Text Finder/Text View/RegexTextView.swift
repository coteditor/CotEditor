//
//  RegexTextView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-04-05.
//
//  ---------------------------------------------------------------------------
//
//  © 2018-2024 1024jp
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
import RegexHighlighting
import StringUtils

class RegexTextView: NSTextView {
    
    // MARK: Public Properties
    
    var parseMode: RegexParseMode = .search  { didSet { self.invalidateRegularExpression() } }
    var isRegularExpressionMode: Bool = false  { didSet { self.invalidateRegularExpression() } }
    
    private(set) var isValid = true
    
    private let theme: RegexTheme<NSColor> = .default
    
    
    // MARK: Text View Methods
    
    /// The content string did update.
    override func didChangeText() {
        
        // invalidate the pattern before invoking delegates
        self.invalidateRegularExpression()
        
        super.didChangeText()
    }
    
    
    /// Adjusts word selection range.
    override func selectionRange(forProposedRange proposedCharRange: NSRange, granularity: NSSelectionGranularity) -> NSRange {
        
        let range = super.selectionRange(forProposedRange: proposedCharRange, granularity: granularity)
        
        guard
            self.isRegularExpressionMode,
            case .search = self.parseMode,
            granularity == .selectByWord,
            proposedCharRange.isEmpty,  // not on expanding selection
            range.length == 1  // clicked character can be a brace
        else { return range }
        
        let characterIndex = String.Index(utf16Offset: range.lowerBound, in: self.string)
        
        // select inside of brackets
        if let pairRange = self.string.rangeOfBracePair(at: characterIndex, candidates: [BracePair("(", ")"), BracePair("[", "]")], ignoring: BracePair("[", "]")) {
            return NSRange(pairRange, in: self.string)
        }
        
        return range
    }
    
    
    /// The selection did change.
    override func setSelectedRange(_ charRange: NSRange, affinity: NSSelectionAffinity, stillSelecting stillSelectingFlag: Bool) {
        
        super.setSelectedRange(charRange, affinity: affinity, stillSelecting: stillSelectingFlag)
        
        guard
            self.isRegularExpressionMode,
            case .search = self.parseMode,
            !stillSelectingFlag
        else { return }
        
        self.highlightMatchingBrace(candidates: [BracePair("(", ")"), BracePair("[", "]")], ignoring: BracePair("[", "]"))
    }
    
    
    // MARK: Private Methods
    
    /// Highlights the content string as a regular expression pattern.
    private func invalidateRegularExpression() {
        
        self.isValid = self.highlightAsRegularExpressionPattern(mode: self.parseMode, theme: self.theme, enabled: self.isRegularExpressionMode)
    }
}
