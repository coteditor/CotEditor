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
//  © 2014-2024 1024jp
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

final class StatusBarController: NSHostingController<StatusBar> {
    
    let model: StatusBar.Model
    
    
    required init(model: StatusBar.Model) {
        
        self.model = model
        
        super.init(rootView: StatusBar(model: self.model))
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidAppear() {
        
        super.viewDidAppear()
        
        self.model.onAppear()
    }
    
    
    override func viewDidDisappear() {
        
        super.viewDidDisappear()
        
        self.model.onDisappear()
    }
}


private extension StatusBar.Model {
    
    @MainActor func onAppear() {
        
        self.observeDocument()
        
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
            .sink { [weak self] in self?.document?.analyzer.statusBarRequirements = $0 }
    }
    
    
    @MainActor func onDisappear() {
        
        self.defaultsObserver = nil
        self.documentObservers.removeAll()
        self.document?.analyzer.statusBarRequirements = []
    }
    
    
    @MainActor private func observeDocument() {
        
        guard let document else {
            self.documentObservers.removeAll()
            return
        }
        
        document.analyzer.statusBarRequirements = UserDefaults.standard.statusBarEditorInfo
        
        self.documentObservers = [
            document.analyzer.$result
                .removeDuplicates()
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in self?.countResult = $0 },
            document.$fileAttributes
                .map { $0?.size }
                .removeDuplicates()
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in self?.fileSize = $0 },
            document.$fileEncoding
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in self?.fileEncoding = $0 },
            document.$lineEnding
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in self?.lineEnding = $0 },
        ]
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
    
    final class Model: ObservableObject {
        
        @MainActor var document: Document?  { didSet { Task { @MainActor in self.observeDocument() } } }
        
        @Published var fileEncoding: FileEncoding = .utf8
        @Published var lineEnding: LineEnding = .lf
        
        @Published fileprivate(set) var countResult: EditorCounter.Result = .init()
        @Published fileprivate(set) var fileSize: Int64?
        
        private var defaultsObserver: AnyCancellable?
        private var documentObservers: Set<AnyCancellable> = []
        
        
        init(document: Document? = nil) {
            
            self.document = document
        }
    }
    
    
    @ObservedObject var model: Model
    
    @State private(set) var fileEncodings: [FileEncoding?] = []
    
    @State private var isAcknowledgementPresented = false
    
    
    var body: some View {
        
        HStack {
            EditorCountView(result: self.model.countResult)
            
            Spacer()
            
            if let fileSize = self.model.fileSize {
                Text(fileSize, format: .byteCount(style: .file, spellsOutZero: false))
                    .monospacedDigit()
                    .help(String(localized: "File size", table: "Document", comment: "tooltip"))
            } else {
                Text(verbatim: "–")
                    .foregroundStyle(.tertiary)
            }
            
            HStack(spacing: 2) {
                Divider()
                    .padding(.vertical, 4)
                
                Picker(selection: $model.fileEncoding) {
                    if !self.fileEncodings.contains(self.model.fileEncoding) {
                        Text(self.model.fileEncoding.localizedName).tag(self.model.fileEncoding)
                    }
                    Section(String(localized: "Text Encoding", table: "Document", comment: "menu item header")) {
                        ForEach(Array(self.fileEncodings.enumerated()), id: \.offset) { (_, fileEncoding) in
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
                .onChange(of: self.model.fileEncoding) { newValue in
                    self.model.document?.askChangingEncoding(to: newValue)
                }
                .help(String(localized: "Text Encoding", table: "Document"))
                
                Divider()
                    .padding(.vertical, 4)
                
                LineEndingPicker(String(localized: "Line Endings", table: "Document", comment: "menu item header"),
                                 selection: $model.lineEnding)
                .onChange(of: self.model.lineEnding) { newValue in
                    self.model.document?.changeLineEnding(to: newValue)
                }
                .help(String(localized: "Line Endings", table: "Document"))
                .frame(width: 48)
            }
        }
        .onReceive(EncodingManager.shared.$fileEncodings.receive(on: RunLoop.main)) { encodings in
            self.fileEncodings = encodings
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(String(localized: "Status Bar", table: "Document", comment: "accessibility label"))
        .buttonStyle(.borderless)
        .controlSize(.small)
        .padding(.leading, 10)
        .frame(height: 21)
        .background(.thinMaterial)  // .windowBackground on macOS 14
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
        
        self = Self(label, attributes: .init().foregroundColor(.secondary))
        + Self(value ?? "–", attributes: .init()
            .foregroundColor((value == nil) ? NSColor.disabledControlTextColor : .labelColor))
    }
}


private struct LineEndingPicker: NSViewRepresentable {
    
    typealias NSViewType = NSPopUpButton
    
    let label: String
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



// MARK: - Preview

#Preview {
    let model = StatusBar.Model()
    model.countResult.characters = .init(entire: 1024, selected: 64)
    
    return StatusBar(model: model)
}
