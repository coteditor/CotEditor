//
//  StatusBar.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2014-07-11.
//
//  ---------------------------------------------------------------------------
//
//  © 2014-2025 1024jp
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
import StoreKit
import Combine
import ControlUI
import Defaults
import FileEncoding
import LineEnding

struct StatusBar: View {
    
    @MainActor @Observable final class Model {
        
        var document: DataDocument?  { willSet { self.invalidateObservation(document: newValue) } }
        
        private var isActive: Bool = false
        private var defaultsObserver: AnyCancellable?
        
        
        init(document: DataDocument? = nil) {
            
            self.document = document
        }
    }
    
    
    @State var model: Model
    
    @AppStorage(.showStatusBar) private var showsStatusBar
    @AppStorage(.donationBadgeType) private var badgeType
    
    @State private var hasDonated: Bool = false
    
    
    var body: some View {
        
        HStack {
            if self.hasDonated, self.badgeType != .invisible {
                CoffeeBadge(type: self.badgeType)
            }
            
            if let document = self.model.document as? Document {
                NotEditableBadge(document: document)
                EditorCountView(result: document.counter.result)
                    .layoutPriority(-1)
            }
            
            Spacer()
            
            if let document = self.model.document {
                FileSizeView(size: document.fileAttributes?.size)
            }
            
            if let document = self.model.document as? Document {
                DocumentStatusBar(document: document)
            }
        }
        .onAppear {
            self.model.onAppear()
        }
        .onDisappear {
            self.model.onDisappear()
        }
        .onChange(of: self.showsStatusBar) { _, newValue in
            if newValue {
                self.model.onAppear()
            } else {
                self.model.onDisappear()
            }
        }
        .subscriptionStatusTask(for: Donation.groupID) { taskState in
            self.hasDonated = taskState.value?.map(\.state).contains(.subscribed) == true
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(String(localized: "Status Bar", table: "Document", comment: "accessibility label"))
        .buttonStyle(.borderless)
        .controlSize(.small)
        .lineLimit(1)
        .padding(.leading)
        .modifier { content in
            if #available(macOS 26, *) {
                content
                    .frame(height: 16)
                    .padding(.vertical, 8)
                    .containerCornerOffset(.horizontal, sizeToFit: true)
            } else {
                content
                    .frame(height: 23)
            }
        }
        .background(.windowBackground)
    }
}


// MARK: Private APIs

private extension StatusBar.Model {
    
    /// Called when the view is fully transitioned onto the screen.
    func onAppear() {
        
        self.isActive = true
        
        self.invalidateObservation(document: self.document)
        
        // observe changes in defaults
        let editorDefaultKeys: [DefaultKey<Bool>] = [
            .showStatusBarLines,
            .showStatusBarChars,
            .showStatusBarWords,
            .showStatusBarLocation,
            .showStatusBarLine,
            .showStatusBarColumn,
        ]
        let publishers = editorDefaultKeys.map { UserDefaults.standard.publisher(for: $0) }
        self.defaultsObserver = Publishers.MergeMany(publishers)
            .map { _ in UserDefaults.standard.statusBarEditorInfo }
            .sink { [weak self] in (self?.document as? Document)?.counter.statusBarRequirements = $0 }
    }
    
    
    /// Called after the view is removed from the view hierarchy in a window.
    func onDisappear() {
        
        self.isActive = false
        
        self.defaultsObserver = nil
        (self.document as? Document)?.counter.statusBarRequirements = []
    }
    
    
    /// Updates observations.
    private func invalidateObservation(document: DataDocument?) {
        
        (self.document as? Document)?.counter.statusBarRequirements = []
        
        if let document = document as? Document, self.isActive {
            document.counter.statusBarRequirements = UserDefaults.standard.statusBarEditorInfo
        }
    }
}


private struct CoffeeBadge: View {
    
    var type: BadgeType
    
    @State private var isMessagePresented = false
    
    
    var body: some View {
        
        Toggle(self.type.label, systemImage: self.type.symbolName, isOn: $isMessagePresented)
            .toggleStyle(.button)
            .fontWeight(.semibold)
            .labelStyle(.iconOnly)
            .fixedSize()
            .padding(.trailing, 8)
            .popover(isPresented: $isMessagePresented) {
                Text("Thank you for your kind support!", tableName: "Document", comment: "message for users who made a donation")
                    .padding(.vertical, 8)
                    .padding(.horizontal)
            }
    }
}


private struct NotEditableBadge: View {
    
    var document: Document
    
    @State private var isEditable: Bool = true
    
    
    var body: some View {
        
        HStack {
            if self.isEditable == false {
                Label(String(localized: "Not editable", table: "Document"), systemImage: "pencil.slash")
                    .help(String(localized: "The document is not editable.", table: "Document", comment: "tooltip"))
                    .labelStyle(.iconOnly)
            }
        }
        .onReceive(self.document.$isEditable) { self.isEditable = $0 }
        .animation(.default.speed(1.5), value: self.isEditable)
    }
}


private struct FileSizeView: View {
    
    var size: Int64?
    
    
    var body: some View {
        
        LabeledContent(String(localized: "File size", table: "Document"),
                       optional: self.size?.formatted(.byteCount(style: .file, spellsOutZero: false)))
        .monospacedDigit()
        .labelsHidden()
        .help(String(localized: "File size", table: "Document", comment: "tooltip"))
        .fixedSize()
    }
}


private struct DocumentStatusBar: View {
    
    private var document: Document
    
    @State private var isEditable: Bool
    @State private var lineEnding: LineEnding
    @State private var fileEncoding: FileEncoding
    @State private var encodingManager: EncodingManager = .shared
    
    
    init(document: Document) {
        
        self.document = document
        self.isEditable = document.isEditable
        self.lineEnding = document.lineEnding
        self.fileEncoding = document.fileEncoding
    }
    
    
    var body: some View {
        
        HStack(spacing: 4) {
            Divider()
                .padding(.vertical, isLiquidGlass ? 0 : 4)
            
            Picker(String(localized: "Text Encoding", table: "Document"), selection: $fileEncoding) {
                Section(String(localized: "Text Encoding", table: "Document")) {
                    if !self.encodingManager.fileEncodings.contains(self.fileEncoding) {
                        Text(self.fileEncoding.localizedName).tag(self.fileEncoding)
                        Divider()
                    }
                    ForEach(Array(self.encodingManager.fileEncodings.enumerated()), id: \.offset) { _, fileEncoding in
                        if let fileEncoding {
                            Text(fileEncoding.localizedName).tag(fileEncoding)
                        } else {
                            Divider()
                        }
                    }
                }
            }
            .onChange(of: self.fileEncoding) { _, newValue in
                self.document.askChangingEncoding(to: newValue)
            }
            .help(String(localized: "Text Encoding", table: "Document"))
            .labelsHidden()
            
            Divider()
                .padding(.vertical, isLiquidGlass ? 0 : 4)
            
            LineEndingPicker(String(localized: "Line Endings", table: "Document"), selection: $lineEnding) { lineEnding in
                self.document.changeLineEnding(to: lineEnding)
            }
            .disabled(!self.isEditable)
            .help(String(localized: "Line Endings", table: "Document"))
            .accessibilityLabel(String(localized: "Line Endings", table: "Document"))
            .frame(width: 48)
        }
        .onReceive(self.document.$isEditable) { self.isEditable = $0 }
        .onReceive(self.document.$lineEnding) { self.lineEnding = $0 }
        .onReceive(self.document.$fileEncoding) { self.fileEncoding = $0 }
    }
}


private struct EditorCountView: View {
    
    var result: EditorCounter.Result
    
    @AppStorage(.showStatusBarLines) private var showsLines
    @AppStorage(.showStatusBarChars) private var showsCharacters
    @AppStorage(.showStatusBarWords) private var showsWords
    @AppStorage(.showStatusBarLocation) private var showsLocation
    @AppStorage(.showStatusBarLine) private var showsLine
    @AppStorage(.showStatusBarColumn) private var showsColumn
    
    
    var body: some View {
        
        TruncatingHStack {
            if self.showsLines {
                Text(String(localized: "CountType.lines.label", defaultValue: "Lines", table: "Document"),
                     value: self.result.lines.formatted)
            }
            if self.showsCharacters {
                Text(String(localized: "CountType.characters.label", defaultValue: "Characters", table: "Document"),
                     value: self.result.characters.formatted)
            }
            if self.showsWords {
                Text(String(localized: "CountType.words.label", defaultValue: "Words", table: "Document"),
                     value: self.result.words.formatted)
            }
            if self.showsLocation {
                Text(String(localized: "CountType.location.label", defaultValue: "Location", table: "Document"),
                     value: self.result.location?.formatted())
            }
            if self.showsLine {
                Text(String(localized: "CountType.line.label", defaultValue: "Line", table: "Document"),
                     value: self.result.line?.formatted())
            }
            if self.showsColumn {
                Text(String(localized: "CountType.column.label", defaultValue: "Column", table: "Document"),
                     value: self.result.column?.formatted())
            }
        }
        .foregroundStyle(.secondary)
        .monospacedDigit()
        .accessibilityAddTraits(.updatesFrequently)
    }
}


private extension Text {
    
    /// Instantiates the labeled value for status bar.
    ///
    /// - Parameters:
    ///   - label: Localized label.
    ///   - state: The content string.
    init(_ label: String, value: String?) {
        
        let valueText = if let value {
            Text(value).foregroundStyle(.primary)
        } else {
            Text.none
        }
        
        self = Text("\(label): \(valueText)")
    }
}


private struct LineEndingPicker: NSViewRepresentable {
    
    typealias NSViewType = NSPopUpButton
    
    var label: String
    @Binding var selection: LineEnding
    var onSelect: (LineEnding) -> Void
    
    
    init(_ label: String, selection: Binding<LineEnding>, onSelect: @escaping (LineEnding) -> Void) {
        
        self.label = label
        self._selection = selection
        self.onSelect = onSelect
    }
    
    
    func makeNSView(context: Context) -> NSPopUpButton {
        
        let menu = OptionalMenu(title: self.label)
        menu.autoenablesItems = false
        menu.items = [.sectionHeader(title: self.label)]
        menu.items += LineEnding.allCases.map { lineEnding in
            let item = NSMenuItem()
            item.title = lineEnding.label
            item.toolTip = lineEnding.description
            item.action = #selector(Coordinator.didSelectItem)
            item.target = context.coordinator
            item.representedObject = lineEnding
            item.isHidden = !lineEnding.isBasic
            item.keyEquivalentModifierMask = lineEnding.isBasic ? [] : [.option]
            
            return item
        }
        
        let popUpButton = NSPopUpButton()
        popUpButton.menu = menu
        popUpButton.isBordered = false
        popUpButton.controlSize = .small
        popUpButton.font = .menuFont(ofSize: NSFont.smallSystemFontSize)
        
        return popUpButton
    }
    
    
    func updateNSView(_ nsView: NSPopUpButton, context: Context) {
        
        let index = nsView.indexOfItem(withRepresentedObject: self.selection)
        nsView.selectItem(at: index)
    }
    
    
    func makeCoordinator() -> Coordinator {
        
        Coordinator(selection: $selection, onSelect: self.onSelect)
    }
    
    
    final class Coordinator: NSObject {
        
        @Binding private var selection: LineEnding
        private var onSelect: (LineEnding) -> Void
        
        
        init(selection: Binding<LineEnding>, onSelect: @escaping (LineEnding) -> Void) {
            
            self._selection = selection
            self.onSelect = onSelect
        }
        
        
        @objc func didSelectItem(_ sender: NSMenuItem) {
            
            self.selection = sender.representedObject as! LineEnding
            self.onSelect(self.selection)
        }
    }
}


private extension UserDefaults {
    
    /// The info types needed to be calculated.
    var statusBarEditorInfo: EditorCounter.Types {
        
        EditorCounter.Types()
            .union(self[.showStatusBarChars] ? .characters : [])
            .union(self[.showStatusBarLines] ? .lines : [])
            .union(self[.showStatusBarWords] ? .words : [])
            .union(self[.showStatusBarLocation] ? .location : [])
            .union(self[.showStatusBarLine] ? .line : [])
            .union(self[.showStatusBarColumn] ? .column : [])
    }
}


// MARK: - Preview

#Preview {
    let document = Document()
    document.isEditable = false
    document.counter.result.lines = .init(entire: 1024, selected: 64)
    
    return StatusBar(model: StatusBar.Model(document: document))
}
