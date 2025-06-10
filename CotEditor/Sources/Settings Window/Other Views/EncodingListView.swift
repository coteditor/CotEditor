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
import Observation
import Defaults
import FileEncoding

extension UndoManager: @retroactive @unchecked Sendable { }


private struct EncodingItem: Identifiable {
    
    /// Returns every time a new instance with a different id.
    static var separator: Self  { Self(encoding: kCFStringEncodingInvalidId) }
    
    let id = UUID()
    var encoding: CFStringEncoding
    
    var isSeparator: Bool  { self.encoding == kCFStringEncodingInvalidId }
}


struct EncodingListView: View {
    
    @MainActor @Observable fileprivate final class Model {
        
        typealias Item = EncodingItem
        
        
        var items: [Item]
        var selection: Set<Item.ID> = []
        
        private let defaults: UserDefaults
        
        
        init(defaults: UserDefaults = .standard) {
            
            self.items = defaults[.encodingList].map(Item.init(encoding:))
            self.defaults = defaults
        }
    }
    
    
    @State private var model = Model()
    @Environment(\.undoManager) private var undoManager
    @Environment(\.dismiss) private var dismiss
    
    
    var body: some View {
        
        VStack(alignment: .leading) {
            Text("Drag encodings to change the order:", tableName: "EncodingList")
            
            List(selection: $model.selection) {
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
                    self.model.move(from: indexes, to: index, undoManager: self.undoManager)
                }
            }
            .onDeleteCommand {
                self.model.remove(ids: self.model.selection, undoManager: self.undoManager)
            }
            .border(.separator)
            .scrollContentBackground(.hidden)
            .background(.fill.quaternary)
            .environment(\.defaultMinListRowHeight, 14)
            .frame(minHeight: 250, idealHeight: 250)
            
            Text("This order is for the encoding menu and the encoding detection. The detection process only considers the items listed here, with higher items being prioritized.", tableName: "EncodingList")
                .controlSize(.small)
                .fixedSize(horizontal: false, vertical: true)
            
            HStack {
                Button(String(localized: "Button.restoreDefaults.label", defaultValue: "Restore Defaults", table: "Control"), action: self.model.restore)
                    .disabled(!self.model.canRestore)
                    .fixedSize()
                
                Spacer()
                
                ControlGroup {
                    Menu(String(localized: "Button.add.label", defaultValue: "Add", table: "Control"), systemImage: "plus") {
                        let listedEncodings = self.model.items.compactMap(\.encoding)
                        let encodings = String.availableStringEncodings
                            .filter { !listedEncodings.contains($0.cfEncoding) }
                            .sorted(using: KeyPathComparator(\.localizedName, comparator: .localizedStandard))
                        
                        Button(String(localized: "Separator", table: "EncodingList")) {
                            self.model.addSeparator(after: self.model.selection, undoManager: self.undoManager)
                        }
                        
                        Section(String(localized: "Text Encoding", table: "EncodingList")) {
                            ForEach(encodings, id: \.rawValue) { encoding in
                                Button(encoding.localizedName) {
                                    self.model.addEncoding(encoding.cfEncoding, after: self.model.selection, undoManager: self.undoManager)
                                }
                            }
                        }
                    }
                    Button(String(localized: "Button.remove.label", defaultValue: "Remove", table: "Control"), systemImage: "minus") {
                        self.model.remove(ids: self.model.selection, undoManager: self.undoManager)
                    }
                    .disabled(self.model.selection.isEmpty || self.model.canRemove(ids: self.model.selection) != nil)
                    .help(self.model.canRemove(ids: self.model.selection)?.localizedDescription ?? "")
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
        }.frame(height: 13)
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

extension EncodingListView.Model {
    
    enum RemovalError: Error {
        
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
    ///   - undoManager: The undo manager.
    func move(from source: IndexSet, to destination: Int, undoManager: UndoManager? = nil) {
        
        self.registerUndo(to: undoManager)
        
        withAnimation {
            self.items.move(fromOffsets: source, toOffset: destination)
        }
    }
    
    
    /// Returns whether the all items of given ids can be removed.
    ///
    /// - Parameter ids: The item ids to check.
    /// - Returns: `nil` if it can be removed, otherwise `RemovalError`.
    func canRemove(ids: Set<Item.ID>) -> RemovalError? {
        
        self.items.filter(with: ids).lazy.compactMap(self.canRemove).first
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
    ///   - undoManager: The undo manager.
    func addSeparator(after ids: Set<Item.ID>, undoManager: UndoManager? = nil) {
        
        self.registerUndo(to: undoManager)
        
        let index = self.items.lastIndex { ids.contains($0.id) }
        let item: Item = .separator
        
        withAnimation {
            self.items.insert(item, at: index?.advanced(by: 1) ?? 0)
            self.selection = [item.id]
        }
    }
    
    
    /// Adds a text encoding below the last of the given items.
    ///
    /// - Parameters:
    ///   - encoding: The text encoding to add.
    ///   - ids: The selection ids.
    ///   - undoManager: The undo manager.
    func addEncoding(_ encoding: CFStringEncoding, after ids: Set<Item.ID>, undoManager: UndoManager? = nil) {
        
        guard self.items.allSatisfy({ $0.encoding != encoding }) else { return assertionFailure() }
        
        self.registerUndo(to: undoManager)
        
        let index = self.items.lastIndex { ids.contains($0.id) }
        let item = Item(encoding: encoding)
        
        withAnimation {
            self.items.insert(item, at: index?.advanced(by: 1) ?? 0)
            self.selection = [item.id]
        }
    }
    
    
    /// Removes items in the selection.
    ///
    /// - Parameters:
    ///   - ids: The selection ids.
    ///   - undoManager: The undo manager.
    func remove(ids: Set<Item.ID>, undoManager: UndoManager? = nil) {
        
        self.registerUndo(to: undoManager)
        
        withAnimation {
            self.items.removeAll { ids.contains($0.id) && (self.canRemove($0) == nil) }
        }
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
    
    
    /// Registers the current state by allowing undo/redo.
    ///
    /// - Parameter undoManager: The undo manager.
    private func registerUndo(to undoManager: UndoManager?) {
        
        undoManager?.registerUndo(withTarget: self) { [items = self.items] target in
            target.update(items: items, undoManager: undoManager)
        }
    }
    
    
    /// Updates the items and registers the current state to the undo manager.
    ///
    /// - Parameters:
    ///   - items: The new items.
    ///   - undoManager: The undo manager.
    private func update(items: [Item], undoManager: UndoManager?) {
        
        undoManager?.registerUndo(withTarget: self) { [items = self.items] target in
            target.update(items: items, undoManager: undoManager)
        }
        
        withAnimation {
            self.items = items
        }
    }
}


private extension EncodingListView.Model.RemovalError {
    
    var localizedDescription: String {
     
        switch self {
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
