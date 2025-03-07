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
//  © 2018-2025 1024jp
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
import Combine
import Defaults
import Syntax
import StringUtils

final class OutlineInspectorViewController: NSHostingController<OutlineInspectorView> {
    
    // MARK: Public Properties
    
    var document: Document? {
        
        didSet {
            if self.isViewShown {
                self.model.document = document
            }
        }
    }
    
    
    // MARK: Private Properties
    
    private let model = OutlineInspectorView.Model()
    
    
    // MARK: Lifecycle
    
    required init(document: Document?) {
        
        self.document = document
        
        super.init(rootView: OutlineInspectorView(model: self.model))
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        self.model.document = self.document
    }
    
    
    override func viewDidDisappear() {
        
        super.viewDidDisappear()
        
        self.model.document = nil
    }
}


struct OutlineInspectorView: View {
    
    @MainActor @Observable final class Model {
        
        typealias Item = OutlineItem
        
        
        var items: [Item] = []
        var selection: Item.ID?  { didSet { self.selectItem(id: selection) } }
        
        var document: Document?  { didSet { self.invalidateObservation() } }
        
        private var isOwnSelectionChange = false
        private var documentObserver: AnyCancellable?
        private var syntaxObserver: AnyCancellable?
        private var selectionObserver: AnyCancellable?
    }
    
    
    @State var model: Model
    
    @AppStorage(.outlineViewFontSize) private var fontSize: Double
    
    @State var filterString: String = ""
    
    
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
                OutlineRowView(item: item, fontSize: self.fontSize)
                    .listRowSeparator(.hidden)
                    .frame(height: self.fontSize)
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
                    Button(String(localized: "Bigger", table: "MainMenu"), action: self.biggerFont)
                    Button(String(localized: "Smaller", table: "MainMenu"), action: self.smallerFont)
                    Button(String(localized: "Reset to Default", table: "MainMenu"), action: self.resetFont)
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
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Outline", tableName: "Document"))
        .controlSize(.small)
        .padding(EdgeInsets(top: 8, leading: 12, bottom: 12, trailing: 12))
    }
    
    
    // MARK: Private Methods
    
    /// Make the outline list's font size bigger.
    private func biggerFont() {
        
        self.fontSize += 1
    }
    
    
    /// Make the outline list's font size smaller.
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
    var fontSize: Double = 0
    
    
    var body: some View {
        
        if self.item.value.isSeparator {
            Divider().selectionDisabled()
            
        } else {
            Text(self.item.attributedString
                .replacingAttributes(AttributeContainer.inlinePresentationIntent(.emphasized),
                                     with: AttributeContainer
                    .backgroundColor(.findHighlightColor)
                    .foregroundColor(.black.withAlphaComponent(0.9)))  // for legibility in Dark Mode
                .mergingAttributes(self.item.value.attributes(fontSize: fontSize), mergePolicy: .keepCurrent)
            )
        }
    }
}


private extension OutlineInspectorView.Model {
    
    /// Updates observations.
    func invalidateObservation() {
        
        if let document {
            self.documentObserver = document.didChangeSyntax
                .merge(with: Just(""))  // initial
                .sink { [weak self] _ in
                    self?.syntaxObserver = self?.document?.syntaxParser.$outlineItems
                        .compactMap(\.self)
                        .receive(on: DispatchQueue.main)
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
    
    
    /// Selects correspondence range of the item in the editor.
    ///
    /// - Parameter id: The `id` of the item to select.
    private func selectItem(id: Item.ID?) {
        
        guard
            !self.isOwnSelectionChange,
            let item = self.items[id: id],
            let textView = self.document?.textView,
            textView.string.length >= item.range.upperBound
        else { return }
        
        textView.selectedRange = item.range
        textView.centerSelectionInVisibleArea(self)
    }
    
    
    /// Updates row selection to synchronize with the editor's cursor location.
    ///
    /// - Parameters:
    ///   - textView: The text view to apply the selection. when `nil`,
    ///               the current focused editor will be used (the document can have multiple editors).
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


// MARK: - Preview

#Preview(traits: .fixedLayout(width: 240, height: 300)) {
    let model = OutlineInspectorView.Model()
    model.items = [
        OutlineItem(title: "Hallo", range: .notFound),
        OutlineItem(title: "Guten Tag!", range: .notFound, style: [.bold]),
        OutlineItem.separator(range: .notFound),
        OutlineItem(title: "Hund", range: .notFound, style: [.underline]),
    ]
    
    return OutlineInspectorView(model: model)
}
