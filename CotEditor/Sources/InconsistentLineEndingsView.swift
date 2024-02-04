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
    
    typealias Item = ValueRange<LineEnding>
    
    
    @MainActor final class Model: ObservableObject {
        
        var document: Document  { didSet { self.invalidateObservation() } }
        var isAppeared = false  { didSet { self.invalidateObservation() } }
        
        @Published var items: [Item] = []
        @Published var current: LineEnding = .lf
        
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
            Text("Inconsistent Line Endings", tableName: "Inspector", comment: "section title")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.secondary)
            
            // message
            if self.model.items.isEmpty {
                Text("No issues found.", tableName: "Inspector")
                    .foregroundStyle(.secondary)
            } else {
                Text("Found \(self.model.items.count) line endings other than \(self.model.current.name).",
                     tableName: "Inspector",
                     comment: "%lld is the number of inconsistent line endings and %@ is a line ending type, such as LF")
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
                    
                    TableColumn(String(localized: "Line Ending", table: "Inspector", comment: "table column"), value: \.value.rawValue) {
                        Text($0.value.name)
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
        .accessibilityLabel(Text("Inconsistent Line Endings", tableName: "Inspector"))
        .controlSize(.small)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    
    
    /// Selects correspondence range of the item in the editor.
    ///
    /// - Parameter id: The `id` of the item to select.
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


private extension InconsistentLineEndingsView.Model {
    
    func invalidateObservation() {
        
        if self.isAppeared {
            self.observers = [
                self.document.lineEndingScanner.$inconsistentLineEndings
                    .removeDuplicates()
                    .receive(on: RunLoop.main)
                    .sink { [weak self] in self?.items = $0 },
                self.document.$lineEnding
                    .removeDuplicates()
                    .receive(on: RunLoop.main)
                    .sink { [weak self] in self?.current = $0 },
            ]
        } else {
            self.observers.removeAll()
        }
    }
}



// MARK: - Preview

@available(macOS 14, *)
#Preview(traits: .fixedLayout(width: 240, height: 300)) {
    let document = Document()
    document.textStorage.replaceContent(with: "  \r \n \r")
    
    return InconsistentLineEndingsView(model: .init(document: document))
        .padding(12)
}

@available(macOS 14, *)
#Preview("Empty", traits: .fixedLayout(width: 240, height: 300)) {
    InconsistentLineEndingsView(model: .init(document: .init()))
        .padding(12)
}
