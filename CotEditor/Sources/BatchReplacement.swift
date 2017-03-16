/*
 
 BatchReplacement.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2017-02-19.
 
 ------------------------------------------------------------------------------
 
 © 2017 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 https://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Foundation

struct BatchReplacement {
    
    struct Settings {
        
        var textualOptions: NSString.CompareOptions
        var regexOptions: NSRegularExpression.Options
        var unescapesReplacementString: Bool
        
        
        init(textualOptions: NSString.CompareOptions = [], regexOptions: NSRegularExpression.Options = [.anchorsMatchLines], unescapesReplacementString: Bool = false) {
            
            self.textualOptions = textualOptions
            self.regexOptions = regexOptions
            self.unescapesReplacementString = unescapesReplacementString
        }
    }
    
    
    
    var name: String
    var settings: Settings
    var replacements: [Replacement]
    
    
    init(name: String, settings: Settings = Settings(), replacements: [Replacement] = []) {
        
        self.name = name
        self.settings = settings
        self.replacements = replacements
    }
    
}



// MARK: - Replacement

extension BatchReplacement {
    
    struct Result {
        
        var string: String
        var selectedRanges: [NSRange]?
        var count = 0
        
        
        fileprivate init(string: String, selectedRanges: [NSRange]?) {
            
            self.string = string
            self.selectedRanges = selectedRanges
        }
    }
    
    
    
    // MARK: Public Methods
    
    /// Batch-replace given string.
    ///
    /// - Parameters:
    ///   - string: The string to replace.
    ///   - ranges: The ranges of selection in the text view.
    ///   - inSelection: Whether replace only in selection.
    ///   - block: The Block enumerates the matches.
    ///   - stop: A reference to a Boolean value. The Block can set the value to true to stop further processing.
    /// - Returns: The result of the replacement.
    func replace(string: String, ranges: [NSRange], inSelection: Bool, using block: (_ stop: inout Bool) -> Void) -> Result {
        
        var result = Result(string: string, selectedRanges: ranges)
        
        guard !string.isEmpty else { return result }
        
        for replacement in self.replacements {
            guard replacement.enabled else { continue }
            
            let settings = TextFind.Settings(usesRegularExpression: replacement.usesRegularExpression,
                                             isWrap: false,
                                             inSelection: inSelection,
                                             textualOptions: self.settings.textualOptions,
                                             regexOptions: self.settings.regexOptions,
                                             unescapesReplacementString: self.settings.unescapesReplacementString)
            let findRanges = result.selectedRanges ?? [result.string.nsRange]
            
            // -> Invalid replacement sets will be just ignored.
            let textFind: TextFind
            do {
                textFind = try TextFind(for: result.string, findString: replacement.findString, settings: settings, selectedRanges: findRanges)
            } catch {
                assertionFailure(error.localizedDescription)
                continue
            }
            
            // process replacement
            var cancelled = false
            let (replacementItems, selectedRanges) = textFind.replaceAll(with: replacement.replacementString) { (stop) in
                block(&stop)
                cancelled = stop
            }
            
            // finish if cancelled
            guard !cancelled else { return Result(string: string, selectedRanges: ranges) }
            
            // update string
            for item in replacementItems.reversed() {
                result.string = (result.string as NSString).replacingCharacters(in: item.range, with: item.string)
                result.count += 1
            }
            
            // update selected ranges
            result.selectedRanges = selectedRanges
        }
        
        return result
    }
    
}
