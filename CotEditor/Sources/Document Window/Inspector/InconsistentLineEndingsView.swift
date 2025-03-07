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
import Observation
import LineEnding
import ValueRange

struct InconsistentLineEndingsView: View {
    
    typealias Item = ValueRange<LineEnding>
    
    
    var document: Document?
    
    @State var items: [Item] = []
    @State var lineEnding: LineEnding = .lf
    
    @State private var selection: Item.ID?
    @State private var sortOrder: [KeyPathComparator<Item>] = []
    
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 8) {
            Text("Inconsistent Line Endings", tableName: "Document", comment: "section title in inspector")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.secondary)
                .accessibilityRemoveTraits(.isHeader)
            
            if self.items.isEmpty {
                Text("No issues found.", tableName: "Document")
                    .foregroundStyle(.secondary)
            } else {
                Text("Found \(self.items.count) line endings other than \(self.lineEnding.label).",
                     tableName: "Document",
                     comment: "%lld is the number of inconsistent line endings and %@ is a line ending type, such as LF")
            }
            
            if !self.items.isEmpty {
                Table(self.items, selection: $selection, sortOrder: $sortOrder) {
                    TableColumn(String(localized: "Line", table: "Document", comment: "table column header"), value: \.lowerBound) {
                        // calculate the line number first at this point to postpone the high cost processing as much as possible
                        if let line = self.document?.lineEndingScanner.lineNumber(at: $0.lowerBound) {
                            Text(line, format: .number)
                                .monospacedDigit()
                        }
                    }
                    .alignment(.trailing)
                    
                    TableColumn(String(localized: "Line Ending", table: "Document", comment: "table column header"), value: \.value.rawValue) {
                        Text($0.value.label)
                    }
                }
                .onChange(of: self.selection) { (_, newValue) in
                    self.selectItem(id: newValue)
                }
                .onChange(of: self.sortOrder) { (_, newValue) in
                    withAnimation {
                        self.items.sort(using: newValue)
                    }
                }
                .tableStyle(.bordered)
                .border(Color(nsColor: .gridColor))
            }
        }
        .onChange(of: self.document?.lineEndingScanner.inconsistentLineEndings, initial: true) { (_, newValue) in
            self.items = (newValue ?? []).sorted(using: self.sortOrder)
        }
        .onChange(of: self.document?.lineEndingScanner.baseLineEnding, initial: true) { (_, newValue) in
            self.lineEnding = newValue ?? .lf
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Inconsistent Line Endings", tableName: "Document"))
        .controlSize(.small)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    
    
    // MARK: Private Methods
    
    /// Selects correspondence range of the item in the editor.
    ///
    /// - Parameter id: The `id` of the item to select.
    private func selectItem(id: Item.ID?) {
        
        guard
            let item = self.items[id: id],
            let textView = self.document?.textView,
            textView.string.length >= item.range.upperBound
        else { return }
        
        textView.selectedRange = item.range
        textView.centerSelectionInVisibleArea(self)
    }
}


// MARK: - Preview

#Preview(traits: .fixedLayout(width: 240, height: 300)) {
    InconsistentLineEndingsView(items: [
        .init(value: .cr, range: .notFound)
    ])
    .padding(12)
}

#Preview("Empty", traits: .fixedLayout(width: 240, height: 300)) {
    InconsistentLineEndingsView()
        .padding(12)
}
