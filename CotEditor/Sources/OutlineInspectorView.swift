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
        
        didSet {
            if self.isViewShown {
                self.model.document = document
            }
        }
    }
    
    
    // MARK: Private Properties
    
    private let model = OutlineInspectorView.Model()
    
    
    // MARK: Lifecycle
    
    required init(document: Document) {
        
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
    
    @MainActor final class Model: ObservableObject {
        
        typealias Item = OutlineItem
        
        
        @Published var items: [Item] = []
        @Published var selection: Item.ID?
        
        var document: Document?  { didSet { self.invalidateObservation() } }
        
        private var isOwnSelectionChange = false
        private var documentObserver: AnyCancellable?
        private var syntaxObserver: AnyCancellable?
        private var selectionObserver: AnyCancellable?
    }
    
    
    @ObservedObject var model: Model
    
    @AppStorage(.outlineViewFontSize) private var fontSize: Double
    
    @State var filterString: String = ""
    
    
    var body: some View {
        
        VStack(alignment: .leading) {
            Text("Outline", tableName: "Inspector", comment: "section title")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.secondary)
            
            ZStack {
                let items = self.model.items.filterItems(with: self.filterString)
                
                List(items, selection: $model.selection) { item in
                    OutlineRowView(item: item)
                        .listRowSeparator(.hidden)
                        .font(.system(size: self.fontSize))
                        .frame(height: self.fontSize)
                }
                .onReceive(self.model.$selection) { id in
                    // use .onReceive(_:) instead of .onChange(of:) to control the timing
                    self.model.selectItem(id: id)
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
                .border(.separator)
                .environment(\.defaultMinListRowHeight, self.fontSize)
                
                if !self.filterString.isEmpty, items.isEmpty {
                    Text("No Filter Results", tableName: "Inspector", comment: "display on the list when no results in filtering outline items")
                        .foregroundStyle(.secondary)
                        .controlSize(.regular)
                }
            }
            
            FilterField(text: $filterString)
                .autosaveName("OutlineSearch")
                .controlSize(.regular)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Outline", tableName: "Inspector"))
        .controlSize(.small)
        .padding(EdgeInsets(top: 8, leading: 12, bottom: 12, trailing: 12))
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
                .bold(self.item.style.contains(.bold))
                .italic(self.item.style.contains(.italic))
                .underline(self.item.style.contains(.underline))
        }
    }
}


private extension OutlineInspectorView.Model {
    
    /// Selects correspondence range of the item in the editor.
    ///
    /// - Parameter id: The `id` of the item to select.
    func selectItem(id: Item.ID?) {
        
        guard
            !self.isOwnSelectionChange,
            let item = self.items.first(where: { $0.id == id }),
            let textView = self.document?.textView,
            textView.string.length >= item.range.upperBound
        else { return }
        
        textView.selectedRange = item.range
        textView.centerSelectionInVisibleArea(self)
    }
    
    
    func invalidateObservation() {
        
        if let document {
            self.documentObserver = document.didChangeSyntax
                .merge(with: Just(""))  // initial
                .sink { [weak self] _ in
                    self?.syntaxObserver = self?.document?.syntaxParser.$outlineItems
                        .compactMap { $0 }
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
                .debounce(for: .seconds(0.05), scheduler: RunLoop.main)
                .sink { [weak self] in self?.invalidateCurrentItem(in: $0) }
            
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
            let textView = textView ?? self.document?.textView,
            let item = self.items.item(at: textView.selectedRange.location)
        else { return }
        
        self.isOwnSelectionChange = true
        self.selection = item.id
        self.isOwnSelectionChange = false
    }
}



// MARK: - Preview

@available(macOS 14, *)
#Preview(traits: .fixedLayout(width: 240, height: 300)) {
    let model = OutlineInspectorView.Model()
    model.items = [
        OutlineItem(title: "Hallo", range: .notFound),
        OutlineItem(title: "Guten Tag!", range: .notFound, style: [.bold]),
        OutlineItem(title: "-", range: .notFound),
        OutlineItem(title: "Hund", range: .notFound, style: [.underline]),
    ]
    
    return OutlineInspectorView(model: model)
}
