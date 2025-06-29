//
//  EncodingListView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2022-07-23.
//
//  ---------------------------------------------------------------------------
//
//  © 2022-2025 1024jp
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
import Defaults
import FileEncoding

private struct EncodingItem: Equatable, Identifiable {
    
    /// Returns every time a new instance with a different id.
    static var separator: Self  { Self(encoding: kCFStringEncodingInvalidId) }
    
    let id = UUID()
    var encoding: CFStringEncoding
    
    var isSeparator: Bool  { self.encoding == kCFStringEncodingInvalidId }
}


struct EncodingListView: View {
    
    @MainActor @Observable fileprivate final class Model {
        
        typealias Item = EncodingItem
        
        
        private(set) var items: [Item]
        
        @ObservationIgnored var undoManager: UndoManager?
        
        private let defaults: UserDefaults
        
        
        init(defaults: UserDefaults = .standard) {
            
            self.items = defaults[.encodingList].map(Item.init(encoding:))
            self.defaults = defaults
        }
    }
    
    
    @State private var model = Model()
    @State private var selection: Set<Model.Item.ID> = []
    
    @Environment(\.undoManager) private var undoManager
    @Environment(\.dismiss) private var dismiss
    
    
    var body: some View {
        
        VStack(alignment: .leading) {
            Text("Drag encodings to change the order:", tableName: "EncodingList")
            
            List(selection: $selection) {
                ForEach(self.model.items) { item in
                    VStack(alignment: .leading, spacing: 8) {
                        if item.isSeparator {
                            Divider()
                        } else if item.encoding == .utf8 {
                            EncodingView(encoding: item.encoding)
                            EncodingView(encoding: item.encoding, withUTF8BOM: true)
                        } else {
                            EncodingView(encoding: item.encoding)
                        }
                    }.listRowSeparator(.hidden)
                }.onMove { (indexes, index) in
                    self.model.move(from: indexes, to: index)
                }
            }
            .onDeleteCommand {
                self.model.remove(ids: self.selection)
            }
            .animation(.default, value: self.model.items)
            .scrollContentBackground(.hidden)
            .background(RoundedRectangle(cornerRadius: 6)
                .fill(.fill.quaternary)
                .stroke(.separator))
            .environment(\.defaultMinListRowHeight, 14)
            .frame(minHeight: 250, idealHeight: 250)
            
            Text("This order is for the encoding menu and the encoding detection. The detection process only considers the items listed here, with higher items being prioritized.", tableName: "EncodingList")
                .controlSize(.small)
                .fixedSize(horizontal: false, vertical: true)
            
            HStack {
                Button(String(localized: "Button.restoreDefaults.label", defaultValue: "Restore Defaults", table: "Control"), action: self.model.restore)
                    .disabled(!self.model.canRestore)
                
                Spacer()
                
                ControlGroup {
                    Menu(String(localized: "Button.add.label", defaultValue: "Add", table: "Control"), systemImage: "plus") {
                        let listedEncodings = self.model.items.compactMap(\.encoding)
                        let encodings = String.availableStringEncodings
                            .filter { !listedEncodings.contains($0.cfEncoding) }
                            .sorted(using: KeyPathComparator(\.localizedName, comparator: .localizedStandard))
                        
                        Button(String(localized: "Separator", table: "EncodingList")) {
                            let item = self.model.addSeparator(after: self.selection)
                            self.selection = [item.id]
                        }
                        
                        Section(String(localized: "Text Encoding", table: "EncodingList")) {
                            ForEach(encodings, id: \.rawValue) { encoding in
                                Button(encoding.localizedName) {
                                    let item = self.model.addEncoding(encoding.cfEncoding, after: self.selection)
                                    self.selection = [item.id]
                                }
                            }
                        }
                    }
                    
                    let removalError = self.model.canRemove(ids: self.selection)
                    Button(String(localized: "Button.remove.label", defaultValue: "Remove", table: "Control"), systemImage: "minus") {
                        self.model.remove(ids: self.selection)
                    }
                    .disabled(removalError != nil)
                    .help(removalError?.localizedDescription ?? "")
                }
                .menuStyle(.button)
                .menuIndicator(.hidden)
                .labelStyle(.iconOnly)
                .fixedSize()
            }
            .padding(.bottom)
            
            HStack {
                HelpLink(anchor: "howto_customize_encoding_order")
                
                Spacer()
                
                SubmitButtonGroup {
                    self.model.save()
                    self.dismiss()
                } cancelAction: {
                    self.dismiss()
                }
            }
        }
        .onAppear {
            self.model.undoManager = self.undoManager
        }
        .scenePadding()
        .frame(idealWidth: 380, maxHeight: 450)
    }
}


private struct EncodingView: View {
    
    var encoding: CFStringEncoding
    var withUTF8BOM = false
    
    
    var body: some View {
        
        HStack(alignment: .firstTextBaseline) {
            Text(self.name)
            Text(self.ianaCharsetName)
                .foregroundStyle(.secondary)
        }.frame(height: 14)
    }
    
    
    private var name: String {
        
        FileEncoding(encoding: String.Encoding(cfEncoding: self.encoding),
                     withUTF8BOM: self.withUTF8BOM).localizedName
    }
    
    
    private var ianaCharsetName: String {
        
        CFStringConvertEncodingToIANACharSetName(self.encoding) as String? ?? "–"
    }
}


private extension String.Encoding {
    
    var localizedName: String  { String.localizedName(of: self) }
}


// MARK: -

private extension EncodingListView.Model {
    
    enum RemovalError: Error {
        
        case noItem
        case encoding(String.Encoding)
        case defaultEncoding
    }
    
    
    /// Whether the current order differs from the default.
    var canRestore: Bool {
        
        self.items.map(\.encoding) != self.defaults[initial: .encodingList]
    }
    
    
    /// Moves items to the given destination.
    ///
    /// - Parameters:
    ///   - source: The indexes of items to move.
    ///   - destination: The destination index to move to.
    func move(from source: IndexSet, to destination: Int) {
        
        self.registerUndo()
        
        self.items.move(fromOffsets: source, toOffset: destination)
    }
    
    
    /// Returns whether the all items of given ids can be removed.
    ///
    /// - Parameter ids: The item ids to check.
    /// - Returns: `nil` if the items can be removed, otherwise `RemovalError`.
    func canRemove(ids: Set<Item.ID>) -> RemovalError? {
        
        guard !ids.isEmpty else { return .noItem }
        
        return self.items.filter(with: ids).lazy.compactMap(self.canRemove).first
    }
    
    
    /// Restores the list to the default.
    func restore() {
        
        self.items = self.defaults[initial: .encodingList].map(EncodingItem.init)
    }
    
    
    /// Saves the current encodings to the user default.
    func save() {
        
        self.defaults[.encodingList] = self.items.map(\.encoding)
    }
    
    
    /// Adds a separator below the last of the given items.
    ///
    /// - Parameters:
    ///   - ids: The selection ids.
    func addSeparator(after ids: Set<Item.ID>) -> Item {
        
        self.registerUndo()
        
        let index = self.items.lastIndex { ids.contains($0.id) }
        let item: Item = .separator
        self.items.insert(item, at: index?.advanced(by: 1) ?? 0)
        
        return item
    }
    
    
    /// Adds a text encoding below the last of the given items.
    ///
    /// - Parameters:
    ///   - encoding: The text encoding to add.
    ///   - ids: The selection ids.
    func addEncoding(_ encoding: CFStringEncoding, after ids: Set<Item.ID>) -> Item {
        
        assert(self.items.allSatisfy({ $0.encoding != encoding }))
        
        self.registerUndo()
        
        let index = self.items.lastIndex { ids.contains($0.id) }
        let item = Item(encoding: encoding)
        self.items.insert(item, at: index?.advanced(by: 1) ?? 0)
        
        return item
    }
    
    
    /// Removes items with the given IDs.
    ///
    /// - Parameters:
    ///   - ids: The selection ids.
    func remove(ids: Set<Item.ID>) {
        
        self.registerUndo()
        
        self.items.removeAll { ids.contains($0.id) && (self.canRemove($0) == nil) }
    }
    
    
    // MARK: Private Methods
    
    /// Checks whether the given item can be removed.
    ///
    /// - Parameter item: The item to remove.
    /// - Returns: `nil` if it can be removed, otherwise `RemovalError`.
    private func canRemove(_ item: Item) -> RemovalError? {
        
        switch item.encoding {
            case .utf8:
                .encoding(.utf8)
            case UInt32(self.defaults[.encoding]):
                .defaultEncoding
            default:
                nil
        }
    }
    
    
    /// Registers the current state for both undo/redo.
    private func registerUndo() {
        
        self.undoManager?.registerUndo(withTarget: self) { [items = self.items] target in
            MainActor.assumeIsolated {
                target.update(items: items)
            }
        }
    }
    
    
    /// Updates the items and registers the current state to the undo manager.
    ///
    /// - Parameters:
    ///   - items: The new items.
    private func update(items: [Item]) {
        
        self.undoManager?.registerUndo(withTarget: self) { [items = self.items] target in
            MainActor.assumeIsolated {
                target.update(items: items)
            }
        }
        
        self.items = items
    }
}


private extension EncodingListView.Model.RemovalError {
    
    var localizedDescription: String? {
        
        switch self {
            case .noItem:
                nil
            case .encoding(let encoding):
                String(localized: "EncodingListView.Model.RemovalError.utf8.description",
                       defaultValue: "\(String.localizedName(of: encoding)) can’t be removed.",
                       table: "EncodingList",
                       comment: "%@ is a localized encoding name.")
            case .defaultEncoding:
                String(localized: "EncodingListView.Model.RemovalError.defaultEncoding.description",
                       defaultValue: "The encoding set as default can’t be removed.",
                       table: "EncodingList")
        }
    }
}


private extension CFStringEncoding {
    
    static let utf8 = CFStringEncoding(CFStringBuiltInEncodings.UTF8.rawValue)
}


// MARK: - Preview

#Preview(traits: .fixedLayout(width: 400, height: 400)) {
    EncodingListView()
}
