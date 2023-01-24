//
//  MultipleReplace.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2017-02-19.
//
//  ---------------------------------------------------------------------------
//
//  © 2017-2023 1024jp
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

final class MultipleReplace: Codable {
    
    struct Replacement: Equatable {
        
        var findString: String = ""
        var replacementString: String = ""
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



// MARK: - Replacement

extension MultipleReplace {
    
    struct Result {
        
        var string: String
        var selectedRanges: [NSRange]?
    }
    
    
    enum Status {
        
        case processed
        case unitChagned
    }
    
    
    // MARK: Public Methods
    
    /// Batch-find in the given string.
    ///
    /// - Parameters:
    ///   - string: The string to find in.
    ///   - ranges: The ranges of selection in the text view.
    ///   - inSelection: Whether find only in selection.
    ///   - progress: The progress object to observe cancellation by the user and notify the find progress.
    /// - Returns: The found ranges. This method will return first all search finished.
    /// - Throws: `CancellationError`
    func find(string: String, ranges: [NSRange], inSelection: Bool, progress: FindProgress? = nil) throws -> [NSRange] {
        
        var result: [NSRange] = []
        
        for replacement in self.replacements where replacement.isEnabled {
            let mode = replacement.mode(settings: self.settings)
            
            // -> Invalid replacement rules will just be ignored.
            guard let textFind = try? TextFind(for: string, findString: replacement.findString, mode: mode, inSelection: inSelection, selectedRanges: ranges) else { continue }
            
            // process find
            textFind.findAll { (ranges, stop) in
                guard progress?.isCancelled != true else {
                    stop = true
                    return
                }
                
                result.append(ranges.first!)
                progress?.count += 1
            }
            
            // finish if cancelled
            guard progress?.isCancelled != true else { throw CancellationError() }
            
            // notify
            progress?.completedUnit += 1
        }
        
        return result
    }
    
    
    /// Batch-replace matches in the given string.
    ///
    /// - Parameters:
    ///   - string: The string to replace.
    ///   - ranges: The ranges of selection in the text view.
    ///   - inSelection: Whether replace only in selection.
    ///   - progress: The progress object to observe cancellation by the user and notify the replacement progress.
    /// - Returns: The result of the replacement. This method will return first all replacement finished.
    /// - Throws: `CancellationError`
    func replace(string: String, ranges: [NSRange], inSelection: Bool, progress: FindProgress? = nil) throws -> Result {
        
        var result = Result(string: string, selectedRanges: ranges)
        
        for replacement in self.replacements where replacement.isEnabled {
            let mode = replacement.mode(settings: self.settings)
            let findRanges = result.selectedRanges ?? [result.string.nsRange]
            
            // -> Invalid replacement rules will just be ignored.
            guard let textFind = try? TextFind(for: result.string, findString: replacement.findString, mode: mode, inSelection: inSelection, selectedRanges: findRanges) else { continue }
            
            // process replacement
            let (replacementItems, selectedRanges) = textFind.replaceAll(with: replacement.replacementString) { (_, count, stop) in
                guard progress?.isCancelled != true else {
                    stop = true
                    return
                }
                
                progress?.count += count
            }
            
            // finish if cancelled
            guard progress?.isCancelled != true else { throw CancellationError() }
            
            // update string
            for item in replacementItems.reversed() {
                result.string = (result.string as NSString).replacingCharacters(in: item.range, with: item.item)
            }
            
            // update selected ranges
            result.selectedRanges = selectedRanges
            
            // notify
            progress?.completedUnit += 1
        }
        
        return result
    }
}


private extension MultipleReplace.Replacement {
    
    /// Create TextFind.Mode with Replacement.
    ///
    /// - Parameter settings: The replacement settings to obtain the mode.
    /// - Returns: A TextFind.Mode.
    func mode(settings: MultipleReplace.Settings) -> TextFind.Mode {
        
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

extension MultipleReplace.Replacement {
    
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
