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
import Observation
import Combine
import ControlUI
import Defaults
import FileEncoding
import LineEnding

final class StatusBarController: NSHostingController<StatusBar> {
    
    let model: StatusBar.Model
    
    
    required init(model: StatusBar.Model) {
        
        self.model = model
        
        super.init(rootView: StatusBar(model: self.model))
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        self.model.onAppear()
    }
    
    
    override func viewDidDisappear() {
        
        super.viewDidDisappear()
        
        self.model.onDisappear()
    }
}


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
            .sink { [weak self] in self?.document?.counter.statusBarRequirements = $0 }
    }
    
    
    /// Called after the view  is removed from the view hierarchy in a window.
    func onDisappear() {
        
        self.isActive = false
        
        self.defaultsObserver = nil
        self.documentObservers.removeAll()
        self.document?.counter.statusBarRequirements = []
    }
    
    
    /// Updates observations.
    private func invalidateObservation(document: Document?) {
        
        self.document?.counter.statusBarRequirements = []
        self.isEditable = document?.isEditable != false
        self.countResult = document?.counter.result
        self.fileEncoding = document?.fileEncoding
        
        if let document, self.isActive {
            document.counter.statusBarRequirements = UserDefaults.standard.statusBarEditorInfo
            
            self.documentObservers = [
                document.$isEditable
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] in self?.isEditable = $0 },
                document.didChangeFileEncoding
                    .sink { [weak self] in self?.fileEncoding = $0 },
                document.$lineEnding
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] in self?.lineEnding = $0 },
            ]
        } else {
            self.documentObservers.removeAll()
            self.lineEnding = nil
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


// MARK: -

struct StatusBar: View {
    
    @MainActor @Observable final class Model {
        
        private(set) var document: Document?
        
        var isEditable: Bool = true
        var countResult: EditorCounter.Result?
        
        var fileEncoding: FileEncoding?
        var lineEnding: LineEnding?
        
        private var isActive: Bool = false
        private var defaultsObserver: AnyCancellable?
        private var documentObservers: Set<AnyCancellable> = []
        
        
        init(document: Document? = nil) {
            
            self.document = document
        }
        
        
        /// Updates the represented document.
        ///
        /// - Parameter document: The new document, or `nil`.
        func updateDocument(to document: Document?) {
            
            self.invalidateObservation(document: document)
            self.document = document
        }
    }
    
    
    @State var model: Model
    
    @AppStorage(.donationBadgeType) private var badgeType
    
    @State private var encodingManager: EncodingManager = .shared
    @State private var hasDonated: Bool = false
    
    
    var body: some View {
        
        HStack {
            if self.hasDonated, self.badgeType != .invisible {
                CoffeeBadge(type: self.badgeType)
                    .transition(.symbolEffect)
            }
            if self.model.isEditable == false {
                Label(String(localized: "Not editable", table: "Document"), systemImage: "pencil")
                    .symbolVariant(.slash)
                    .labelStyle(.iconOnly)
                    .help(String(localized: "The document is not editable.", table: "Document", comment: "tooltip"))
            }
            if let result = self.model.countResult {
                EditorCountView(result: result)
            }
            
            Spacer()
            
            if let document = self.model.document {
                if let fileSize = document.fileAttributes?.size {
                    Text(fileSize, format: .byteCount(style: .file, spellsOutZero: false))
                        .monospacedDigit()
                        .help(String(localized: "File size", table: "Document", comment: "tooltip"))
                } else {
                    NoneTextView()
                }
            }
            
            HStack(spacing: 2) {
                if let fileEncoding = self.model.fileEncoding {
                    Divider()
                        .padding(.vertical, 4)
                    
                    Picker(selection: $model.fileEncoding ?? .utf8) {
                        if !self.encodingManager.fileEncodings.contains(fileEncoding) {
                            Text(fileEncoding.localizedName).tag(fileEncoding)
                        }
                        Section(String(localized: "Text Encoding", table: "Document", comment: "menu item header")) {
                            ForEach(Array(self.encodingManager.fileEncodings.enumerated()), id: \.offset) { (_, fileEncoding) in
                                if let fileEncoding {
                                    Text(fileEncoding.localizedName).tag(fileEncoding)
                                } else {
                                    Divider()
                                }
                            }
                        }
                    } label: {
                        EmptyView()
                    }
                    .onChange(of: fileEncoding) { (_, newValue) in
                        self.model.document?.askChangingEncoding(to: newValue)
                    }
                    .help(String(localized: "Text Encoding", table: "Document"))
                    .accessibilityLabel(String(localized: "Text Encoding", table: "Document"))
                }
                
                if let lineEnding = self.model.lineEnding {
                    Divider()
                        .padding(.vertical, 4)
                    
                    LineEndingPicker(String(localized: "Line Endings", table: "Document", comment: "menu item header"),
                                     selection: $model.lineEnding ?? .lf)
                    .disabled(self.model.isEditable != true)
                    .onChange(of: lineEnding) { (_, newValue) in
                        self.model.document?.changeLineEnding(to: newValue)
                    }
                    .help(String(localized: "Line Endings", table: "Document"))
                    .accessibilityLabel(String(localized: "Line Endings", table: "Document", comment: "menu item header"))
                    .frame(width: 48)
                }
            }
        }
        .subscriptionStatusTask(for: Donation.groupID) { taskState in
            self.hasDonated = taskState.value?.map(\.state).contains(.subscribed) == true
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(String(localized: "Status Bar", table: "Document", comment: "accessibility label"))
        .animation(.default.speed(1.5), value: self.model.isEditable)
        .buttonStyle(.borderless)
        .controlSize(.small)
        .padding(.leading, 10)
        .frame(height: 23)
        .background(.windowBackground)
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
        
        Text(self.attributedString)
            .monospacedDigit()
            .accessibilityAddTraits(.updatesFrequently)
    }
    
    
    private var attributedString: AttributedString {
        
        var strings: [AttributedString] = []
        
        if self.showsLines {
            strings.append(.init(String(localized: "Lines: ", table: "Document", comment: "label in status bar"),
                                 value: self.result.lines.formatted))
        }
        if self.showsCharacters {
            strings.append(.init(String(localized: "Characters: ", table: "Document", comment: "label in status bar"),
                                 value: self.result.characters.formatted))
        }
        if self.showsWords {
            strings.append(.init(String(localized: "Words: ", table: "Document", comment: "label in status bar"),
                                 value: self.result.words.formatted))
        }
        if self.showsLocation {
            strings.append(.init(String(localized: "Location: ", table: "Document", comment: "label in status bar"),
                                 value: self.result.location?.formatted()))
        }
        if self.showsLine {
            strings.append(.init(String(localized: "Line: ", table: "Document", comment: "label in status bar"),
                                 value: self.result.line?.formatted()))
        }
        if self.showsColumn {
            strings.append(.init(String(localized: "Column: ", table: "Document", comment: "label in status bar"),
                                 value: self.result.column?.formatted()))
        }
        
        return strings.reduce(into: AttributedString()) { (string, item) in
            if !string.runs.isEmpty {
                string.append(AttributedString("  "))
            }
            string.append(item)
        }
    }
}


private extension AttributedString {
    
    /// Returns formatted label for status bar.
    ///
    /// - Parameters:
    ///   - label: Localized label.
    ///   - state: The content string.
    /// - Returns: An attributed string.
    init(_ label: String, value: String?) {
        
        self = Self(label, attributes: AttributeContainer.foregroundColor(.secondary))
        + Self(value ?? "–", attributes: AttributeContainer.foregroundColor((value == nil) ? .tertiaryLabelColor : .labelColor))
    }
}


private struct LineEndingPicker: NSViewRepresentable {
    
    typealias NSViewType = NSPopUpButton
    
    var label: String
    @Binding var selection: LineEnding
    
    
    init(_ label: String, selection: Binding<LineEnding>) {
        
        self.label = label
        self._selection = selection
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
        
        Coordinator(selection: $selection)
    }
    
    
    final class Coordinator: NSObject {
        
        @Binding private var selection: LineEnding
        
        
        init(selection: Binding<LineEnding>) {
            
            self._selection = selection
        }
        
        
        @objc func didSelectItem(_ sender: NSMenuItem) {
            
            self.selection = sender.representedObject as! LineEnding
        }
    }
}


private struct CoffeeBadge: View {
    
    var type: BadgeType
    
    @State private var isMessagePresented = false
    
    
    var body: some View {
        
        Button {
            self.isMessagePresented.toggle()
        } label: {
            Label {
                Text(self.type.label)
            } icon: {
                Image(systemName: self.type.symbolName)
            }
        }
        .fontWeight(.semibold)
        .labelStyle(.iconOnly)
        .popover(isPresented: $isMessagePresented) {
            Text("Thank you for your kind support!", tableName: "Document", comment: "message for users who made a donation")
                .padding(.vertical, 8)
                .padding(.horizontal)
        }
    }
}


// MARK: - Preview

#Preview {
    let model = StatusBar.Model()
    let result = EditorCounter.Result()
    result.characters = .init(entire: 1024, selected: 64)
    model.countResult = result
    
    return StatusBar(model: StatusBar.Model())
}
