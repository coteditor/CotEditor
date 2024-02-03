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
//  © 2018-2024 1024jp
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

final class OutlineInspectorViewController: NSHostingController<OutlineInspectorView>, DocumentOwner {
    
    // MARK: Public Properties
    
    var document: Document {
        
        get { self.model.document }
        set { self.model.document = newValue }
    }
    
    
    // MARK: Private Properties
    
    private let model: OutlineInspectorView.Model
    
    
    // MARK: Lifecycle
    
    required init(document: Document) {
        
        self.model = OutlineInspectorView.Model(document: document)
        
        super.init(rootView: OutlineInspectorView(model: model))
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        self.model.isAppeared = true
    }
    
    
    override func viewDidDisappear() {
        
        super.viewDidDisappear()
        
        self.model.isAppeared = false
    }
}


struct OutlineInspectorView: View {
    
    typealias Item = OutlineItem
    
    
    @MainActor final class Model: ObservableObject {
        
        var document: Document  { didSet { self.invalidateObservation() } }
        var isAppeared = false  { didSet { self.invalidateObservation() } }
        
        @Published var items: [Item] = []
        @Published var selection: Item.ID?
        @Published var filterString: String = ""
        
        var isOwnSelectionChange = false
        private var documentObserver: AnyCancellable?
        private var syntaxObserver: AnyCancellable?
        private var selectionObserver: AnyCancellable?
        
        
        init(document: Document) {
            
            self.document = document
        }
    }
    
    
    @ObservedObject var model: Model
    
    @AppStorage(.outlineViewFontSize) private var fontSize: Double
    
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 8) {
            Text("Outline", tableName: "Inspector", comment: "section title")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.secondary)
            
            ZStack {
                let items = self.model.items.filterItems(with: self.model.filterString)
                
                List(items, selection: $model.selection) { item in
                    OutlineRowView(item: item)
                        .listRowSeparator(.hidden)
                        .font(.system(size: self.fontSize))
                        .frame(height: self.fontSize)
                }
                .onReceive(self.model.$selection) { id in
                    // use .onReceive instead of .onChange to control the timing
                    self.selectItem(id: id)
                }
                .onCommand(#selector(EditorTextView.biggerFont)) {
                    self.fontSize += 1
                }
                .onCommand(#selector(EditorTextView.smallerFont)) {
                    self.fontSize = max(self.fontSize - 1, NSFont.smallSystemFontSize)
                }
                .onCommand(#selector(EditorTextView.resetFont)) {
                    UserDefaults.standard.restore(key: .outlineViewFontSize)
                }
                .listStyle(.inset)
                .border(Color(nsColor: .gridColor))
                .environment(\.defaultMinListRowHeight, self.fontSize)
                
                if !self.model.filterString.isEmpty, items.isEmpty {
                    Text("No Filter Results", tableName: "Inspector", comment: "display on list when no results in filtering outline items")
                        .foregroundStyle(.secondary)
                        .controlSize(.regular)
                }
            }
            
            FilterField(text: $model.filterString)
                .autosaveName("OutlineSearch")
                .controlSize(.regular)
        }
        .onAppear {
            self.model.isAppeared = true
        }
        .onDisappear {
            self.model.isAppeared = false
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Outline", tableName: "Inspector"))
        .controlSize(.small)
        .padding(.top, 8)
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    
    
    /// Selects correspondence range of the item in the editor.
    ///
    /// - Parameter id: The `id` of the item to select.
    @MainActor private func selectItem(id: Item.ID?) {
        
        guard
            !self.model.isOwnSelectionChange,
            let item = self.model.items.first(where: { $0.id == id }),
            let textView = self.model.document.textView,
            textView.string.length >= item.range.upperBound
        else { return }
        
        textView.selectedRange = item.range
        textView.centerSelectionInVisibleArea(self)
    }
}


private extension OutlineInspectorView.Model {
    
    func invalidateObservation() {
        
        if self.isAppeared {
            self.documentObserver = self.document.didChangeSyntax
                .merge(with: Just(""))  // initial
                .sink { [weak self] _ in
                    self?.syntaxObserver = self?.document.syntaxParser.$outlineItems
                        .compactMap { $0 }
                        .receive(on: DispatchQueue.main)
                        .sink { [weak self] in
                            self?.items = $0
                            self?.invalidateCurrentItem()
                        }
                }
            
            self.selectionObserver = NotificationCenter.default.publisher(for: NSTextView.didChangeSelectionNotification)
                .map { $0.object as! NSTextView }
                .filter { [weak self] in $0.textStorage == self?.document.textStorage }
                .filter { !$0.hasMarkedText() }
                // avoid updating outline item selection before finishing outline parse
                // -> Otherwise, a wrong item can be selected because of using the outdated outline ranges.
                //    You can ignore text selection change at this time point because the outline selection will be updated when the parse finished.
                .filter { $0.textStorage?.editedMask.contains(.editedCharacters) == false }
                .debounce(for: .seconds(0.05), scheduler: RunLoop.main)
                .sink { self.invalidateCurrentItem(in: $0) }
            
        } else {
            self.documentObserver = nil
            self.syntaxObserver = nil
            self.selectionObserver = nil
        }
    }
    
    
    /// Updates row selection to synchronize with the editor's cursor location.
    ///
    /// - Parameter textView: The text view to apply the selection. when nil, the current focused editor will be used (the document can have multiple editors).
    private func invalidateCurrentItem(in textView: NSTextView? = nil) {
        
        guard
            self.filterString.isEmpty,
            let textView = textView ?? self.document.textView,
            let item = self.items.item(at: textView.selectedRange.location)
        else { return }
        
        self.isOwnSelectionChange = true
        self.selection = item.id
        self.isOwnSelectionChange = false
    }
}


private struct OutlineRowView: View {
    
    var item: OutlineItem
    
    var body: some View {
        
        if self.item.isSeparator {
            if #available(macOS 14, *) {
                Divider().selectionDisabled()
            } else {
                Divider()
            }
        } else {
            Text(self.item.attributedTitle)
                .fontWeight(self.item.style.contains(.bold) ? .semibold : nil)
                .italic(self.item.style.contains(.italic))
                .underline(self.item.style.contains(.underline))
                .truncationMode(.tail)
        }
    }
}



// MARK: - Preview

@available(macOS 14, *)
#Preview(traits: .fixedLayout(width: 240, height: 300)) {
    let model = OutlineInspectorView.Model(document: .init())
    model.items = [
        OutlineItem(title: "Hello", range: .notFound),
        OutlineItem(title: "Guten Tag!", range: .notFound, style: [.bold]),
        OutlineItem(title: "-", range: .notFound),
        OutlineItem(title: "Hund", range: .notFound, style: [.underline]),
    ]
    
    return OutlineInspectorView(model: model)
}
