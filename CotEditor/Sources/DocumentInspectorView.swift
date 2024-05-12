//
//  DocumentInspectorView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-05-31.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2024 1024jp
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

final class DocumentInspectorViewController: NSHostingController<DocumentInspectorView>, DocumentOwner {
    
    // MARK: Public Properties
    
    var document: Document {
        
        didSet {
            if self.isViewShown {
                self.model.document = document
            }
        }
    }
    
    
    // MARK: Private Properties
    
    private let model = DocumentInspectorView.Model()
    
    
    
    // MARK: Lifecycle
    
    required init(document: Document) {
        
        self.document = document
        
        super.init(rootView: DocumentInspectorView(model: self.model))
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


struct DocumentInspectorView: View {
    
    @MainActor @Observable final class Model {
        
        var attributes: DocumentFile.Attributes?
        var fileURL: URL?
        var encoding: FileEncoding = .utf8
        var lineEnding: LineEnding = .lf
        var mode: Mode = .kind(.general)
        var countResult: EditorCounter.Result?
        
        var document: Document?  { willSet { self.invalidateObservation(document: newValue) } }
        
        private var observers: Set<AnyCancellable> = []
    }
    
    
    @State var model: Model
    
    
    var body: some View {
        
        ScrollView(.vertical) {
            VStack(spacing: 8) {
                DocumentFileView(attributes: self.model.attributes, fileURL: self.model.fileURL)
                Divider()
                TextSettingsView(encoding: self.model.encoding, lineEnding: self.model.lineEnding, mode: self.model.mode)
                Divider()
                CountLocationView(result: self.model.countResult)
                Divider()
                CharacterPaneView(character: self.model.countResult?.character)
            }
            .padding(EdgeInsets(top: 4, leading: 12, bottom: 12, trailing: 12))
            .disclosureGroupStyle(InspectorDisclosureGroupStyle())
            .labeledContentStyle(InspectorLabeledContentStyle())
        }
        .accessibilityLabel(Text("Document Inspector", tableName: "Document"))
        .controlSize(.small)
    }
}


private struct DocumentFileView: View {
    
    var attributes: DocumentFile.Attributes?
    var fileURL: URL?
    
    @State private var isExpanded = true
    
    
    var body: some View {
        
        DisclosureGroup(String(localized: "Document File", table: "Document", comment: "section title in inspector"), isExpanded: $isExpanded) {
            Form {
                OptionalLabeledContent(String(localized: "Created", table: "Document",
                                              comment: "label in document inspector"),
                                       value: self.attributes?.creationDate?.formatted(date: .abbreviated, time: .shortened))
                OptionalLabeledContent(String(localized: "Modified", table: "Document",
                                              comment: "label in document inspector"),
                                       value: self.attributes?.modificationDate?.formatted(date: .abbreviated, time: .shortened))
                OptionalLabeledContent(String(localized: "Size", table: "Document",
                                              comment: "label in document inspector"),
                                       value: self.attributes?.size.formatted(.byteCount(style: .file, includesActualByteCount: true)))
                OptionalLabeledContent(String(localized: "Permissions", table: "Document",
                                              comment: "label in document inspector"),
                                       value: self.attributes?.permissions.formatted())
                OptionalLabeledContent(String(localized: "Owner", table: "Document",
                                              comment: "label in document inspector"),
                                       value: self.attributes?.owner)
                
                LabeledContent(String(localized: "Full Path", table: "Document", comment: "label in document inspector")) {
                    if let fileURL = self.fileURL {
                        HStack(alignment: .lastTextBaseline, spacing: 0) {
                            Text(fileURL, format: .url)
                                .textSelection(.enabled)
                                .foregroundStyle(.primary)
                            Button(String(localized: "Show in Finder", table: "Document"), systemImage: "arrow.forward") {
                                NSWorkspace.shared.activateFileViewerSelecting([fileURL])
                            }
                            .symbolVariant(.circle)
                            .symbolVariant(.fill)
                            .fontWeight(.bold)
                            .labelStyle(.iconOnly)
                            .controlSize(.mini)
                            .buttonStyle(.borderless)
                        }
                    } else {
                        Text(verbatim: "–")
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}


private struct TextSettingsView: View {
    
    var encoding: FileEncoding
    var lineEnding: LineEnding
    var mode: Mode
    
    @State private var isExpanded = true
    
    
    var body: some View {
        
        DisclosureGroup(String(localized: "Text Settings", table: "Document", comment: "section title in inspector"), isExpanded: $isExpanded) {
            Form {
                LabeledContent(String(localized: "Encoding", table: "Document",
                                      comment: "label in document inspector"),
                               value: self.encoding.localizedName)
                LabeledContent(String(localized: "Line Endings", table: "Document",
                                      comment: "label in document inspector"),
                               value: self.lineEnding.label)
                LabeledContent(String(localized: "Mode", table: "Document",
                                      comment: "label in document inspector"),
                               value: self.mode.label)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}


private struct CountLocationView: View {
    
    var result: EditorCounter.Result?
    
    @State private var isExpanded = true
    
    
    var body: some View {
        
        DisclosureGroup(String(localized: "Count", table: "Document", comment: "section title in inspector"), isExpanded: $isExpanded) {
            Form {
                OptionalLabeledContent(String(localized: "Lines", table: "Document",
                                              comment: "label in document inspector"),
                                       value: self.result?.lines.formatted)
                OptionalLabeledContent(String(localized: "Characters", table: "Document",
                                              comment: "label in document inspector"),
                                       value: self.result?.characters.formatted)
                OptionalLabeledContent(String(localized: "Words", table: "Document",
                                              comment: "label in document inspector"),
                                       value: self.result?.words.formatted)
                .padding(.bottom, 8)
                
                OptionalLabeledContent(String(localized: "Location", table: "Document",
                                              comment: "label in document inspector"),
                                       value: self.result?.location?.formatted())
                OptionalLabeledContent(String(localized: "Line", table: "Document",
                                              comment: "label in document inspector"),
                                       value: self.result?.line?.formatted())
                OptionalLabeledContent(String(localized: "Column", table: "Document",
                                              comment: "label in document inspector"),
                                       value: self.result?.column?.formatted())
            }
            .monospacedDigit()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}


private struct CharacterPaneView: View {
    
    var character: Character?
    
    @State private var isExpanded = true
    
    
    var body: some View {
    
        DisclosureGroup(String(localized: "Character", table: "Document", comment: "section title in inspector"), isExpanded: $isExpanded) {
            Form {
                if let character {
                    LabeledContent(String(localized: "Code Points", table: "Document",
                                          comment: "label in document inspector")) {
                        WrappingHStack {
                            ForEach(Array(character.unicodeScalars.enumerated()), id: \.offset) { (_, scalar) in
                                Text(scalar.codePoint)
                                    .monospacedDigit()
                                    .textSelection(.enabled)
                                    .padding(.horizontal, 2)
                                    .overlay(RoundedRectangle(cornerRadius: 3.5).inset(by: 0.5)
                                        .stroke(.tertiary))
                            }
                        }
                    }
                } else {
                    Text("Not selected", tableName: "Document", comment: "placeholder")
                        .foregroundStyle(.tertiary)
                        .help(String(localized: "Select a single character to show Unicode information.", table: "Document", comment: "tooltip"))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}


private struct OptionalLabeledContent: View {
    
    var title: String
    var value: String?
    
    
    init(_ title: String, value: String?) {
        
        self.title = title
        self.value = value
    }
    
    
    var body: some View {
        
        LabeledContent(self.title) {
            if let value {
                Text(value)
                    .textSelection(.enabled)
                    .foregroundStyle(.primary)
            } else {
                Text(verbatim: "–")
                    .foregroundStyle(.tertiary)
            }
        }
    }
}


private struct InspectorDisclosureGroupStyle: DisclosureGroupStyle {
    
    func makeBody(configuration: Configuration) -> some View {
        
        DisclosureGroup(isExpanded: configuration.$isExpanded) {
            configuration.content
        } label: {
            configuration.label
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.secondary)
                .fixedSize()
        }
    }
}


private struct InspectorLabeledContentStyle: LabeledContentStyle {
    
    func makeBody(configuration: Configuration) -> some View {
        
        LabeledContent {
            configuration.content
        } label: {
            configuration.label
                // keep specific width for short labels, such as Chinese
                .frame(minWidth: 48, alignment: .trailing)
        }.padding(.bottom, 1)
    }
}


private extension DocumentInspectorView.Model {
    
    func invalidateObservation(document: Document?) {
        
        self.document?.counter.updatesAll = false
        self.countResult = document?.counter.result
        
        if let document {
            document.counter.updatesAll = true
            
            self.observers = [
                document.publisher(for: \.fileURL, options: .initial)
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] in self?.fileURL = $0 },
                document.$fileAttributes
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] in self?.attributes = $0 },
                document.$fileEncoding
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] in self?.encoding = $0 },
                document.$lineEnding
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] in self?.lineEnding = $0 },
                document.didChangeSyntax
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] syntax in
                        Task {
                            self?.mode = await ModeManager.shared.mode(for: syntax)
                        }
                    },
            ]
        } else {
            self.observers.removeAll()
        }
    }
}



// MARK: - Preview

#Preview(traits: .fixedLayout(width: 240, height: 520)) {
    let model = DocumentInspectorView.Model()
    model.attributes = .init(
        creationDate: .now,
        modificationDate: .now,
        size: 1024,
        permissions: FilePermissions(mask: 0o644),
        owner: "clarus"
    )
    model.fileURL = URL(filePath: "/Users/clarus/Desktop/My Script.py")
    model.encoding = .init(encoding: .utf8, withUTF8BOM: true)
    
    let result = EditorCounter.Result()
    result.characters = .init(entire: 1024, selected: 4)
    result.lines = .init(entire: 10, selected: 1)
    result.character = "🐈‍⬛"
    
    model.countResult = result
    
    return DocumentInspectorView(model: model)
}

#Preview("Empty", traits: .fixedLayout(width: 240, height: 520)) {
    DocumentInspectorView(model: .init())
}
