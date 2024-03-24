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
import Combine
import AppKit.NSTextStorage

struct IncompatibleCharactersView: View {
    
    @MainActor final class Model: ObservableObject {
        
        typealias Item = ValueRange<IncompatibleCharacter>
        
        
        @Published var items: [Item] = []
        @Published private(set) var isScanning = false
        
        var document: Document?  { didSet { self.invalidateObservation() } }
        
        private(set) var task: Task<Void, any Error>?
        private var observer: AnyCancellable?
    }
    
    
    @ObservedObject var model: Model
    
    @State private var selection: Model.Item.ID?
    @State private var sortOrder: [KeyPathComparator<Model.Item>] = []
    
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 8) {
            Text("Incompatible Characters", tableName: "Document",
                 comment: "section title in inspector")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.secondary)
            
            if self.model.isScanning {
                Text("Scanning incompatible characters…", tableName: "Document")
            } else if self.model.items.isEmpty {
                Text("No issues found.", tableName: "Document")
                    .foregroundStyle(.secondary)
            } else {
                Text("Found \(self.model.items.count) incompatible characters.", tableName: "Document",
                     comment: "%lld is the number of characters.")
            }
            
            if !self.model.items.isEmpty {
                Table(self.model.items, selection: $selection, sortOrder: $sortOrder) {
                    TableColumn(String(localized: "Line", table: "Document", comment: "table column header"), value: \.location) {
                        // calculate the line number first at this point to postpone the high cost processing as much as possible
                        if let line = self.model.document?.lineEndingScanner.lineNumber(at: $0.location) {
                            Text(line, format: .number)
                                .monospacedDigit()
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }
                    
                    TableColumn(String(localized: "Character", table: "Document", comment: "table column header"), value: \.value.character) {
                        let character = $0.value.character
                        let invisibleCategories: Set<Unicode.GeneralCategory> = [.control, .spaceSeparator, .lineSeparator]
                        
                        if let unicode = character.unicodeScalars.first,
                           invisibleCategories.contains(unicode.properties.generalCategory) {
                            Text(unicode.codePoint)
                                .foregroundStyle(.tertiary)
                        } else {
                            Text(String(character))
                        }
                    }
                    
                    TableColumn(String(localized: "Converted", table: "Document", comment: "table column header for converted character")) {
                        if let converted = $0.value.converted {
                            Text(converted)
                        }
                    }
                }
                .onChange(of: self.selection) { newValue in
                    self.model.selectItem(id: newValue)
                }
                .onChange(of: self.sortOrder) { newValue in
                    withAnimation {
                        self.model.items.sort(using: newValue)
                    }
                }
                .tableStyle(.bordered)
                .border(Color(nsColor: .gridColor))
            }
        }
        .onDisappear {
            self.model.task?.cancel()
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Incompatible Characters", tableName: "Document"))
        .controlSize(.small)
        .frame(maxWidth: .infinity, minHeight: self.model.items.isEmpty ? 60 : 120, alignment: .topLeading)
    }
}


private extension IncompatibleCharactersView.Model {
    
    /// Selects correspondence range of the item in the editor.
    ///
    /// - Parameter id: The `id` of the item to select.
    func selectItem(id: Item.ID?) {
        
        guard
            let item = self.items.first(where: { $0.id == id }),
            let textView = self.document?.textView,
            textView.string.length >= item.range.upperBound
        else { return }
        
        textView.selectedRange = item.range
        textView.centerSelectionInVisibleArea(self)
    }
    
    
    func invalidateObservation() {
        
        if let document {
            self.observer = Publishers.Merge3(
                Just(Void()),  // initial scan
                NotificationCenter.default.publisher(for: NSTextStorage.didProcessEditingNotification, object: document.textStorage)
                    .map { $0.object as! NSTextStorage }
                    .filter { $0.editedMask.contains(.editedCharacters) }
                    .debounce(for: .seconds(0.3), scheduler: RunLoop.current)
                    .eraseToVoid(),
                document.$fileEncoding
                    .map(\.encoding)
                    .removeDuplicates()
                    .eraseToVoid()
            )
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                self.task?.cancel()
                self.task = Task {
                    let items = try await self.scan()
                    self.updateMarkup(items)
                    self.items = items
                }
            }
            
        } else {
            self.observer = nil
            self.task?.cancel()
            self.updateMarkup([])
        }
    }
    
    
    // MARK: Private Methods
    
    /// Scans the characters incompatible with the current encoding in the document contents.
    ///
    /// - Returns: An array of Item.
    /// - Throws: `CancellationError`
    @MainActor private func scan() async throws -> [ValueRange<IncompatibleCharacter>] {
        
        assert(Thread.isMainThread)
        
        guard let document else { return [] }
        
        let string = document.textStorage.string
        let encoding = document.fileEncoding.encoding
        
        guard !string.canBeConverted(to: encoding) else { return [] }
        
        self.isScanning = true
        defer { self.isScanning = false }
        
        return try await Task.detached { [string = string.immutable] in
            try string.charactersIncompatible(with: encoding)
        }.value
    }
    
    
    /// Update markup in the editors.
    ///
    /// - Parameter items: The new incompatible characters.
    @MainActor private func updateMarkup(_ items: [ValueRange<IncompatibleCharacter>]) {
        
        if !self.items.isEmpty {
            self.document?.textStorage.clearAllMarkup()
        }
        self.document?.textStorage.markup(ranges: items.map(\.range))
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
    let model = IncompatibleCharactersView.Model()
    model.items = [
        .init(value: .init(character: "~", converted: "-"), range: .notFound),
        .init(value: .init(character: " ", converted: "?"), range: .notFound),
    ]
    
    return IncompatibleCharactersView(model: model)
        .padding(12)
}

@available(macOS 14, *)
#Preview("Empty", traits: .fixedLayout(width: 240, height: 300)) {
    IncompatibleCharactersView(model: .init())
        .padding(12)
}
