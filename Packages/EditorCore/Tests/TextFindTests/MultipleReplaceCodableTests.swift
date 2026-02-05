//
//  MultipleReplaceCodableTests.swift
//  TextFindTests
//
//  Created by 1024jp on 2026-02-05.
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

import Foundation
import Testing
@testable import TextFind

struct MultipleReplaceCodableTests {
    
    @Test func replacementRoundTrip() throws {
        
        let replacement = MultipleReplace.Replacement(
            findString: "foo",
            replacementString: "bar",
            usesRegularExpression: true,
            ignoresCase: true,
            description: "desc",
            isEnabled: false
        )
        
        let data = try JSONEncoder().encode(replacement)
        let decoded = try JSONDecoder().decode(MultipleReplace.Replacement.self, from: data)
        
        #expect(decoded == replacement)
    }
    
    
    @Test func replacementDecodingDefaults() throws {
        
        let json = """
        {
            "findString": "foo",
            "replacementString": "bar"
        }
        """
        let data = try #require(json.data(using: .utf8))
        let decoded = try JSONDecoder().decode(MultipleReplace.Replacement.self, from: data)
        
        #expect(decoded.findString == "foo")
        #expect(decoded.replacementString == "bar")
        #expect(decoded.usesRegularExpression == false)
        #expect(decoded.ignoresCase == false)
        #expect(decoded.description == nil)
        #expect(decoded.isEnabled == true)
    }
    
    
    @Test func replacementEncodingDefaults() throws {
        
        let replacement = MultipleReplace.Replacement(findString: "foo", replacementString: "bar")
        let data = try JSONEncoder().encode(replacement)
        let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let keys = Set(object.keys)
        
        #expect(keys == ["findString", "replacementString"])
    }
    
    
    @Test func settingsRoundTrip() throws {
        
        let settings = MultipleReplace.Settings(
            textualOptions: [.caseInsensitive, .diacriticInsensitive],
            regexOptions: [.anchorsMatchLines, .caseInsensitive],
            matchesFullWord: true,
            unescapesReplacementString: false
        )
        
        let data = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(MultipleReplace.Settings.self, from: data)
        
        #expect(decoded == settings)
    }
    
    
    @Test func settingsDecodingDefaults() throws {
        
        let json = """
        {
            "textualOptions": 0,
            "regexOptions": 0
        }
        """
        let data = try #require(json.data(using: .utf8))
        let decoded = try JSONDecoder().decode(MultipleReplace.Settings.self, from: data)
        
        #expect(decoded.textualOptions.isEmpty)
        #expect(decoded.regexOptions.isEmpty)
        #expect(decoded.matchesFullWord == false)
        #expect(decoded.unescapesReplacementString == false)
    }
}
