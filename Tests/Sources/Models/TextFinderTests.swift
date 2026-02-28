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
//  © 2017-2024 1024jp
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
@testable import CotEditor

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
    
    
    // MARK: Private Methods
    
    private func performFindAction(_ action: TextFinder.Action, with finder: TextFinder) async throws -> FindResult {
        
        let notifications = NotificationCenter.default.notifications(named: TextFinder.DidFindMessage.name, object: finder)
        var iterator = notifications.makeAsyncIterator()
        
        finder.performAction(action)
        
        let notification = try #require(await iterator.next())
        return try #require(notification.userInfo?["result"] as? FindResult)
    }
}


// MARK: -

@MainActor private final class TestTextView: NSTextView {
    
    init(string: String) {
        
        let textStorage = NSTextStorage(string: string)
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer()
        
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        
        super.init(frame: .zero, textContainer: textContainer)
        
        self.isEditable = true
        self.isSelectable = true
        self.string = string
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func showFindIndicator(for charRange: NSRange) { }
}
