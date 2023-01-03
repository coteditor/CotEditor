//
//  TextFinderSettings.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2023-01-03.
//
//  ---------------------------------------------------------------------------
//
//  © 2023 1024jp
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
import Combine

final class TextFinderSettings: NSObject {
    
    // MARK: Public Properties
    
    static let shared = TextFinderSettings()
    
    @objc dynamic var findString: String  { didSet { self.shareFindString() } }
    @objc dynamic var replacementString: String
    
    
    // MARK: Private Properties
    
    private static let maximumRecents = 20
    
    private let defaults: UserDefaults
    private var applicationActivationObserver: AnyCancellable?
    
    
    
    // MARK: Lifecycle
    
    private init(defaults: UserDefaults = .standard) {
        
        self.findString = NSPasteboard(name: .find).string(forType: .string) ?? ""
        self.replacementString = ""
        self.defaults = defaults
        
        super.init()
        
        // observe application activation to sync find string with other apps
        self.applicationActivationObserver = NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
            .compactMap { _ in NSPasteboard(name: .find).string(forType: .string) }
            .sink { [weak self] in self?.findString = $0 }
    }
    
    
    
    // MARK: Public Methods
    
    /// The options for the text search.
    var mode: TextFind.Mode {
        
        let defaults = self.defaults
        
        if defaults[.findUsesRegularExpression] {
            let options = NSRegularExpression.Options()
                .union(defaults[.findIgnoresCase] ? .caseInsensitive : [])
                .union(defaults[.findRegexIsSingleline] ? .dotMatchesLineSeparators : [])
                .union(defaults[.findRegexIsMultiline] ? .anchorsMatchLines : [])
                .union(defaults[.findRegexUsesUnicodeBoundaries] ? .useUnicodeWordBoundaries : [])
            
            return .regularExpression(options: options, unescapesReplacement: defaults[.findRegexUnescapesReplacementString])
            
        } else {
            let options = String.CompareOptions()
                .union(defaults[.findIgnoresCase] ? .caseInsensitive : [])
                .union(defaults[.findTextIsLiteralSearch] ? .literal : [])
                .union(defaults[.findTextIgnoresDiacriticMarks] ? .diacriticInsensitive : [])
                .union(defaults[.findTextIgnoresWidth] ? .widthInsensitive : [])
            
            return .textual(options: options, fullWord: defaults[.findMatchesFullWord])
        }
    }
    
    
    /// Whether uses the regular expression.
    var usesRegularExpression: Bool {
        
        get { self.defaults[.findUsesRegularExpression] }
        set { self.defaults[.findUsesRegularExpression] = newValue }
    }
    
    
    /// Whether find string only in selectedRanges.
    var inSelection: Bool {
        
        self.defaults[.findInSelection]
    }
    
    
    /// Whether the search wraps  around.
    var isWrap: Bool {
        
        self.defaults[.findIsWrap]
    }
    
    
    /// Add the current find string to the history.
    func noteFindHistory() {
        
        self.appendHistory(self.findString, forKey: .findHistory)
    }
    
    
    /// Add the current find and replacement strings to the history.
    func noteReplaceHistory() {
        
        self.appendHistory(self.findString, forKey: .findHistory)
        self.appendHistory(self.replacementString, forKey: .replaceHistory)
    }
    
    
    
    // MARK: Private Methods
    
    /// Put the current find string to the shared pasteboard.
    private func shareFindString() {
        
        let pasteboard = NSPasteboard(name: .find)
        pasteboard.clearContents()
        pasteboard.setString(self.findString, forType: .string)
    }
    
    
    /// Add a new value to the history as the latest item with the user defaults key.
    ///
    /// - Parameters:
    ///   - value: The value to add.
    ///   - key: The default key to add the value.
    private func appendHistory<T: Equatable>(_ value: T, forKey key: DefaultKey<[T]>) {
        
        guard (value as? String)?.isEmpty != true else { return }
        
        self.defaults[key].appendUnique(value, maximum: Self.maximumRecents)
    }
}
