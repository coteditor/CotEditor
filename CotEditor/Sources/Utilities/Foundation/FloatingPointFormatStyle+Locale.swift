//
//  FloatingPointFormatStyle+Locale.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-04-08.
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

extension FloatingPointFormatStyle {
    
    /// A floating-point format style that uses the current language code together with the current system region.
    ///
    /// - Note:
    ///   This exists as a workaround for the `FormatStyle` / SwiftUI issue discussed in #2055.
    ///   Some numeric controls ignore the user's custom "Number format" preference in System
    ///   Settings and derive decimal/grouping separators from the language-based locale instead.
    ///   Applying this style helps keep formatting and parsing stable enough for settings
    ///   round-trips, although it still cannot fully reproduce the user's preferred number
    ///   format (2026-04, macOS 26.4).
    var numberLocale: FloatingPointFormatStyle<Value> {
        
        self.numberLocale(locale: .current)
    }
    
    
    /// Returns a style applying the current language code and region from the given locale.
    func numberLocale(locale: Locale) -> FloatingPointFormatStyle<Value> {
        
        self.locale(Locale(languageCode: locale.language.languageCode,
                           languageRegion: locale.region))
    }
}
