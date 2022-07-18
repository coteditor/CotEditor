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
//  © 2022 1024jp
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

import SwiftUI
import Combine
import AppKit

final class CharacterCountOptionsSetting: ObservableObject {
    
    @AppStorage("countOption.unit") var unit: CharacterCountOptions.CharacterUnit = .graphemeCluster
    @AppStorage("countOption.normalizationForm") var normalizationForm: UnicodeNormalizationForm = .nfc
    @AppStorage("countOption.normalizes") var normalizes = false
    @AppStorage("countOption.ignoresNewlines") var ignoresNewlines = false
    @AppStorage("countOption.ignoresWhitespaces") var ignoresWhitespaces = false
    @AppStorage("countOption.treatsConsecutiveWhitespaceAsSingle") var treatsConsecutiveWhitespaceAsSingle = false
    @AppStorage("countOption.encoding") var encoding: Int = Int(String.Encoding.utf8.rawValue)
    
    
    var options: CharacterCountOptions {
        
        .init(unit: self.unit,
              normalizationForm: self.normalizes ? self.normalizationForm : nil,
              ignoresNewlines: self.ignoresNewlines,
              ignoresWhitespaces: self.ignoresWhitespaces,
              treatsConsecutiveWhitespaceAsSingle: self.treatsConsecutiveWhitespaceAsSingle,
              encoding: .init(rawValue: UInt(self.encoding)))
    }
    
}



final class AdvancedCharacterCounter: ObservableObject {
    
    // MARK: Public Properties
    
    @Published private(set) var entireCount: Int? = 0
    @Published private(set) var selectionCount: Int? = 0
    
    
    // MARK: Private Properties
    
    private let textView: NSTextView
    private let setting = CharacterCountOptionsSetting()
    
    
    
    // MARK: Lifecycle
    
    init(textView: NSTextView) {
        
        self.textView = textView
        
        // observe text view and UserDefaults
        NotificationCenter.default.publisher(for: NSText.didChangeNotification, object: textView)
            .eraseToVoid()
            .merge(with: self.setting.objectWillChange)
            .merge(with: Just(Void()))  // initial calculation
            .compactMap { [weak self] in self?.textView }
            .receive(on: DispatchQueue.main)
            .map { $0.string.immutable }
            .receive(on: DispatchQueue.global())
            .map { [unowned self] in $0.count(options: self.setting.options) }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .assign(to: &self.$entireCount)
        NotificationCenter.default.publisher(for: EditorTextView.didLiveChangeSelectionNotification, object: textView)
            .eraseToVoid()
            .merge(with: self.setting.objectWillChange)
            .merge(with: Just(Void()))  // initial calculation
            .compactMap { [weak self] in self?.textView }
            .receive(on: DispatchQueue.main)
            .map { ($0.string as NSString).substring(with: $0.selectedRange) }
            .receive(on: DispatchQueue.global())
            .map { [unowned self] in $0.count(options: self.setting.options) }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .assign(to: &self.$selectionCount)
    }
    
}
