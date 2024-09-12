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

struct TextFinderTests {
    
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
}
