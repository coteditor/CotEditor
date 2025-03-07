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
    
     @Observable fileprivate final class Model {
        
        typealias Item = EncodingItem
        
        
        var items: [Item]
        
        private let defaults: UserDefaults
        
        
        init(defaults: UserDefaults = .standard) {
            
            self.items = defaults[.encodingList].map(Item.init(encoding:))
            self.defaults = defaults
        }
    }
    
    
    @State private var model = Model()
    @Environment(\.undoManager) private var undoManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selection: Set<EncodingItem.ID> = []
    
    
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
                    self.model.move(from: indexes, to: index, undoManager: self.undoManager)
                }
            }
            .onDeleteCommand {
                self.model.deleteSeparators(in: self.selection, undoManager: self.undoManager)
            }
            .border(.separator)
            .scrollContentBackground(.hidden)
            .background(.fill.quaternary)
            .environment(\.defaultMinListRowHeight, 14)
            .frame(minHeight: 250, idealHeight: 250)
                
            HStack {
                Spacer()
                Button(String(localized: "Add Separator", table: "EncodingList", comment: "button label")) {
                    self.model.addSeparator(after: self.selection, undoManager: self.undoManager)
                }
                Button(String(localized: "Delete Separator", table: "EncodingList", comment: "button label")) {
                    self.model.deleteSeparators(in: self.selection, undoManager: self.undoManager)
                }
                .disabled(!self.model.containSeparators(in: self.selection))
            }.controlSize(.small)
            
            Text("This order is for the encoding menu and the encoding detection on file opening. By the detection, the higher items are more prioritized.", tableName: "EncodingList")
                .controlSize(.small)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom)
            
            HStack {
                HelpLink(anchor: "howto_customize_encoding_order")
                
                Button(String(localized: "Restore Defaults", table: "EncodingList", comment: "button label")) {
                    self.model.restore()
                }
                .disabled(!self.model.canRestore)
                .fixedSize()
                
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


// MARK: -

extension EncodingListView.Model {
    
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
    
    
    /// Returns whether the items of given ids contain separators.
    ///
    /// - Parameter ids: The item ids to check.
    /// - Returns: A `Bool` value.
    func containSeparators(in ids: Set<Item.ID>) -> Bool {
        
        self.items
            .filter(with: ids)
            .contains(where: \.isSeparator)
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
        
        withAnimation {
            self.items.insert(.separator, at: index?.advanced(by: 1) ?? 0)
        }
    }
    
    
    /// Deletes separators in the selection.
    ///
    /// - Parameters:
    ///   - ids: The selection ids.
    ///   - undoManager: The undo manager.
    func deleteSeparators(in ids: Set<Item.ID>, undoManager: UndoManager? = nil) {
        
        self.registerUndo(to: undoManager)
        
        withAnimation {
            self.items.removeAll { $0.isSeparator && ids.contains($0.id) }
        }
    }
    
    
    // MARK: Private Methods
    
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


private extension CFStringEncoding {
    
    static let utf8 = CFStringEncoding(CFStringBuiltInEncodings.UTF8.rawValue)
}


// MARK: - Preview

#Preview(traits: .fixedLayout(width: 400, height: 400)) {
    EncodingListView()
}
