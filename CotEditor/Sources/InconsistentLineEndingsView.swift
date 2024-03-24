//
//  InconsistentLineEndingsView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2022-04-11.
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

import SwiftUI
import Combine

struct InconsistentLineEndingsView: View {
    
    @MainActor final class Model: ObservableObject {
        
        typealias Item = ValueRange<LineEnding>
        
        
        @Published var items: [Item] = []
        @Published var lineEnding: LineEnding = .lf
        
        var document: Document?  { didSet { self.invalidateObservation() } }
        
        private var observers: Set<AnyCancellable> = []
    }
    
    
    @ObservedObject var model: Model
    
    @State private var selection: Model.Item.ID?
    @State private var sortOrder: [KeyPathComparator<Model.Item>] = []
    
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 8) {
            Text("Inconsistent Line Endings", tableName: "Document", comment: "section title in inspector")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.secondary)
            
            if self.model.items.isEmpty {
                Text("No issues found.", tableName: "Document")
                    .foregroundStyle(.secondary)
            } else {
                Text("Found \(self.model.items.count) line endings other than \(self.model.lineEnding.label).",
                     tableName: "Document",
                     comment: "%lld is the number of inconsistent line endings and %@ is a line ending type, such as LF")
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
                    
                    TableColumn(String(localized: "Line Ending", table: "Document", comment: "table column header"), value: \.value.rawValue) {
                        Text($0.value.label)
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
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Inconsistent Line Endings", tableName: "Document"))
        .controlSize(.small)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}


private extension InconsistentLineEndingsView.Model {
    
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
            self.observers = [
                document.lineEndingScanner.$inconsistentLineEndings
                    .removeDuplicates()
                    .receive(on: RunLoop.main)
                    .sink { [weak self] in self?.items = $0 },
                document.$lineEnding
                    .removeDuplicates()
                    .receive(on: RunLoop.main)
                    .sink { [weak self] in self?.lineEnding = $0 },
            ]
        } else {
            self.observers.removeAll()
        }
    }
}



// MARK: - Preview

@available(macOS 14, *)
#Preview(traits: .fixedLayout(width: 240, height: 300)) {
    let model = InconsistentLineEndingsView.Model()
    model.items = [
        .init(value: .cr, range: .notFound)
    ]
    
    return InconsistentLineEndingsView(model: model)
        .padding(12)
}

@available(macOS 14, *)
#Preview("Empty", traits: .fixedLayout(width: 240, height: 300)) {
    InconsistentLineEndingsView(model: .init())
        .padding(12)
}
