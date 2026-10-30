//
//  TextFinderTests.swift
//  Tests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2017-02-03.
//
//  ---------------------------------------------------------------------------
//
//  © 2017-2026 1024jp
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
import Defaults
import LineEnding
import TextFind
import Testing
@testable import CotEditor

@Suite(.serialized)  // TextFinder instances share their find settings.
@MainActor struct TextFinderTests {
    
    @Test func finderActions() {
        
        #expect(TextFinder.Action.showFindInterface.rawValue == NSTextFinder.Action.showFindInterface.rawValue)
        #expect(TextFinder.Action.nextMatch.rawValue == NSTextFinder.Action.nextMatch.rawValue)
        #expect(TextFinder.Action.previousMatch.rawValue == NSTextFinder.Action.previousMatch.rawValue)
        #expect(TextFinder.Action.replaceAll.rawValue == NSTextFinder.Action.replaceAll.rawValue)
        #expect(TextFinder.Action.replace.rawValue == NSTextFinder.Action.replace.rawValue)
        #expect(TextFinder.Action.replaceAndFind.rawValue == NSTextFinder.Action.replaceAndFind.rawValue)
        #expect(TextFinder.Action.setSearchString.rawValue == NSTextFinder.Action.setSearchString.rawValue)
        #expect(TextFinder.Action.replaceAllInSelection.rawValue == NSTextFinder.Action.replaceAllInSelection.rawValue)
        #expect(TextFinder.Action.selectAll.rawValue == NSTextFinder.Action.selectAll.rawValue)
        #expect(TextFinder.Action.selectAllInSelection.rawValue == NSTextFinder.Action.selectAllInSelection.rawValue)
        #expect(TextFinder.Action.hideFindInterface.rawValue == NSTextFinder.Action.hideFindInterface.rawValue)
        #expect(TextFinder.Action.showReplaceInterface.rawValue == NSTextFinder.Action.showReplaceInterface.rawValue)
        #expect(TextFinder.Action.hideReplaceInterface.rawValue == NSTextFinder.Action.hideReplaceInterface.rawValue)
    }
    
    
    @Test func findMatchesCacheBehavior() async throws {
        
        do {
            let textView = TestTextView(string: "foo foo foo")
            textView.setSelectedRange(NSRange(0..<(textView.string as NSString).length))
            
            let finder = TextFinder()
            finder.client = textView
            finder.settings.findString = "foo"
            finder.settings.usesRegularExpression = false
            
            _ = try await self.performFindAction(.nextMatch, with: finder)
            let firstCache = try #require(finder.findMatchesCache)
            
            textView.setSelectedRange(NSRange(0..<(textView.string as NSString).length))
            _ = try await self.performFindAction(.nextMatch, with: finder)
            let secondCache = try #require(finder.findMatchesCache)
            
            #expect(firstCache.options.textVersion == secondCache.options.textVersion)
            #expect(firstCache.matches == secondCache.matches)
        }
        
        do {
            let textView = TestTextView(string: "foo bar foo")
            textView.setSelectedRange(NSRange(0..<(textView.string as NSString).length))
            
            let finder = TextFinder()
            finder.client = textView
            finder.settings.findString = "foo"
            finder.settings.usesRegularExpression = false
            
            let firstResult = try await self.performFindAction(.nextMatch, with: finder)
            let firstCache = try #require(finder.findMatchesCache)
            
            textView.textStorage?.replaceCharacters(in: NSRange(0..<3), with: "xxx")
            textView.setSelectedRange(NSRange(0..<(textView.string as NSString).length))
            
            let secondResult = try await self.performFindAction(.nextMatch, with: finder)
            let secondCache = try #require(finder.findMatchesCache)
            
            #expect(firstResult.count == 2)
            #expect(secondResult.count == 1)
            #expect(firstCache.options.textVersion != secondCache.options.textVersion)
        }
        
        do {
            let textView = TestTextView(string: "foo bar foo")
            textView.setSelectedRange(NSRange(0..<(textView.string as NSString).length))
            
            let finder = TextFinder()
            finder.client = textView
            finder.settings.findString = "foo"
            finder.settings.usesRegularExpression = false
            
            _ = try await self.performFindAction(.nextMatch, with: finder)
            let firstCache = try #require(finder.findMatchesCache)
            
            finder.settings.findString = "bar"
            textView.setSelectedRange(NSRange(0..<(textView.string as NSString).length))
            
            let result = try await self.performFindAction(.nextMatch, with: finder)
            let secondCache = try #require(finder.findMatchesCache)
            
            #expect(result.count == 1)
            #expect(textView.selectedRange() == NSRange(4..<7))
            #expect(firstCache.options.textVersion == secondCache.options.textVersion)
            #expect(firstCache.matches != secondCache.matches)
        }
        
        do {
            let textView = TestTextView(string: "foo bar foo")
            
            let finder = TextFinder()
            finder.client = textView
            finder.settings.findString = "foo"
            finder.settings.usesRegularExpression = false
            
            textView.setSelectedRange(NSRange(0..<3))
            _ = try await self.performFindAction(.nextMatch, with: finder)
            let firstCache = try #require(finder.findMatchesCache)
            
            textView.setSelectedRange(NSRange(8..<11))
            let result = try await self.performFindAction(.nextMatch, with: finder)
            let secondCache = try #require(finder.findMatchesCache)
            
            if finder.settings.inSelection {
                #expect(result.count == 1)
                #expect(textView.selectedRange() == NSRange(8..<11))
                #expect(firstCache.matches != secondCache.matches)
            } else {
                #expect(result.count == 2)
                #expect(firstCache.matches == secondCache.matches)
            }
        }
    }
    
    
    @Test func findResultMatchMetadata() async throws {
        
        do {
            let textView = TestTextView(string: "foo bar foo")
            
            let finder = TextFinder()
            finder.client = textView
            finder.settings.findString = "foo"
            finder.settings.usesRegularExpression = false
            
            if finder.settings.inSelection {
                textView.setSelectedRange(NSRange(0..<(textView.string as NSString).length))
            } else {
                textView.setSelectedRange(NSRange(0..<0))
            }
            
            let firstResult = try await self.performFindAction(.nextMatch, with: finder)
            let secondResult = try await self.performFindAction(.nextMatch, with: finder)
            
            #expect(firstResult.count == 2)
            #expect(firstResult.currentMatchIndex == 1)
            #expect(firstResult.matchedRange == NSRange(0..<3))
            
            if finder.settings.inSelection {
                #expect(secondResult.currentMatchIndex == 1)
                #expect(secondResult.matchedRange == NSRange(0..<3))
            } else {
                #expect(secondResult.currentMatchIndex == 2)
                #expect(secondResult.matchedRange == NSRange(8..<11))
                
                let previousResult = try await self.performFindAction(.previousMatch, with: finder)
                #expect(previousResult.currentMatchIndex == 1)
                #expect(previousResult.matchedRange == NSRange(0..<3))
            }
        }
        
        do {
            let textView = TestTextView(string: "bar baz")
            textView.setSelectedRange(NSRange(0..<(textView.string as NSString).length))
            
            let finder = TextFinder()
            finder.client = textView
            finder.settings.findString = "foo"
            finder.settings.usesRegularExpression = false
            
            let result = try await self.performFindAction(.nextMatch, with: finder)
            
            #expect(result.count == 0)
            #expect(result.currentMatchIndex == nil)
            #expect(result.matchedRange == nil)
        }
    }
    
    
    @Test(arguments: [TextFinder.Action.findAll, .highlight])
    func findAllPreservesReadOnlyState(action: TextFinder.Action) async throws {
        
        let textView = TestTextView(string: "foo bar foo")
        textView.setSelectedRange(NSRange(0..<(textView.string as NSString).length))
        textView.isEditable = false
        
        let finder = TextFinder()
        finder.client = textView
        finder.settings.findString = "foo"
        finder.settings.usesRegularExpression = false
        
        _ = try await self.performFindAction(action, with: finder)
        
        #expect(!textView.isEditable)
    }
    
    
    /// Closing Find All results removes their highlights while preserving subsequent explicit highlights.
    ///
    /// - Parameters:
    ///   - closesPanel: Whether to close the panel instead of only the result view.
    ///   - highlightsAgain: Whether to perform Highlight All after Find All.
    @Test(arguments: [false, true], [false, true])
    func closingFindAllResults(closesPanel: Bool, highlightsAgain: Bool) async throws {
        
        let controller = FindPanelContentViewController()
        controller.loadViewIfNeeded()
        
        let textView = TestTextView(string: "foo bar foo")
        textView.setSelectedRange(NSRange(0..<(textView.string as NSString).length))
        
        let finder = TextFinder()
        finder.client = textView
        let settings = finder.settings
        let originalFindString = settings.findString
        let originalUsesRegularExpression = settings.usesRegularExpression
        defer {
            settings.findString = originalFindString
            settings.usesRegularExpression = originalUsesRegularExpression
        }
        settings.findString = "foo"
        settings.usesRegularExpression = false
        
        _ = try await self.performFindAction(.findAll, with: finder)
        try #require(await Task.waitFor { !controller.splitViewItems[1].isCollapsed })
        #expect(textView.hasTemporaryBackgroundColor)
        
        if highlightsAgain {
            settings.findString = "bar"
            _ = try await self.performFindAction(.highlight, with: finder)
            #expect(textView.hasTemporaryBackgroundColor)
        }
        settings.findString = ""
        
        await self.closeFindAllResults(controller, closesPanel: closesPanel)
        try #require(await Task.waitFor { controller.splitViewItems[1].isCollapsed })
        
        #expect(textView.hasTemporaryBackgroundColor == highlightsAgain)
    }
    
    
    /// Closing Find All results preserves explicit highlights in another editor.
    ///
    /// - Parameters:
    ///   - closesPanel: Whether to close the panel instead of only the result view.
    ///   - sharesTextStorage: Whether the editors share a document as split editors do.
    @Test(arguments: [false, true], [false, true])
    func closingFindAllResultsPreservesHighlightsInAnotherEditor(closesPanel: Bool, sharesTextStorage: Bool) async throws {
        
        let controller = FindPanelContentViewController()
        controller.loadViewIfNeeded()
        
        let textView = TestTextView(string: "foo bar foo")
        let otherTextView = sharesTextStorage
            ? TestTextView(textStorage: try #require(textView.textStorage))
            : TestTextView(string: "foo bar foo")
        for view in [textView, otherTextView] {
            view.setSelectedRange(NSRange(0..<(view.string as NSString).length))
        }
        
        let finder = TextFinder()
        finder.client = textView
        let otherFinder = TextFinder()
        otherFinder.client = otherTextView
        let settings = finder.settings
        let originalFindString = settings.findString
        let originalUsesRegularExpression = settings.usesRegularExpression
        defer {
            settings.findString = originalFindString
            settings.usesRegularExpression = originalUsesRegularExpression
        }
        settings.findString = "foo"
        settings.usesRegularExpression = false
        
        _ = try await self.performFindAction(.findAll, with: finder)
        try #require(await Task.waitFor { !controller.splitViewItems[1].isCollapsed })
        #expect(textView.hasTemporaryBackgroundColor)
        
        settings.findString = "bar"
        _ = try await self.performFindAction(.highlight, with: otherFinder)
        #expect(otherTextView.hasTemporaryBackgroundColor)
        
        await self.closeFindAllResults(controller, closesPanel: closesPanel)
        try #require(await Task.waitFor { controller.splitViewItems[1].isCollapsed })
        
        #expect(otherTextView.hasTemporaryBackgroundColor)
        #expect(textView.hasTemporaryBackgroundColor == sharesTextStorage)
    }
    
    
    /// Closing Find All results preserves subsequent multiple replace highlights in the same document.
    ///
    /// - Parameters:
    ///   - closesPanel: Whether to close the panel instead of only the result view.
    ///   - usesSplitEditor: Whether to highlight in another editor sharing the same text storage.
    @Test(arguments: [false, true], [false, true])
    func closingFindAllResultsPreservesMultipleReplaceHighlights(closesPanel: Bool, usesSplitEditor: Bool) async throws {
        
        let controller = FindPanelContentViewController()
        controller.loadViewIfNeeded()
        
        let textView = TestTextView(string: "foo bar foo")
        textView.setSelectedRange(NSRange(0..<(textView.string as NSString).length))
        let highlightTarget = usesSplitEditor
            ? TestTextView(textStorage: try #require(textView.textStorage))
            : textView
        let layoutManager = try #require(highlightTarget.layoutManager)
        
        let finder = TextFinder()
        finder.client = textView
        let settings = finder.settings
        let originalFindString = settings.findString
        let originalUsesRegularExpression = settings.usesRegularExpression
        defer {
            settings.findString = originalFindString
            settings.usesRegularExpression = originalUsesRegularExpression
        }
        settings.findString = "foo"
        settings.usesRegularExpression = false
        
        _ = try await self.performFindAction(.findAll, with: finder)
        try #require(await Task.waitFor { !controller.splitViewItems[1].isCollapsed })
        #expect(textView.hasTemporaryBackgroundColor)
        
        let definition = MultipleReplace(replacements: [.init(findString: "bar")])
        _ = try await highlightTarget.highlight(definition, inSelection: false)
        #expect(layoutManager.temporaryAttribute(.backgroundColor, atCharacterIndex: 4, effectiveRange: nil) != nil)
        #expect(layoutManager.temporaryAttribute(.backgroundColor, atCharacterIndex: 0, effectiveRange: nil) == nil)
        
        await self.closeFindAllResults(controller, closesPanel: closesPanel)
        try #require(await Task.waitFor { controller.splitViewItems[1].isCollapsed })
        
        #expect(layoutManager.temporaryAttribute(.backgroundColor, atCharacterIndex: 4, effectiveRange: nil) != nil)
    }
    
    
    @Test func selectAllUsesFindMatchesCache() async throws {
        
        do {
            let textView = TestTextView(string: "foo bar foo")
            textView.setSelectedRange(NSRange(0..<(textView.string as NSString).length))
            
            let finder = TextFinder()
            finder.client = textView
            finder.settings.findString = "foo"
            finder.settings.usesRegularExpression = false
            
            let result = try await self.performFindAction(.selectAll, with: finder)
            let selectedRanges = textView.selectedRanges.map(\.rangeValue)
            let cache = try #require(finder.findMatchesCache)
            
            #expect(result.count == 2)
            #expect(selectedRanges == [NSRange(0..<3), NSRange(8..<11)])
            #expect(cache.matches == selectedRanges)
        }
        
        do {
            let textView = TestTextView(string: "foo bar foo")
            textView.setSelectedRange(NSRange(0..<(textView.string as NSString).length))
            
            let finder = TextFinder()
            finder.client = textView
            finder.settings.findString = "foo"
            finder.settings.usesRegularExpression = false
            
            try await confirmation("No stale find result", expectedCount: 0) { confirm in
                let observer = NotificationCenter.default.addObserver(of: finder, for: TextFinder.DidFindMessage.self) { _ in
                    confirm()
                }
                defer { NotificationCenter.default.removeObserver(observer) }
                
                finder.performAction(.selectAll)
                textView.textStorage?.replaceCharacters(in: NSRange(0..<3), with: "bar")
                
                try await Task.sleep(for: .milliseconds(50))
            }
        }
    }
    
    
    /// Normalizes captured text and selects the inserted text during a single replacement.
    ///
    /// - Parameter lineEnding: The document line ending.
    @Test(arguments: [LineEnding.lf, .crlf])
    func replaceNormalizesCapturedLineEndings(lineEnding: LineEnding) {
        
        let string = "before\r|dog\r\ncow|after\r"
        let range = (string as NSString).range(of: "dog\r\ncow")
        let replacement = "dog\(lineEnding.string)cow\(lineEnding.string)"
        let document = TextDocument()
        document.textStorage.replaceCharacters(in: NSRange(), with: string)
        let controller = EditorTextViewController(document: document)
        defer { withExtendedLifetime(controller) { } }
        let textView = EditorTextView(textStorage: document.textStorage, lineEndingScanner: document.lineEndingScanner)
        textView.lineEnding = lineEnding
        textView.delegate = controller
        textView.selectedRange = range
        
        let finder = TextFinder()
        finder.client = textView
        let settings = finder.settings
        let defaults = UserDefaults.standard
        let originalFindString = settings.findString
        let originalReplacementString = settings.replacementString
        let originalUsesRegularExpression = settings.usesRegularExpression
        let originalInSelection = defaults[.findInSelection]
        defer {
            settings.findString = originalFindString
            settings.replacementString = originalReplacementString
            settings.usesRegularExpression = originalUsesRegularExpression
            defaults[.findInSelection] = originalInSelection
        }
        settings.findString = #"dog\Rcow"#
        settings.replacementString = #"$0\r"#
        settings.usesRegularExpression = true
        defaults[.findInSelection] = false
        
        finder.performAction(.replace)
        
        #expect(textView.string == "before\r|\(replacement)|after\r")
        #expect(textView.selectedRange == NSRange(location: range.location, length: replacement.utf16.count))
    }
    
    
    /// Preserves unmatched line endings through Multiple Replace, undo, and redo with the editor delegate.
    ///
    /// - Throws: A replacement error.
    @Test(.timeLimit(.minutes(1)))
    func multipleReplacePreservesUnmatchedLineEndings() async throws {
        
        let string = "<key>\r</key>\n\t<string>insertNewline:</string>\n"
        let expected = "<key>\r</key><string>insertNewline:</string>\n"
        let findString = #"\n\t<string>"#
        let replacementString = "<string>"
        let document = TextDocument()
        document.textStorage.replaceCharacters(in: NSRange(), with: string)
        let controller = EditorTextViewController(document: document)
        defer { withExtendedLifetime(controller) { } }
        let textView = EditorTextView(textStorage: document.textStorage, lineEndingScanner: document.lineEndingScanner)
        textView.lineEnding = .lf
        textView.delegate = controller
        
        let undoManager = UndoManager()
        undoManager.groupsByEvent = false
        document.undoManager = undoManager
        
        let definition = MultipleReplace(replacements: [
            .init(findString: findString, replacementString: replacementString, usesRegularExpression: true),
        ])
        
        undoManager.beginUndoGrouping()
        try await textView.replaceAll(definition, inSelection: false)
        undoManager.endUndoGrouping()
        
        #expect(textView.string == expected)
        #expect(!textView.isApprovedTextChange)
        #expect(undoManager.canUndo)
        undoManager.undo()
        #expect(textView.string == string)
        #expect(undoManager.canRedo)
        undoManager.redo()
        #expect(textView.string == expected)
    }
    
    
    /// Preserves unmatched line endings through replacement, undo, and redo with the editor delegate.
    ///
    /// - Throws: A find or replacement error.
    @Test(.bug("https://github.com/coteditor/CotEditor/issues/2172"), .timeLimit(.minutes(1)))
    func replaceAllPreservesUnmatchedLineEndings() async throws {
        
        let string = "<key>\r</key>\n\t<string>insertNewline:</string>\n"
        let expected = "<key>\r</key><string>insertNewline:</string>\n"
        let findString = #"\n\t<string>"#
        let replacementString = "<string>"
        let document = TextDocument()
        document.textStorage.replaceCharacters(in: NSRange(), with: string)
        let controller = EditorTextViewController(document: document)
        defer { withExtendedLifetime(controller) { } }
        let textView = EditorTextView(textStorage: document.textStorage, lineEndingScanner: document.lineEndingScanner)
        textView.lineEnding = .lf
        textView.delegate = controller
        
        let undoManager = UndoManager()
        undoManager.groupsByEvent = false
        document.undoManager = undoManager
        
        let finder = TextFinder()
        finder.client = textView
        let settings = finder.settings
        let defaults = UserDefaults.standard
        let originalFindString = settings.findString
        let originalReplacementString = settings.replacementString
        let originalUsesRegularExpression = settings.usesRegularExpression
        let originalInSelection = defaults[.findInSelection]
        defer {
            settings.findString = originalFindString
            settings.replacementString = originalReplacementString
            settings.usesRegularExpression = originalUsesRegularExpression
            defaults[.findInSelection] = originalInSelection
        }
        settings.findString = findString
        settings.replacementString = replacementString
        settings.usesRegularExpression = true
        defaults[.findInSelection] = false
        
        undoManager.beginUndoGrouping()
        let result = try await self.performFindAction(.replaceAll, with: finder)
        #expect(result.count == 1)
        undoManager.endUndoGrouping()
        
        #expect(textView.string == expected)
        #expect(!textView.isApprovedTextChange)
        #expect(undoManager.canUndo)
        undoManager.undo()
        #expect(textView.string == string)
        #expect(undoManager.canRedo)
        undoManager.redo()
        #expect(textView.string == expected)
    }
    
    
    // MARK: Private Methods
    
    /// Closes Find All results and waits for the collapse animation to finish.
    ///
    /// - Parameters:
    ///   - controller: The controller displaying the results.
    ///   - closesPanel: Whether to close the panel instead of only the result view.
    private func closeFindAllResults(_ controller: FindPanelContentViewController, closesPanel: Bool) async {
        
        await withCheckedContinuation { continuation in
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0
                if closesPanel {
                    controller.viewDidDisappear()
                } else {
                    controller.closeResultView(nil)
                }
            } completionHandler: {
                continuation.resume()
            }
        }
    }
    
    
    /// Performs a find action and waits for its typed find-result message.
    ///
    /// - Parameters:
    ///   - action: The find action to perform.
    ///   - finder: The text finder that performs the action.
    /// - Returns: The find result sent from the finder.
    private func performFindAction(_ action: TextFinder.Action, with finder: TextFinder) async throws -> FindResult {
        
        await withCheckedContinuation { continuation in
            var observer: NotificationCenter.ObservationToken?
            observer = NotificationCenter.default.addObserver(of: finder, for: TextFinder.DidFindMessage.self) { message in
                observer.map(NotificationCenter.default.removeObserver)
                continuation.resume(returning: message.result)
            }
            
            finder.performAction(action)
        }
    }
}


// MARK: -

@MainActor private final class TestTextView: NSTextView {
    
    /// Initializes a text view with its own storage.
    ///
    /// - Parameter string: The initial text.
    convenience init(string: String) {
        
        self.init(textStorage: NSTextStorage(string: string))
        self.string = string
    }
    
    
    /// Initializes a text view using the given storage.
    ///
    /// - Parameter textStorage: The text storage, which may be shared with another text view.
    init(textStorage: NSTextStorage) {
        
        let layoutManager = TestLayoutManager()
        let textContainer = NSTextContainer()
        
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        
        super.init(frame: .zero, textContainer: textContainer)
        
        self.isEditable = true
        self.isSelectable = true
    }
    
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func showFindIndicator(for charRange: NSRange) { }
    
    
    var hasTemporaryBackgroundColor: Bool {
        
        guard let layoutManager else { return false }
        
        return (0..<(self.string as NSString).length).contains {
            layoutManager.temporaryAttribute(.backgroundColor, atCharacterIndex: $0, effectiveRange: nil) != nil
        }
    }
}


private final class TestLayoutManager: NSLayoutManager, ValidationIgnorable {
    
    var ignoresDisplayValidation = false
}
