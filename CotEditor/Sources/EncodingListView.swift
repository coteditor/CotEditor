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
//  © 2022-2023 1024jp
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

private struct EncodingItem: Identifiable {
    
    /// Return every time  a new instance with a different id.
    static var separator: Self  { Self(encoding: kCFStringEncodingInvalidId) }
    
    let id = UUID()
    var encoding: CFStringEncoding
    
    var isSeparator: Bool  { self.encoding == kCFStringEncodingInvalidId }
}


struct EncodingListView: View {
    
    private struct SeparatorButtonKey: MaxWidthKey { }
    
    
    weak var parent: NSHostingController<Self>?  // workaround presentationMode.dismiss() doesn't work
    
    @State private var encodingItems: [EncodingItem] = UserDefaults.standard[.encodingList].map(EncodingItem.init(encoding:))
    @State private var selectedItems: Set<EncodingItem.ID> = []
    
    @State private var separatorButtonWidth: CGFloat?
    
    
    var body: some View {
        
        VStack(alignment: .leading) {
            Text("Drag encodings to change the order:")
            
            HStack(alignment: .top) {
                List(selection: $selectedItems) {
                    ForEach(self.encodingItems) { item in
                        VStack(alignment: .leading, spacing: 8) {
                            if item.isSeparator {
                                Divider()
                            } else if item.encoding == .utf8 {
                                EncodingView(encoding: item.encoding)
                                EncodingView(encoding: item.encoding, withUTF8BOM: true)
                            } else {
                                EncodingView(encoding: item.encoding)
                            }
                        }
                    }.onMove { (indexes, index) in
                        withAnimation {
                            self.encodingItems.move(fromOffsets: indexes, toOffset: index)
                        }
                    }
                }
                .listStyle(.bordered)
                .environment(\.defaultMinListRowHeight, 14)
                .frame(minHeight: 250, idealHeight: 250)
                
                VStack(alignment: .leading) {
                    Button(action: self.addSeparator) {
                        Text("Add Separator")
                            .background(WidthGetter(key: SeparatorButtonKey.self))
                            .frame(width: self.separatorButtonWidth)
                    }
                    Button(action: self.deleteSeparators) {
                        Text("Delete Separator")
                            .background(WidthGetter(key: SeparatorButtonKey.self))
                            .frame(width: self.separatorButtonWidth)
                    }.disabled(!self.canDeleteSeparators)
                }.controlSize(.small)
                    .onPreferenceChange(SeparatorButtonKey.self) { self.separatorButtonWidth = $0 }
            }
            
            Text("This order is for the encoding menu and the encoding detection on file opening. By the detection, the higher items are more prioritized.")
                .controlSize(.small)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom)
            
            HStack {
                HelpButton(anchor: "howto_customize_encoding_order")
                
                Button("Restore Defaults", action: self.restore)
                    .disabled(!self.canRestore)
                
                Spacer()
                
                SubmitButtonGroup {
                    self.save()
                    self.parent?.dismiss(nil)
                } cancelAction: {
                    self.parent?.dismiss(nil)
                }
            }
        }
        .padding()
        .frame(minWidth: 420)
    }
    
    
    
    // MARK: Private Methods
    
    /// Whether the current order differs from the default.
    private var canRestore: Bool {
        
        self.encodingItems.map(\.encoding) != UserDefaults.standard.registeredValue(for: .encodingList)
    }
    
    
    /// Whether the selection contains separators.
    private var canDeleteSeparators: Bool {
        
        self.encodingItems.filter(\.isSeparator).map(\.id).contains(where: self.selectedItems.contains)  // macOS 13 contains(collection)
    }
    
    
    /// Restore encodings setting list in the view to the default.
    private func restore() {
        
        self.encodingItems = UserDefaults.standard.registeredValue(for: .encodingList).map(EncodingItem.init)
    }
    
    
    /// Save the current encodings to the user default.
    private func save() {
        
        UserDefaults.standard[.encodingList] = self.encodingItems.map(\.encoding)
    }
    
    
    /// Add a separator below the last selection.
    private func addSeparator() {
        
        let index = self.encodingItems.lastIndex { self.selectedItems.contains($0.id) }
        
        withAnimation {
            self.encodingItems.insert(.separator, at: index?.advanced(by: 1) ?? 0)
        }
    }
    
    
    /// Delete separators in the selection.
    private func deleteSeparators() {
        
        withAnimation {
            self.encodingItems.removeAll { $0.isSeparator && self.selectedItems.contains($0.id) }
        }
    }
}


private struct EncodingView: View {
    
    var encoding: CFStringEncoding
    var withUTF8BOM = false
    
    
    var body: some View {
        
        HStack(alignment: .firstTextBaseline) {
            Text(self.name)
            Text(verbatim: self.ianaCharsetName)
                .foregroundColor(.secondary)  // prefer .secondary over .secondaryLabel to change color when selected
        }.frame(height: 12)
    }
    
    
    private var name: String {
        
        FileEncoding(encoding: String.Encoding(cfEncoding: self.encoding),
                     withUTF8BOM: self.withUTF8BOM).localizedName
    }
    
    
    private var ianaCharsetName: String {
        
        CFStringConvertEncodingToIANACharSetName(self.encoding) as String? ?? "–"
    }
}


private extension CFStringEncoding {
    
    static let utf8 = CFStringEncoding(CFStringBuiltInEncodings.UTF8.rawValue)
}



// MARK: - Preview

struct EncodingListView_Previews: PreviewProvider {
    
    static var previews: some View {
        
        EncodingListView()
    }
}
