//
//  QuotePairRuleTests.swift
//  StringUtilsTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-03-23.
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

import Testing
@testable import StringUtils

struct QuotePairRuleTests {
    
    @Test func distinctForMatching() {
        
        let first = QuotePairRule(pair: SymbolPair("\"", "\""), prefixes: ["r"])
        let duplicate = QuotePairRule(pair: SymbolPair("\"", "\""), prefixes: ["f"])
        let escaped = QuotePairRule(pair: SymbolPair("\"", "\""), escapeCharacter: "\\")
        let rules = [first, duplicate, escaped]
        
        #expect(rules.distinctForMatching == [first, escaped])
    }
    
    
    @Test func rangeOfQuotePair() {
        
        let string = "'a\\'b' 'c'"
        let rules = [
            QuotePairRule(pair: SymbolPair("'", "'"), escapeCharacter: "\\"),
            QuotePairRule(pair: SymbolPair("'", "'")),
        ]
        
        let range = string.rangeOfQuotePair(at: string.index(0), candidates: rules)
        
        #expect(range == string.index(0)...string.index(3))
    }
    
    
    @Test func rangeOfQuotePairWithPrefix() {
        
        let string = "r\"foo\""
        let rules = [QuotePairRule(pair: SymbolPair("\"", "\""), prefixes: ["r"])]
        
        let range = string.rangeOfQuotePair(at: string.index(1), candidates: rules)
        
        #expect(range == string.index(1)...string.index(5))
    }
    
    
    @Test func rangeOfQuotePairWithoutRequiredPrefix() {
        
        let string = "\"foo\""
        let rules = [QuotePairRule(pair: SymbolPair("\"", "\""), prefixes: ["r"])]
        
        let range = string.rangeOfQuotePair(at: string.index(0), candidates: rules)
        
        #expect(range == nil)
    }
}


private extension String {
    
    func index(_ index: Int) -> Index {
        
        self.index(self.startIndex, offsetBy: index)
    }
}
