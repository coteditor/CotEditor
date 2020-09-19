//
//  MultipleReplacement.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2017-02-19.
//
//  ---------------------------------------------------------------------------
//
//  © 2017-2020 1024jp
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

final class MultipleReplacement: Codable {
    
    struct Replacement {
        
        var findString: String
        var replacementString: String
        var usesRegularExpression: Bool = false
        var ignoresCase: Bool = false
        var description: String?
        var isEnabled = true
    }
    
    
    struct Settings: Equatable {
        
        var textualOptions: String.CompareOptions = []
        var regexOptions: NSRegularExpression.Options = [.anchorsMatchLines]
        var matchesFullWord: Bool = false
        var unescapesReplacementString: Bool = true
    }
    
    
    var replacements: [Replacement] = []
    var settings: Settings = .init()
}



extension MultipleReplacement.Replacement {
    
    init() {
        
        self.findString = ""
        self.replacementString = ""
    }
}



// MARK: - Replacement

extension MultipleReplacement {
    
    struct Result {
        
        var string: String
        var selectedRanges: [NSRange]?
        var count = 0
    }
    
    
    
    // MARK: Public Methods
    
    /// Batch-find in given string.
    ///
    /// - Parameters:
    ///   - string: The string to find in.
    ///   - ranges: The ranges of selection in the text view.
    ///   - inSelection: Whether find only in selection.
    ///   - block: The block enumerates the matches.
    ///   - stop: A reference to a Bool value. The block can set the value to true to stop further processing.
    /// - Returns: The found ranges. This method will return first all search finished.
    func find(string: String, ranges: [NSRange], inSelection: Bool, using block: (_ stop: inout Bool) -> Void) -> [NSRange] {
        
        var result = [NSRange]()
        
        guard !string.isEmpty else { return result }
        
        for replacement in self.replacements where replacement.isEnabled {
            let mode = replacement.mode(settings: self.settings)
            
            // -> Invalid replacement rules will just be ignored.
            guard let textFind = try? TextFind(for: string, findString: replacement.findString, mode: mode, inSelection: inSelection, selectedRanges: ranges) else { continue }
            
            // process find
            var isCancelled = false
            textFind.findAll { (ranges, stop) in
                block(&stop)
                isCancelled = stop
                
                result.append(ranges.first!)
            }
            
            guard !isCancelled else { return [] }
        }
        
        return result
    }
    
    
    /// Batch-replace matches in given string.
    ///
    /// - Parameters:
    ///   - string: The string to replace.
    ///   - ranges: The ranges of selection in the text view.
    ///   - inSelection: Whether replace only in selection.
    ///   - block: The block enumerates the matches.
    ///   - stop: A reference to a Bool value. The block can set the value to true to stop further processing.
    /// - Returns: The result of the replacement. This method will return first all replacement finished.
    func replace(string: String, ranges: [NSRange], inSelection: Bool, using block: @escaping (_ stop: inout Bool) -> Void) -> Result {
        
        var result = Result(string: string, selectedRanges: ranges)
        
        guard !string.isEmpty else { return result }
        
        for replacement in self.replacements where replacement.isEnabled {
            let mode = replacement.mode(settings: self.settings)
            let findRanges = result.selectedRanges ?? [result.string.nsRange]
            
            // -> Invalid replacement rules will just be ignored.
            guard let textFind = try? TextFind(for: result.string, findString: replacement.findString, mode: mode, inSelection: inSelection, selectedRanges: findRanges) else { continue }
            
            // process replacement
            var isCancelled = false
            let (replacementItems, selectedRanges) = textFind.replaceAll(with: replacement.replacementString) { (flag, stop) in
                
                switch flag {
                    case .findProgress, .foundCount:
                        break
                    case .replacementProgress:
                        result.count += 1
                        block(&stop)
                        isCancelled = stop
                }
            }
            
            // finish if cancelled
            guard !isCancelled else { return Result(string: string, selectedRanges: ranges) }
            
            // update string
            for item in replacementItems.reversed() {
                result.string = (result.string as NSString).replacingCharacters(in: item.range, with: item.string)
            }
            
            // update selected ranges
            result.selectedRanges = selectedRanges
        }
        
        return result
    }
    
}


private extension MultipleReplacement.Replacement {
    
    /// create TextFind.Mode with Replacement
    func mode(settings: MultipleReplacement.Settings) -> TextFind.Mode {
        
        if self.usesRegularExpression {
            let options = settings.regexOptions.union(self.ignoresCase ? [.caseInsensitive] : [])
            
            return .regularExpression(options: options, unescapesReplacement: settings.unescapesReplacementString)
            
        } else {
            let options = settings.textualOptions.union(self.ignoresCase ? [.caseInsensitive] : [])
            
            return .textual(options: options, fullWord: settings.matchesFullWord)
        }
    }
    
}



// MARK: - Validation

extension MultipleReplacement.Replacement {
    
    /// Check if replacement rule is valid.
    ///
    /// - Throws: `TextFind.Error`
    func validate(regexOptions: NSRegularExpression.Options = []) throws {
        
        guard !self.findString.isEmpty else {
            throw TextFind.Error.emptyFindString
        }
        
        if self.usesRegularExpression {
            do {
                _ = try NSRegularExpression(pattern: self.findString, options: regexOptions)
            } catch {
                throw TextFind.Error.regularExpression(reason: error.localizedDescription)
            }
        }
    }
    
}
