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
//  © 2014-2024 1024jp
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
import UnicodeNormalization

extension EditorTextView {
    
    // MARK: Action Messages (Case Transformations)
    
    /// Transforms the selections to upper case.
    @IBAction override func uppercaseWord(_ sender: Any?) {
        
        // override the default behavior to avoid invoking `selectWord(_:)` command
        // that is also overwritten to select the next same word.
        // -> The same for `lowercaseWord(_:)` and `capitalizeWord(_:)` below.
        self.transformSelection { $0.localizedUppercase }
    }
    
    
    /// Transforms the selections to lower case.
    @IBAction override func lowercaseWord(_ sender: Any?) {
        
        self.transformSelection { $0.localizedLowercase }
    }
    
    
    /// Transforms the selections to capitalized case.
    @IBAction override func capitalizeWord(_ sender: Any?) {
        
        self.transformSelection { $0.localizedCapitalized }
    }
    
    
    /// Transforms the selections to snake case.
    @IBAction func snakecaseWord(_ sender: Any?) {
        
        self.transformSelection { $0.snakecased }
    }
    
    
    /// Transforms the selections to camel case.
    @IBAction func camelcaseWord(_ sender: Any?) {
        
        self.transformSelection { $0.camelcased }
    }
    
    
    /// Transforms the selections to pascal case.
    @IBAction func pascalcaseWord(_ sender: Any?) {
        
        self.transformSelection { $0.pascalcased }
    }
    
    
    /// Encodes URL.
    @IBAction func encodeURL(_ sender: Any?) {
        
        let allowedCharacters = CharacterSet.alphanumerics.union(.init(charactersIn: "-._~"))
        self.transformSelection {
            $0.removingPercentEncoding?
                .addingPercentEncoding(withAllowedCharacters: allowedCharacters) ?? $0
        }
    }
    
    
    /// Decodes URL.
    @IBAction func decodeURL(_ sender: Any?) {
        
        self.transformSelection {
            $0.removingPercentEncoding ?? $0
        }
    }
    
    
    
    // MARK: Action Messages (Transformations)
    
    /// Transforms all full-width-available half-width characters in the selections to full-width.
    @IBAction func exchangeFullwidth(_ sender: Any?) {
        
        self.transformSelection {
            $0.applyingTransform(.fullwidthToHalfwidth, reverse: true) ?? $0
        }
    }
    
    
    /// Transforms all full-width characters in the selections to half-width.
    @IBAction func exchangeHalfwidth(_ sender: Any?) {
        
        self.transformSelection {
            $0.applyingTransform(.fullwidthToHalfwidth, reverse: false) ?? $0
        }
    }
    
    
    /// Transforms half-width roman characters in the selections to full-width.
    @IBAction func exchangeFullwidthRoman(_ sender: Any?) {
        
        self.transformSelection {
            $0.fullwidthRoman()
        }
    }
    
    
    /// Transforms full-width roman characters in the selections to half-width.
    @IBAction func exchangeHalfwidthRoman(_ sender: Any?) {
        
        self.transformSelection {
            $0.fullwidthRoman(reverse: true)
        }
    }
    
    
    /// Transforms Hiragana in the selections to Katakana.
    @IBAction func exchangeKatakana(_ sender: Any?) {
        
        self.transformSelection {
            $0.applyingTransform(.hiraganaToKatakana, reverse: false) ?? $0
        }
    }
    
    
    /// Transforms Katakana in the selections to Hiragana.
    @IBAction func exchangeHiragana(_ sender: Any?) {
        
        self.transformSelection {
            $0.applyingTransform(.hiraganaToKatakana, reverse: true) ?? $0
        }
    }
    
    
    
    // MARK: Action Messages (Unicode Normalization)
    
    /// Normalizes Unicode in the selections.
    @IBAction func normalizeUnicode(_ sender: NSMenuItem) {
        
        guard
            let tag = sender.representedObject as? String,
            let form = UnicodeNormalizationForm(rawValue: tag)
        else { return assertionFailure() }
        
        self.normalizeUnicode(form: form)
    }
    
    
    /// Normalizes Unicode in the selections.
    ///
    /// - Parameter form: The Unicode normalization form.
    func normalizeUnicode(form: UnicodeNormalizationForm) {
        
        self.transformSelection(actionName: form.localizedName) {
            $0.normalizing(in: form)
        }
    }
    
    
    
    // MARK: Action Messages (Smart Quotes)
    
    /// Straightens all curly quotes.
    @IBAction func straightenQuotesInSelection(_ sender: Any?) {
        
        self.transformSelection {
            $0.replacing(/[“”‟„]/, with: "\"")
              .replacing(/[‘’‛‚]/, with: "'")
        }
    }
}



// MARK: Private NSTextView Extension

private extension NSTextView {
    
    /// Transforms all selected strings and register to undo manager.
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
