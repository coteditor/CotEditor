//
//  MultipleReplaceTests.swift
//  Tests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2015-07-17.
//
//  ---------------------------------------------------------------------------
//
//  © 2025-2026 1024jp
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
@testable import TextFind

struct MultipleReplaceTests {
    
    @Test func isEmptyReplace() {
        
        #expect(MultipleReplace().isEmpty)
        #expect(MultipleReplace(replacements: [.init()]).isEmpty)
        #expect(MultipleReplace(replacements: [.init(), .init()]).isEmpty)
        #expect(MultipleReplace(replacements: [.init(findString: "a")]).isEmpty == false)
    }
    
    
    @Test func isEmptyReplacement() {
        
        #expect(MultipleReplace.Replacement().isEmpty)
        #expect(MultipleReplace.Replacement(findString: "a").isEmpty == false)
        #expect(MultipleReplace.Replacement(description: "a").isEmpty == false)
    }
    
    
    @Test func replacementValidateThrows() {
        
        #expect(throws: TextFind.Error.emptyFindString) {
            try MultipleReplace.Replacement().validate()
        }
        
        #expect(throws: TextFind.Error.regularExpression(reason: "The value “(” is invalid.")) {
            try MultipleReplace.Replacement(findString: "(", usesRegularExpression: true).validate()
        }
    }
    
    
    @Test func validateDefinitions() {
        
        // valid: non-empty find string
        let valid = MultipleReplace(replacements: [
            .init(findString: "a"),
        ])
        #expect(valid.validate())
        
        // invalid: empty find string
        let invalidEmpty = MultipleReplace(replacements: [
            .init(),
        ])
        #expect(invalidEmpty.validate() == false)
        
        // invalid: bad regex pattern should make whole set invalid
        let invalidRegex = MultipleReplace(replacements: [
            .init(findString: "(", usesRegularExpression: true),
        ])
        #expect(invalidRegex.validate() == false)
    }
    
    
    @Test func replaceTextualFullWord() throws {
        
        let settings = MultipleReplace.Settings(
            textualOptions: .caseInsensitive,
            regexOptions: [.anchorsMatchLines],
            matchesFullWord: true,
            unescapesReplacementString: true
        )
        let definition = MultipleReplace(replacements: [
            .init(findString: "cat", replacementString: "dog"),
        ], settings: settings)
        let string = "cats cat Cat"
        
        let result = try definition.replace(string: string, ranges: [NSRange(0..<0)], inSelection: false)
        
        #expect(result.string == "cats dog dog")
    }
    
    
    @Test func replaceRegex() throws {
        
        // uses regex, ignore case, and unescape replacement (\t -> tab)
        let settings = MultipleReplace.Settings(
            textualOptions: [],
            regexOptions: [],
            matchesFullWord: false,
            unescapesReplacementString: true
        )
        let definition = MultipleReplace(replacements: [
            .init(findString: "(?!=a)b(c)(?=d)", replacementString: "$1\\t", usesRegularExpression: true, ignoresCase: true)
        ], settings: settings)
        let string = "abcdefg ABCDEFG"
        
        let result = try definition.replace(string: string, ranges: [NSRange(0..<0)], inSelection: false)
        
        #expect(result.string == "ac\tdefg AC\tDEFG")
    }
    
    
    @Test func replaceInSelection() throws {
        
        // two-step replacement confined to selection
        let definition = MultipleReplace(replacements: [
            .init(findString: "abc", replacementString: "x"),
            .init(findString: "x", replacementString: "y")
        ])
        let string = "abc abc abc"
        let selection = NSRange(location: 4, length: 7)  // covers "abc abc" (the last two words)
        
        let result = try definition.replace(string: string, ranges: [selection], inSelection: true)
        
        #expect(result.string == "abc y y")
        #expect(result.selectedRanges?.count == 1)
    }
    
    
    @Test func ignoreDisabledAndInvalidRules() throws {
        
        let definition = MultipleReplace(replacements: [
            .init(findString: "hello", replacementString: "hi", isEnabled: false),  // disabled
            .init(findString: "(", replacementString: "X", usesRegularExpression: true),  // invalid regex -> ignored
            .init(findString: "world", replacementString: "earth"),  // valid
        ])
        let string = "hello world"
        
        let result = try definition.replace(string: string, ranges: [NSRange(0..<0)], inSelection: false)
        
        #expect(result.string == "hello earth")
    }
    
    
    @Test func find() throws {
        
        let definition = MultipleReplace(replacements: [
            .init(findString: "abc"),
            .init(findString: "def"),
        ])
        let string = "abc def abc"
        
        let ranges = try definition.find(string: string, ranges: [NSRange(0..<0)], inSelection: false)
        
        #expect(ranges.count == 3)
        #expect(ranges[0] == NSRange(location: 0, length: 3))
        #expect(ranges[1] == NSRange(location: 8, length: 3))
        #expect(ranges[2] == NSRange(location: 4, length: 3))
    }
    
    
    @Suite struct TSVParse {
        
        @Test func emptyInput() throws {
            
            let definition = try MultipleReplace(tabSeparatedText: "")
            
            #expect(definition.replacements.isEmpty)
            #expect(MultipleReplace(replacements: definition.replacements).isEmpty)
        }
        
        
        @Test func trailingBlankLines() throws {
            
            let tsv = "key\tvalue\n\n\n"
            let definition = try MultipleReplace(tabSeparatedText: tsv)
            
            #expect(definition.replacements.count == 1)
            #expect(definition.replacements[0].findString == "key")
            #expect(definition.replacements[0].replacementString == "value")
        }
        
        
        @Test func multipleLines() throws {
            
            let tsv = """
                      cat\tdog
                      b\tB
                      c\tC
                      """
            let definition = try MultipleReplace(tabSeparatedText: tsv)
            
            #expect(definition.replacements.count == 3)
            #expect(definition.replacements[0] == .init(findString: "cat", replacementString: "dog"))
            #expect(definition.replacements[1] == .init(findString: "b", replacementString: "B"))
            #expect(definition.replacements[2] == .init(findString: "c", replacementString: "C"))
            #expect(definition.settings == .init())
        }
    }
}
