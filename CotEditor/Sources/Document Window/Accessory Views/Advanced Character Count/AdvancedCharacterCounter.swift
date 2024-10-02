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
//  © 2022-2024 1024jp
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
import Observation
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
    
    
    // MARK: Public Methods
    
    /// If there is a selection returns the count of the selection; otherwise, the entire count.
    var count: Int? {
        
        ((self.selectionCount ?? 0) > 0) ? self.selectionCount : self.entireCount
    }
    
    
    /// Stops observing text view.
    func stopObservation() {
        
        self.observers.removeAll()
    }
    
    
    /// Observe the contents and selections of the given text view to count.
    ///
    /// - Parameter textView: The text view to observe.
    func observe(textView: NSTextView) {
        
        self.textView = textView
        
        self.countEntire()
        self.countSelection()
        
        self.observers = [
            NotificationCenter.default.publisher(for: NSText.didChangeNotification, object: textView)
                .sink { [unowned self] _ in self.countEntire() },
            NotificationCenter.default.publisher(for: EditorTextView.didLiveChangeSelectionNotification, object: textView)
                .sink { [unowned self] _ in self.countSelection() },
            Publishers.Merge7(UserDefaults.standard.publisher(for: .countUnit).eraseToVoid(),
                              UserDefaults.standard.publisher(for: .countNormalizationForm).eraseToVoid(),
                              UserDefaults.standard.publisher(for: .countNormalizes).eraseToVoid(),
                              UserDefaults.standard.publisher(for: .countIgnoresNewlines).eraseToVoid(),
                              UserDefaults.standard.publisher(for: .countIgnoresWhitespaces).eraseToVoid(),
                              UserDefaults.standard.publisher(for: .countTreatsConsecutiveWhitespaceAsSingle).eraseToVoid(),
                              UserDefaults.standard.publisher(for: .countEncoding).eraseToVoid())
            .debounce(for: 0, scheduler: RunLoop.main)
            .sink { [unowned self] _ in
                self.countEntire()
                self.countSelection()
            },
        ]
    }
    
    
    /// Counts the entire string in the text view.
    private func countEntire() {
        
        guard let string = self.textView?.string.immutable else { return }
        
        let options = UserDefaults.standard.characterCountOptions
        
        Task.detached {
            let count = string.count(options: options)
            await MainActor.run {
                self.entireCount = count
            }
        }
    }
    
    
    /// Counts the selected strings in the text view.
    private func countSelection() {
        
        guard let strings = self.textView?.selectedStrings else { return }
        
        let options = UserDefaults.standard.characterCountOptions
        
        Task.detached {
            let count: Int? = strings
                .map { $0.count(options: options) }
                .reduce(nil) { (total, count) in
                    if let total, let count { total + count } else { total ?? count }
                }
            await MainActor.run {
                self.selectionCount = count
            }
        }
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
