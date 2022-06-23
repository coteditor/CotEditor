//
//  EditorTextView+Transformation.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-01-10.
//
//  ---------------------------------------------------------------------------
//
//  © 2014-2022 1024jp
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

import Cocoa

extension EditorTextView {
    
    // MARK: Action Messages (Case Transformations)
    
    /// transform to upper case
    @IBAction override func uppercaseWord(_ sender: Any?) {
        
        // override the default behavior to avoid invoking `selectWord(_:)` command
        // that is also overwritten to select the next same word.
        // -> The same for `lowercaseWord(_:)` and `capitalizeWord(_:)` below.
        self.transformSelection { $0.localizedUppercase }
    }
    
    
    /// transform to lower case
    @IBAction override func lowercaseWord(_ sender: Any?) {
        
        self.transformSelection { $0.localizedLowercase }
    }
    
    
    /// transform to capitalized case
    @IBAction override func capitalizeWord(_ sender: Any?) {
        
        self.transformSelection { $0.localizedCapitalized }
    }
    
    
    /// transform to snake case
    @IBAction func snakecaseWord(_ sender: Any?) {
        
        self.transformSelection { $0.snakecased }
    }
    
    
    /// transform to snake case
    @IBAction func camelcaseWord(_ sender: Any?) {
        
        self.transformSelection { $0.camelcased }
    }
    
    
    /// transform to snake case
    @IBAction func pascalcaseWord(_ sender: Any?) {
        
        self.transformSelection { $0.pascalcased }
    }
    
    
    /// encode URL
    @IBAction func encodeURL(_ sender: Any?) {
        
        let allowedCharacters = CharacterSet.alphanumerics.union(.init(charactersIn: "-._~"))
        self.transformSelection {
            $0.addingPercentEncoding(withAllowedCharacters: allowedCharacters) ?? $0
        }
        
    }
    
    
    /// decode URL
    @IBAction func decodeURL(_ sender: Any?) {
        
        self.transformSelection {
            $0.removingPercentEncoding ?? $0
        }
    }
    
    
    
    // MARK: Action Messages (Transformations)
    
    /// transform all full-width-available half-width characters in selection to full-width
    @IBAction func exchangeFullwidth(_ sender: Any?) {
        
        self.transformSelection {
            $0.applyingTransform(.fullwidthToHalfwidth, reverse: true) ?? $0
        }
    }
    
    
    /// transform all full-width characters in selection to half-width
    @IBAction func exchangeHalfwidth(_ sender: Any?) {
        
        self.transformSelection {
            $0.applyingTransform(.fullwidthToHalfwidth, reverse: false) ?? $0
        }
    }
    
    
    /// transform half-width roman characters in selection to full-width
    @IBAction func exchangeFullwidthRoman(_ sender: Any?) {
        
        self.transformSelection {
            $0.fullwidthRoman()
        }
    }
    
    
    /// transform full-width roman characters in selection to half-width
    @IBAction func exchangeHalfwidthRoman(_ sender: Any?) {
        
        self.transformSelection {
            $0.fullwidthRoman(reverse: true)
        }
    }
    
    
    /// transform Hiragana in selection to Katakana
    @IBAction func exchangeKatakana(_ sender: Any?) {
        
        self.transformSelection {
            $0.applyingTransform(.hiraganaToKatakana, reverse: false) ?? $0
        }
    }
    
    
    /// transform Katakana in selection to Hiragana
    @IBAction func exchangeHiragana(_ sender: Any?) {
        
        self.transformSelection {
            $0.applyingTransform(.hiraganaToKatakana, reverse: true) ?? $0
        }
    }
    
    
    
    // MARK: Action Messages (Unicode Normalizations)
    
    /// Unicode normalization (NFD)
    @IBAction func normalizeUnicodeWithNFD(_ sender: Any?) {
        
        self.transformSelection(actionName: "NFD") {
            $0.normalize(in: .nfd)
        }
    }
    
    
    /// Unicode normalization (NFC)
    @IBAction func normalizeUnicodeWithNFC(_ sender: Any?) {
        
        self.transformSelection(actionName: "NFC") {
            $0.normalize(in: .nfc)
        }
    }
    
    
    /// Unicode normalization (NFKD)
    @IBAction func normalizeUnicodeWithNFKD(_ sender: Any?) {
        
        self.transformSelection(actionName: "NFKD") {
            $0.normalize(in: .nfkd)
        }
    }
    
    
    /// Unicode normalization (NFKC)
    @IBAction func normalizeUnicodeWithNFKC(_ sender: Any?) {
        
        self.transformSelection(actionName: "NFKC") {
            $0.normalize(in: .nfkc)
        }
    }
    
    
    /// Unicode normalization (NFKC_Casefold)
    @IBAction func normalizeUnicodeWithNFKCCF(_ sender: Any?) {
        
        self.transformSelection(actionName: "NFKC Casefold".localized) {
            $0.normalize(in: .nfkcCasefold)
        }
    }
    
    
    /// Unicode normalization (Modified NFC)
    @IBAction func normalizeUnicodeWithModifiedNFC(_ sender: Any?) {
        
        self.transformSelection(actionName: "Modified NFC".localized) {
            $0.normalize(in: .modifiedNFC)
        }
    }
    
    
    /// Unicode normalization (Modified NFD)
    @IBAction func normalizeUnicodeWithModifiedNFD(_ sender: Any?) {
        
        self.transformSelection(actionName: "Modified NFD".localized) {
            $0.normalize(in: .modifiedNFD)
        }
    }
    
    
    
    // MARK: Action Messages (Smart Quotes)
    
    /// Straighten all curly quotes.
    @IBAction func straightenQuotesInSelection(_ sender: Any?) {
        
        self.transformSelection {
            $0.replacingOccurrences(of: "[“”‟„]", with: "\"", options: .regularExpression)
              .replacingOccurrences(of: "[‘’‛‚]", with: "'", options: .regularExpression)
        }
    }
    
}



// MARK: Private NSTextView Extension

private extension NSTextView {
    
    /// transform all selected strings and register to undo manager
    func transformSelection(actionName: String? = nil, block: (String) -> String) {
        
        // transform the word that contains the cursor if nothing is selected
        if self.selectedRange.isEmpty {
            self.selectWord(self)
        }
        
        let selectedRanges = self.selectedRanges.map(\.rangeValue)
        var strings: [String] = []
        var appliedRanges: [NSRange] = []
        var newSelectedRanges: [NSRange] = []
        var deltaLocation = 0
        
        for range in selectedRanges where !range.isEmpty {
            let substring = (self.string as NSString).substring(with: range)
            let string = block(substring)
            let newRange = NSRange(location: range.location - deltaLocation, length: string.length)
            
            strings.append(string)
            appliedRanges.append(range)
            newSelectedRanges.append(newRange)
            deltaLocation += range.length - newRange.length
        }
        
        guard !strings.isEmpty else { return }
        
        self.replace(with: strings, ranges: appliedRanges, selectedRanges: newSelectedRanges, actionName: actionName)
        
        self.scrollRangeToVisible(self.selectedRange)
    }
    
}
