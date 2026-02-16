//
//  OutlineInspectorView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-02-27.
//
//  ---------------------------------------------------------------------------
//
//  © 2018-2026 1024jp
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
import Defaults
import Syntax
import StringUtils

@MainActor @Observable private final class OutlineInspectorViewModel: OutlineInspectorView.ModelProtocol {
    
    var isPresented = false  { didSet { self.invalidateObservation() } }
    var document: Document?  { didSet { self.invalidateObservation() } }
    
    var items: [Item] = []
    var selection: Item.ID?  { didSet { self.selectItem(id: selection) } }
    
    private var isOwnSelectionChange = false
    private var documentObserver: AnyCancellable?
    private var syntaxObserver: AnyCancellable?
    private var selectionObserver: AnyCancellable?
    
    
    /// Selects correspondence range of the item in the editor.
    ///
    /// Call this method in `didSet` of `selection` instead of `onChange(of:)` in SwiftUI view.
    ///
    /// - Parameter id: The `id` of the item to select.
    func selectItem(id: Item.ID?) {
        
        guard
            !self.isOwnSelectionChange,
            let item = self.items[id: id],
            let textView = self.document?.textView,
            textView.string.length >= item.range.upperBound
        else { return }
        
        textView.selectedRange = item.range
        textView.centerSelectionInVisibleArea(self)
    }
    
    
    /// Updates observations.
    private func invalidateObservation() {
        
        if let document, self.isPresented {
            self.documentObserver = document.$syntaxName
                .sink { [weak self] _ in
                    self?.syntaxObserver = self?.document?.syntaxController.$outlineItems
                        .compactMap(\.self)
                        .sink { [weak self] in
                            self?.items = $0
                            self?.invalidateCurrentItem()
                        }
                }
            
            self.selectionObserver = NotificationCenter.default.publisher(for: NSTextView.didChangeSelectionNotification)
                .map { $0.object as! NSTextView }
                .filter { [weak self] in $0.textStorage == self?.document?.textStorage }
                .filter { !$0.hasMarkedText() }
            // avoid updating outline item selection before finishing outline parse
            // -> Otherwise, a wrong item can be selected because of using the outdated outline ranges.
            //    You can ignore text selection change at this time point because the outline selection will be updated when the parse finished.
                .filter { $0.textStorage?.editedMask.contains(.editedCharacters) == false }
                .sink { [weak self] in self?.invalidateCurrentItem(in: $0) }
            
        } else {
            self.documentObserver = nil
            self.syntaxObserver = nil
            self.selectionObserver = nil
            self.items.removeAll()
        }
    }
    
    
    /// Updates row selection to synchronize with the editor's cursor location.
    ///
    /// - Parameters:
    ///   - textView: The text view to apply the selection. When `nil`, the current focused editor will be used.
    private func invalidateCurrentItem(in textView: NSTextView? = nil) {
        
        guard
            let textView = textView ?? self.document?.textView,
            let item = self.items.item(at: textView.selectedRange.location)
        else { return }
        
        self.isOwnSelectionChange = true
        self.selection = item.id
        self.isOwnSelectionChange = false
    }
}


// MARK: - View

struct OutlineInspectorView: View, HostedPaneView {
    
    @MainActor protocol ModelProtocol {
        
        typealias Item = OutlineItem
        
        var document: Document? { get set }
        var isPresented: Bool { get set }
        
        var items: [Item] { get }
        var selection: Item.ID? { get set }
    }
    
    
    var document: DataDocument?
    var isPresented: Bool = false
    
    @State var model: any ModelProtocol = OutlineInspectorViewModel()
    
    @AppStorage(.outlineViewFontSize) private var fontSize: Double
    
    @State private var filterString: String = ""
    
    
    // MARK: View Methods
    
    var body: some View {
        
        VStack(alignment: .leading) {
            Text("Outline", tableName: "Document", comment: "section title in inspector")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.secondary)
                .accessibilityRemoveTraits(.isHeader)
            
            let items = self.model.items
                .compactMap { $0.filter(self.filterString, keyPath: \.title) }
            
            List(items, selection: $model.selection) { item in
                OutlineRowView(item: item)
                    .font(.system(size: self.fontSize))
                    .listRowSeparator(.hidden)
            }
            .overlay {
                if !self.filterString.isEmpty, items.isEmpty {
                    Text("No Filter Results", tableName: "Document", comment: "filtering result message")
                        .foregroundStyle(.secondary)
                        .controlSize(.regular)
                }
            }
            .contextMenu {
                Menu(String(localized: "Text Size", table: "MainMenu")) {
                    Button(String(localized: "Bigger", table: "MainMenu"), systemImage: "textformat.size.larger", action: self.biggerFont)
                    Button(String(localized: "Smaller", table: "MainMenu"), systemImage: "textformat.size.smaller", action: self.smallerFont)
                    Button(String(localized: "Reset to Default", table: "MainMenu"), systemImage: "textformat.size", action: self.resetFont)
                }
            }
            .onCommand(#selector((any TextSizeChanging).biggerFont), perform: self.biggerFont)
            .onCommand(#selector((any TextSizeChanging).smallerFont), perform: self.smallerFont)
            .onCommand(#selector((any TextSizeChanging).resetFont), perform: self.resetFont)
            .border(.separator)
            .environment(\.defaultMinListRowHeight, self.fontSize)
            
            FilterField(text: $filterString)
                .autosaveName("OutlineSearch")
                .accessibilityAddTraits(.isSearchField)
                .controlSize(.regular)
        }
        .onChange(of: self.document, initial: true) { _, newValue in
            self.model.document = newValue as? Document
        }
        .onChange(of: self.isPresented, initial: true) { _, newValue in
            self.model.isPresented = newValue
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(String(localized: "InspectorPane.outline.label",
                                   defaultValue: "Outline", table: "Document"))
        .controlSize(.small)
        .padding(EdgeInsets(top: 8, leading: 12, bottom: 12, trailing: 12))
    }
    
    
    // MARK: Private Methods
    
    /// Makes the outline list's font size bigger.
    private func biggerFont() {
        
        self.fontSize += 1
    }
    
    
    /// Makes the outline list's font size smaller.
    private func smallerFont() {
        
        self.fontSize = max(self.fontSize - 1, NSFont.smallSystemFontSize)
    }
    
    
    /// Resets the outline list's font size to the default.
    private func resetFont() {
        
        UserDefaults.standard.restore(key: .outlineViewFontSize)
    }
}


private struct OutlineRowView: View {
    
    var item: FilteredItem<OutlineItem>
    
    
    var body: some View {
        
        if self.item.value.isSeparator {
            Divider().selectionDisabled()
            
        } else {
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text(self.item.value.displayIndent)
                if let kind = self.item.value.kind {
                    kind.icon()
                        .accessibilityLabel(kind.label)
                        .padding(.trailing, 4)
                }
                Text(self.item.attributedString
                    .replacingAttributes(AttributeContainer.inlinePresentationIntent(.stronglyEmphasized),
                                         with: AttributeContainer
                        .backgroundColor(.findHighlightColor)
                        .foregroundColor(.black.withAlphaComponent(0.9)))  // for legibility in Dark Mode
                )
                .fontWeight(self.item.value.style.contains(.bold) ? .semibold : .regular)
                .italic(self.item.value.style.contains(.italic))
                .lineLimit(1)
            }
        }
    }
}


// MARK: - Preview

#Preview(traits: .fixedLayout(width: 240, height: 300)) {
    
    @MainActor struct MockedModel: OutlineInspectorView.ModelProtocol {
        
        var document: Document?
        var isPresented: Bool = true
        
        var items: [Item] = []
        var selection: Item.ID?
    }
    
    @Previewable @State var model = MockedModel(items: [
        OutlineItem(title: "Hallo", range: .notFound, kind: .container),
        OutlineItem(title: "Guten Tag!", range: .notFound, kind: .function),
        OutlineItem.separator(range: .notFound),
        OutlineItem(title: "Hund", range: .notFound),
    ])
    
    return OutlineInspectorView(isPresented: true, model: model)
}
