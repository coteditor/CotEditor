//
//  FloatingPointFormatStyleLocaleTests.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-04-09.
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

import Foundation
import Testing
@testable import CotEditor

struct FloatingPointFormatStyleLocaleTests {
    
    @Test func formatWithInjectedLocale() {
        
        let style = FloatingPointFormatStyle<Double>()
            .precision(.fractionLength(1))
        
        #expect(style.numberLocale(locale: Locale(languageCode: .english, languageRegion: .france)).format(1.5) == "1,5")
        #expect(style.numberLocale(locale: Locale(languageCode: .french, languageRegion: .unitedStates)).format(1.5) == "1.5")
    }
    
    
    @Test func parseWithInjectedLocale() throws {
        
        let style = FloatingPointFormatStyle<Double>()
            .precision(.fractionLength(1))
        
        #expect(try style.numberLocale(locale: Locale(languageCode: .english, languageRegion: .france)).parseStrategy.parse("1,5") == 1.5)
        #expect(try style.numberLocale(locale: Locale(languageCode: .french, languageRegion: .unitedStates)).parseStrategy.parse("1.5") == 1.5)
    }
    
    
    @Test func currentShortcutUsesCurrentLocale() {
        
        let style = FloatingPointFormatStyle<Double>()
            .precision(.fractionLength(2))
        
        #expect(style.numberLocale.format(1234.5) == style.numberLocale(locale: .current).format(1234.5))
    }
}
