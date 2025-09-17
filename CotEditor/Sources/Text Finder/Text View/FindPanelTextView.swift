//
//  FindPanelTextView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2015-03-04.
//
//  ---------------------------------------------------------------------------
//
//  © 2015-2025 1024jp
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
import Combine
import Defaults
import Invisible
import StringUtils

/// Text view that behaves like an NSTextField.
final class FindPanelTextView: RegexTextView {
    
    // MARK: Public Properties
    
    var action: (() -> Void)?
    
    
    // MARK: Private Properties
    
    private var defaultObservers: Set<AnyCancellable> = []
    
    
    // MARK: Lifecycle
    
    required init() {
        
        let layoutManager = FindPanelLayoutManager()
        let textStorage = NSTextStorage()
        textStorage.addLayoutManager(layoutManager)
        let textContainer = NSTextContainer()
        layoutManager.addTextContainer(textContainer)
        
        super.init(frame: .zero, textContainer: textContainer)
        
        self.isRichText = false
        
        // set system font (standard NSTextField behavior)
        self.font = .systemFont(ofSize: 0)
        
        // workaround a bug that caused fallback font, Last Resort, to be used as the typing font
        // cf. [#1435](https://github.com/coteditor/CotEditor/issues/1435)
        self.typingAttributes[.font] = self.font
        
        // set inset a bit like NSTextField (horizontal inset is added in FindPanelTextClipView)
        self.textContainerInset = NSSize(width: 0, height: 4)
        
        // set writing direction to RTL when UI is RTL
        self.baseWritingDirection = (self.userInterfaceLayoutDirection == .rightToLeft) ? .rightToLeft : .natural
        
        // avoid wrapping
        self.isHorizontallyResizable = true
        self.isVerticallyResizable = true
        self.textContainer!.widthTracksTextView = false
        self.textContainer!.size = self.infiniteSize
        self.isHorizontallyResizable = true
        
        // behave as field editor for Tab, Shift-Tab, and Return keys
        self.isFieldEditor = true
        
        // disable automatic text substitutions
        self.isAutomaticQuoteSubstitutionEnabled = false
        self.isAutomaticDashSubstitutionEnabled = false
        self.isAutomaticTextReplacementEnabled = false
        self.isAutomaticSpellingCorrectionEnabled = false
        self.smartInsertDeleteEnabled = false
        
        // observe user defaults
        let publishers = Invisible.allCases.map(\.visibilityDefaultKey).uniqued
            .map { UserDefaults.standard.publisher(for: $0) }
        self.defaultObservers = [
            Publishers.MergeMany(publishers)
                .merge(with: Just(true))
                .map { _ in UserDefaults.standard.shownInvisible }
                .assign(to: \.shownInvisibles, on: layoutManager),
            UserDefaults.standard.publisher(for: .showInvisibles, initial: true)
                .assign(to: \.showsInvisibles, on: layoutManager),
        ]
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: TextView Methods
    
    /// The view is on focus.
    override func becomeFirstResponder() -> Bool {
        
        // select whole string on focus (standard NSTextField behavior)
        self.selectedRange = self.string.range
        
        return super.becomeFirstResponder()
    }
    
    
    /// The view dismisses focus.
    override func resignFirstResponder() -> Bool {
        
        // clear current selection (standard NSTextField behavior)
        self.selectedRange = NSRange(0..<0)
        
        return super.resignFirstResponder()
    }
    
    
    override func insertNewline(_ sender: Any?) {
        
        // perform the action with return (standard NSTextField behavior)
        self.action?()
    }
    
    
    override func responds(to aSelector: Selector!) -> Bool {
        
        // ignore text find action (standard NSTextField behavior)
        if aSelector == #selector(performTextFinderAction) {
            return false
        }
        
        return super.responds(to: aSelector)
    }
}
