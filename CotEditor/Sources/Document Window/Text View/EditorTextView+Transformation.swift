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
//  © 2014-2025 1024jp
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
import StringUtils

extension EditorTextView {
    
    // MARK: Action Messages (Case Transformations)
    
    /// Transforms the selections to upper case.
    @IBAction override func uppercaseWord(_ sender: Any?) {
        
        // override the default behavior to avoid invoking `selectWord(_:)` command
        // that is also overwritten to select the next same word.
        // -> The same for `lowercaseWord(_:)` and `capitalizeWord(_:)` below.
        self.transformSelection(to: \.localizedUppercase)
    }
    
    
    /// Transforms the selections to lower case.
    @IBAction override func lowercaseWord(_ sender: Any?) {
        
        self.transformSelection(to: \.localizedLowercase)
    }
    
    
    /// Transforms the selections to capitalized case.
    @IBAction override func capitalizeWord(_ sender: Any?) {
        
        self.transformSelection(to: \.localizedCapitalized)
    }
    
    
    /// Transforms the selections to snake case.
    @IBAction func snakecaseWord(_ sender: Any?) {
        
        self.transformSelection(to: \.snakecased)
    }
    
    
    /// Transforms the selections to camel case.
    @IBAction func camelcaseWord(_ sender: Any?) {
        
        self.transformSelection(to: \.camelcased)
    }
    
    
    /// Transforms the selections to pascal case.
    @IBAction func pascalcaseWord(_ sender: Any?) {
        
        self.transformSelection(to: \.pascalcased)
    }
    
    
    // MARK: Action Messages (Transformations)
    
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
            let form = sender.representedObject as? UnicodeNormalizationForm
        else { return assertionFailure() }
        
        self.normalizeUnicode(form: form)
    }
    
    
    /// Normalizes Unicode in the selections.
    ///
    /// - Parameter form: The Unicode normalization form.
    func normalizeUnicode(form: UnicodeNormalizationForm) {
        
        guard self.transformSelection(to: {
            $0.normalizing(in: form)
        }) else { return }
        
        self.undoManager?.setActionName(form.localizedName)
    }
    
    
    // MARK: Action Messages (Smart Quotes)
    
    /// Straightens all curly quotes.
    @IBAction func straightenQuotesInSelection(_ sender: Any?) {
        
        self.transformSelection(to: \.straighteningQuotes)
    }
}
