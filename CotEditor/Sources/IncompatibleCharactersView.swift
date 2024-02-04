//
//  IncompatibleCharactersView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-02-03.
//
//  ---------------------------------------------------------------------------
//
//  © 2024 1024jp
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
import AppKit.NSTextStorage
import Combine

struct IncompatibleCharactersView: View {
    
    typealias Item = ValueRange<IncompatibleCharacter>
    
    
    @MainActor final class Model: ObservableObject {
        
        var document: Document  { didSet { self.invalidateObservation() } }
        var isAppeared = false  { didSet { self.invalidateObservation() } }
        
        @Published var items: [Item] = []
        @Published var isScanning = false
        
        private var observers: Set<AnyCancellable> = []
        
        
        init(document: Document) {
            
            self.document = document
        }
    }
    
    
    @ObservedObject var model: Model
    
    @State private var selection: Item.ID?
    @State private var sortOrder = [KeyPathComparator(\Item.location)]
    
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 8) {
            Text("Incompatible Characters", tableName: "Inspector",
                 comment: "section title")
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(.secondary)
            
            // message
            if self.model.isScanning {
                Text("Scanning incompatible characters…", tableName: "Inspector")
            } else if self.model.items.isEmpty {
                Text("No issues found.", tableName: "Inspector")
                    .foregroundStyle(.secondary)
            } else {
                Text("Found \(self.model.items.count) incompatible characters.", tableName: "Inspector",
                     comment: "%lld is the number of characters.")
            }
            
            // table
            if !self.model.items.isEmpty {
                Table(self.model.items, selection: $selection, sortOrder: $sortOrder) {
                    TableColumn(String(localized: "Line", table: "Inspector", comment: "table column"), value: \.location) {
                        // calculate the line number first at this point to postpone the high cost processing as much as possible
                        let line = self.model.document.lineEndingScanner.lineNumber(at: $0.location)
                        Text(line, format: .number)
                            .monospacedDigit()
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    
                    TableColumn(String(localized: "Character", table: "Inspector", comment: "table column"), value: \.value.character) {
                        let character = $0.value.character
                        let invisibleCategories: Set<Unicode.GeneralCategory> = [.control, .spaceSeparator, .lineSeparator]
                        
                        if let unicode = character.unicodeScalars.first,
                           invisibleCategories.contains(unicode.properties.generalCategory) {
                            Text(unicode.codePoint)
                                .foregroundStyle(Color.tertiaryLabel)
                        } else {
                            Text(String(character))
                        }
                    }
                    
                    TableColumn(String(localized: "Converted", table: "Inspector", comment: "table column for converted character")) {
                        if let converted = $0.value.converted {
                            Text(converted)
                        }
                    }
                }
                .onChange(of: self.selection) { newValue in
                    self.selectItem(id: newValue)
                }
                .onChange(of: self.sortOrder) { newOrder in
                    withAnimation {
                        self.model.items.sort(using: newOrder)
                    }
                }
                .tableStyle(.bordered)
                .border(Color(nsColor: .gridColor))
            }
        }
        .onAppear {
            self.model.isAppeared = true
        }
        .onDisappear {
            self.model.isAppeared = false
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Incompatible Characters", tableName: "Inspector"))
        .controlSize(.small)
        .frame(maxWidth: .infinity, minHeight: self.model.items.isEmpty ? 60 : 120, alignment: .topLeading)
    }
    
    
    /// Selects correspondence range of the item in the editor.
    ///
    /// - Parameter row: The index of items to select.
    @MainActor private func selectItem(id: Item.ID?) {
        
        guard
            let item = self.model.items.first(where: { $0.id == id }),
            let textView = self.model.document.textView,
            textView.string.length >= item.range.upperBound
        else { return }
        
        textView.selectedRange = item.range
        textView.centerSelectionInVisibleArea(self)
    }
}


private extension IncompatibleCharactersView.Model {
    
    func invalidateObservation() {
        
        let scanner = self.document.incompatibleCharacterScanner
        
        scanner.shouldScan = self.isAppeared
        scanner.invalidate()
        
        if !self.isAppeared, !self.items.isEmpty {
            self.document.textStorage.clearAllMarkup()
        }
        
        if self.isAppeared {
            self.observers = [
                scanner.$incompatibleCharacters
                    .removeDuplicates()
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] in
                        self?.updateMarkup($0)
                        self?.items = $0
                    },
                scanner.$isScanning
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] in self?.isScanning = $0 },
            ]
        } else {
            self.observers.removeAll()
        }
    }
    
    
    // MARK: Private Methods
    
    /// Update mark up in the editors.
    ///
    /// - Parameter items: The new incompatible characters.
    private func updateMarkup(_ items: [ValueRange<IncompatibleCharacter>]) {
        
        if !self.items.isEmpty {
            self.document.textStorage.clearAllMarkup()
        }
        self.document.textStorage.markup(ranges: items.map(\.range))
    }
}


private extension NSTextStorage {
    
    /// Changes the background color of passed-in ranges.
    ///
    /// - Parameter ranges: The ranges to markup.
    @MainActor func markup(ranges: [NSRange]) {
        
        guard !ranges.isEmpty else { return }
        
        for manager in self.layoutManagers {
            guard let color = manager.firstTextView?.textColor?.withAlphaComponent(0.2) else { continue }
            
            for range in ranges {
                manager.addTemporaryAttribute(.backgroundColor, value: color, forCharacterRange: range)
            }
        }
    }
    
    
    /// Clears all background highlight (including text finder's highlights).
    @MainActor func clearAllMarkup() {
        
        let range = self.string.nsRange
        
        for manager in self.layoutManagers {
            manager.removeTemporaryAttribute(.backgroundColor, forCharacterRange: range)
        }
    }
}



// MARK: - Preview

@available(macOS 14, *)
#Preview(traits: .fixedLayout(width: 240, height: 300)) {
    let document = Document()
    document.changeEncoding(to: FileEncoding(encoding: .shiftJIS))
    document.textStorage.replaceContent(with: "  ~ \n ~ \\")
    
    return IncompatibleCharactersView(model: .init(document: document))
        .padding(12)
}

@available(macOS 14, *)
#Preview("Empty", traits: .fixedLayout(width: 240, height: 300)) {
    IncompatibleCharactersView(model: .init(document: .init()))
        .padding(12)
}
