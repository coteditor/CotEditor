//
//  AdvancedCharacterCounter.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2022-07-16.
//
//  ---------------------------------------------------------------------------
//
//  © 2022-2026 1024jp
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
import Defaults
import StringUtils

@MainActor @Observable final class AdvancedCharacterCounter {
    
    // MARK: Public Properties
    
    private(set) var entireCount: Int? = 0
    private(set) var selectionCount: Int? = 0
    
    
    // MARK: Private Properties
    
    private weak var textView: NSTextView?
    private var observers: Set<AnyCancellable> = []
    private var entireCountTask: Task<Void, any Error>?
    private var selectionCountTask: Task<Void, any Error>?
    
    
    // MARK: Public Methods
    
    /// If there is a selection returns the count of the selection; otherwise, the entire count.
    var count: Int? {
        
        ((self.selectionCount ?? 0) > 0) ? self.selectionCount : self.entireCount
    }
    
    
    /// Stops observing text view.
    func stopObservation() {
        
        self.observers.removeAll()
        self.entireCountTask?.cancel()
        self.entireCountTask = nil
        self.selectionCountTask?.cancel()
        self.selectionCountTask = nil
    }
    
    
    /// Observe the content and selection of the given text view to count.
    ///
    /// - Parameter textView: The text view to observe.
    func observe(textView: NSTextView) {
        
        self.textView = textView
        
        self.countEntire()
        self.countSelection()
        
        self.observers = [
            NotificationCenter.default.publisher(for: NSText.didChangeNotification, object: textView)
                .sink { [unowned self] _ in self.countEntire() },
            NotificationCenter.default.publisher(for: EditorTextView.DidLiveChangeSelectionMessage.name, object: textView)
                .sink { [unowned self] _ in self.countSelection() },
            Publishers.Merge7(UserDefaults.standard.publisher(for: .countUnit).map { _ in },
                              UserDefaults.standard.publisher(for: .countNormalizationForm).map { _ in },
                              UserDefaults.standard.publisher(for: .countNormalizes).map { _ in },
                              UserDefaults.standard.publisher(for: .countIgnoresNewlines).map { _ in },
                              UserDefaults.standard.publisher(for: .countIgnoresWhitespaces).map { _ in },
                              UserDefaults.standard.publisher(for: .countTreatsConsecutiveWhitespaceAsSingle).map { _ in },
                              UserDefaults.standard.publisher(for: .countEncoding).map { _ in })
            .debounce(for: 0, scheduler: RunLoop.main)
            .sink { [unowned self] _ in
                self.countEntire()
                self.countSelection()
            },
        ]
    }
    
    
    // MARK: Private Methods
    
    /// Counts the entire string in the text view.
    private func countEntire() {
        
        self.entireCountTask?.cancel()
        
        guard let string = self.textView?.string.immutable else {
            self.entireCountTask = nil
            return
        }
        
        let options = UserDefaults.standard.characterCountOptions
        self.entireCountTask = Task { [weak self] in
            try Task.checkCancellation()
            let count = await Self.calculateCount(in: string, options: options)
            try Task.checkCancellation()
            
            self?.entireCount = count
        }
    }
    
    
    /// Counts the selected strings in the text view.
    private func countSelection() {
        
        self.selectionCountTask?.cancel()
        
        guard let strings = self.textView?.selectedStrings else {
            self.selectionCountTask = nil
            return
        }
        
        let options = UserDefaults.standard.characterCountOptions
        self.selectionCountTask = Task { [weak self] in
            try Task.checkCancellation()
            let count = await Self.calculateCount(in: strings, options: options)
            try Task.checkCancellation()
            
            self?.selectionCount = count
        }
    }
    
    
    /// Calculates the count of a string off the main actor.
    ///
    /// - Parameters:
    ///   - string: The string to count.
    ///   - options: The counting options.
    /// - Returns: The count, or `nil` if counting failed.
    @concurrent private static func calculateCount(in string: String, options: CharacterCountOptions) async -> Int? {
        
        string.count(options: options)
    }
    
    
    /// Calculates the total count of the selected strings off the main actor.
    ///
    /// - Parameters:
    ///   - strings: The selected strings to count.
    ///   - options: The counting options.
    /// - Returns: The total count, or `nil` if counting failed.
    @concurrent private static func calculateCount(in strings: [String], options: CharacterCountOptions) async -> Int? {
        
        strings
            .compactMap { $0.count(options: options) }
            .reduce(0, +)
    }
}


private extension UserDefaults {
    
    var characterCountOptions: CharacterCountOptions {
        
        CharacterCountOptions(
            unit: self[.countUnit] ?? .graphemeCluster,
            normalizationForm: self[.countNormalizes] ? self[.countNormalizationForm] : nil,
            ignoresNewlines: self[.countIgnoresNewlines],
            ignoresWhitespaces: self[.countIgnoresWhitespaces],
            treatsConsecutiveWhitespaceAsSingle: self[.countTreatsConsecutiveWhitespaceAsSingle],
            encoding: .init(rawValue: UInt(self[.countEncoding])))
    }
}
