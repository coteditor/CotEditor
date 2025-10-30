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
//  © 2024-2025 1024jp
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
import CharacterInfo
import FileEncoding
import LineEnding
import StringUtils
import ValueRange

struct IncompatibleCharactersView: View {
    
    @MainActor @Observable final class Model {
        
        typealias Item = ValueRange<IncompatibleCharacter>
        
        
        var items: [Item] = []
        private(set) var isScanning = false
        
        private var document: Document?
        
        private(set) var task: Task<Void, any Error>?
        private var observers: Set<AnyCancellable> = []
    }
    
    
    var document: Document?
    
    @State var model = Model()
    
    @State private var selection: Model.Item.ID?
    @State private var sortOrder: [KeyPathComparator<Model.Item>] = []
    
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 8) {
            Text("Incompatible Characters", tableName: "Document",
                 comment: "section title in inspector")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.secondary)
                .accessibilityRemoveTraits(.isHeader)
            
            if self.model.isScanning {
                Text("Scanning incompatible characters…", tableName: "Document")
            } else if !self.model.items.isEmpty {
                Text("Found \(self.model.items.count) incompatible characters.", tableName: "Document",
                     comment: "%lld is the number of characters.")
            } else {
                Text("No issues found.", tableName: "Document")
                    .foregroundStyle(.secondary)
            }
            
            if !self.model.items.isEmpty {
                Table(self.model.items, selection: $selection, sortOrder: $sortOrder) {
                    TableColumn(String(localized: "Line", table: "Document", comment: "table column header"), value: \.lowerBound) {
                        // calculate the line number first at this point to postpone the high cost processing as much as possible
                        if let line = self.model.lineNumber(at: $0.lowerBound) {
                            Text(line, format: .number)
                                .monospacedDigit()
                        }
                    }
                    .alignment(.trailing)
                    
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
                    
                    TableColumn(String(localized: "Converted", table: "Document", comment: "table column header for converted character"), sortUsing: KeyPathComparator(\.value.converted)) {
                        if let converted = $0.value.converted {
                            Text(converted)
                        }
                    }
                }
                .onChange(of: self.selection) { _, newValue in
                    self.model.selectItem(id: newValue)
                }
                .onChange(of: self.sortOrder) { _, newValue in
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
        .onChange(of: self.document, initial: true) { _, newValue in
            self.model.updateDocument(newValue)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(String(localized: "Incompatible Characters", table: "Document"))
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
            let item = self.items[id: id],
            let textView = self.document?.textView,
            textView.string.length >= item.range.upperBound
        else { return }
        
        textView.selectedRange = item.range
        textView.centerSelectionInVisibleArea(self)
    }
    
    
    /// Returns the line number at the character location.
    ///
    /// - Parameter location: The character location.
    /// - Returns: A line number.
    func lineNumber(at location: Int) -> Int? {
        
        self.document?.lineEndingScanner.lineNumber(at: location)
    }
    
    
    /// Updates the document.
    ///
    /// - Parameter document: The new document.
    func updateDocument(_ document: Document?) {
        
        self.document = document
        self.invalidateObservation()
    }
    
    
    // MARK: Private Methods
    
    /// Updates observations.
    private func invalidateObservation() {
        
        self.observers.removeAll()
        
        if let document {
            self.invalidateIncompatibleCharacters()
            
            NotificationCenter.default.publisher(for: NSTextStorage.didProcessEditingNotification, object: document.textStorage)
                .map { $0.object as! NSTextStorage }
                .filter { $0.editedMask.contains(.editedCharacters) }
                .debounce(for: .seconds(0.3), scheduler: RunLoop.current)
                .sink { [weak self] _ in self?.invalidateIncompatibleCharacters() }
                .store(in: &self.observers)
            document.$fileEncoding
                .map(\.encoding)
                .removeDuplicates()
                .sink { [weak self] _ in self?.invalidateIncompatibleCharacters() }
                .store(in: &self.observers)
            
        } else {
            self.task?.cancel()
            self.items.removeAll()
            self.isScanning = false
        }
    }
    
    
    /// Updates incompatible characters.
    private func invalidateIncompatibleCharacters() {
        
        self.task?.cancel()
        self.task = Task {
            let items = try await self.scan()
            self.items = items
            self.document?.textView?.updateBackgroundColor(.unemphasizedSelectedTextBackgroundColor, ranges: items.map(\.range))
        }
    }
    
    
    /// Scans the characters incompatible with the current encoding in the document contents.
    ///
    /// - Returns: An array of Item.
    /// - Throws: `CancellationError`
    private func scan() async throws -> [ValueRange<IncompatibleCharacter>] {
        
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
}


// MARK: - Preview

#Preview(traits: .fixedLayout(width: 240, height: 300)) {
    let model = IncompatibleCharactersView.Model()
    model.items = [
        .init(value: .init(character: "~", converted: "-"), range: .notFound),
        .init(value: .init(character: " ", converted: "?"), range: .notFound),
    ]
    
    return IncompatibleCharactersView(model: model)
        .padding(12)
}

#Preview("Empty", traits: .fixedLayout(width: 240, height: 300)) {
    IncompatibleCharactersView()
        .padding(12)
}
