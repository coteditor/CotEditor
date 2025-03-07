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
//  © 2017-2024 1024jp
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

public struct MultipleReplace: Equatable, Sendable, Codable {
    
    public struct Replacement: Equatable, Sendable {
        
        public var findString: String
        public var replacementString: String
        public var usesRegularExpression: Bool
        public var ignoresCase: Bool
        public var description: String?
        public var isEnabled: Bool
        
        
        public init(findString: String = "", replacementString: String = "", usesRegularExpression: Bool = false, ignoresCase: Bool = false, description: String? = nil, isEnabled: Bool = true) {
            
            self.findString = findString
            self.replacementString = replacementString
            self.usesRegularExpression = usesRegularExpression
            self.ignoresCase = ignoresCase
            self.description = description
            self.isEnabled = isEnabled
        }
    }
    
    
    public struct Settings: Equatable, Sendable {
        
        public var textualOptions: String.CompareOptions
        public var regexOptions: NSRegularExpression.Options
        public var matchesFullWord: Bool
        public var unescapesReplacementString: Bool
        
        
        public init(textualOptions: String.CompareOptions = [], regexOptions: NSRegularExpression.Options = [.anchorsMatchLines], matchesFullWord: Bool = false, unescapesReplacementString: Bool = true) {
            
            self.textualOptions = textualOptions
            self.regexOptions = regexOptions
            self.matchesFullWord = matchesFullWord
            self.unescapesReplacementString = unescapesReplacementString
        }
    }
    
    
    public var replacements: [Replacement]
    public var settings: Settings
    
    
    public init(replacements: [Replacement] = [], settings: Settings = .init()) {
        
        self.replacements = replacements
        self.settings = settings
    }
}


// MARK: - Replacement

extension MultipleReplace {
    
    public struct Result: Equatable, Sendable {
        
        public var string: String
        public var selectedRanges: [NSRange]?
    }
    
    
    public enum Status: Equatable, Sendable {
        
        case processed
        case unitChanged
    }
    
    
    // MARK: Public Methods
    
    /// Batch-finds in the given string.
    ///
    /// - Parameters:
    ///   - string: The string to find in.
    ///   - ranges: The ranges of selection in the text view.
    ///   - inSelection: Whether find only in selection.
    ///   - progress: The progress object to observe cancellation by the user and notify the find progress.
    /// - Returns: The found ranges. This method will return first all search finished.
    public func find(string: String, ranges: [NSRange], inSelection: Bool, progress: FindProgress? = nil) throws(CancellationError) -> [NSRange] {
        
        var result: [NSRange] = []
        
        for replacement in self.replacements where replacement.isEnabled {
            let mode = replacement.mode(settings: self.settings)
            
            // -> Invalid replacement rules will just be ignored.
            guard let textFind = try? TextFind(for: string, findString: replacement.findString, mode: mode, inSelection: inSelection, selectedRanges: ranges) else { continue }
            
            // process find
            textFind.findAll { (ranges, stop) in
                guard progress?.state != .cancelled else {
                    stop = true
                    return
                }
                
                result.append(ranges.first!)
                progress?.incrementCount()
            }
            
            // finish if cancelled
            guard progress?.state != .cancelled else { throw CancellationError() }
            
            // notify
            progress?.incrementCompletedUnit()
        }
        
        return result
    }
    
    
    /// Batch-replaces matches in the given string.
    ///
    /// - Parameters:
    ///   - string: The string to replace.
    ///   - ranges: The ranges of selection in the text view.
    ///   - inSelection: Whether replace only in selection.
    ///   - progress: The progress object to observe cancellation by the user and notify the replacement progress.
    /// - Returns: The result of the replacement. This method will return first all replacement finished.
    public func replace(string: String, ranges: [NSRange], inSelection: Bool, progress: FindProgress? = nil) throws(CancellationError) -> Result {
        
        var result = Result(string: string, selectedRanges: ranges)
        
        for replacement in self.replacements where replacement.isEnabled {
            let mode = replacement.mode(settings: self.settings)
            let findRanges = result.selectedRanges ?? [result.string.nsRange]
            
            // -> Invalid replacement rules will just be ignored.
            guard let textFind = try? TextFind(for: result.string, findString: replacement.findString, mode: mode, inSelection: inSelection, selectedRanges: findRanges) else { continue }
            
            // process replacement
            let (replacementItems, selectedRanges) = textFind.replaceAll(with: replacement.replacementString) { (_, count, stop) in
                guard progress?.state != .cancelled else {
                    stop = true
                    return
                }
                
                progress?.incrementCount(by: count)
            }
            
            // finish if cancelled
            guard progress?.state != .cancelled else { throw CancellationError() }
            
            // update string
            for item in replacementItems.reversed() {
                result.string = (result.string as NSString).replacingCharacters(in: item.range, with: item.value)
            }
            
            // update selected ranges
            result.selectedRanges = selectedRanges
            
            // notify
            progress?.incrementCompletedUnit()
        }
        
        return result
    }
}


private extension MultipleReplace.Replacement {
    
    /// Creates a TextFind.Mode with Replacement.
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
    
    /// Checks if replacement rule is valid.
    public func validate(regexOptions: NSRegularExpression.Options = []) throws(TextFind.Error) {
        
        guard !self.findString.isEmpty else {
            throw .emptyFindString
        }
        
        if self.usesRegularExpression {
            do {
                _ = try NSRegularExpression(pattern: self.findString, options: regexOptions)
            } catch {
                throw .regularExpression(reason: error.localizedDescription)
            }
        }
    }
}
