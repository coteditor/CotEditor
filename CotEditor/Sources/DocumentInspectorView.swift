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
import Combine

final class DocumentInspectorViewController: NSHostingController<DocumentInspectorView>, DocumentOwner {
    
    // MARK: Public Properties
    
    var document: Document {
        
        get { self.model.document }
        set { self.model.document = newValue }
    }
    
    
    // MARK: Private Properties
    
    private let model: DocumentInspectorView.Model
    
    
    
    // MARK: Lifecycle
    
    required init(document: Document) {
        
        self.model = .init(document: document)
        
        super.init(rootView: DocumentInspectorView(model: self.model))
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


struct DocumentInspectorView: View {
    
    @MainActor final class Model: ObservableObject {
        
        var document: Document  { didSet { self.invalidateObservation() } }
        var isAppeared = false  { didSet { self.invalidateObservation() } }
        
        @Published var attributes: DocumentFile.Attributes?
        @Published var fileURL: URL?
        @Published var encoding: FileEncoding = FileEncoding(encoding: .utf8)
        @Published var lineEnding: LineEnding = .lf
        @Published var countResult: EditorCountResult = .init()
        
        private var observers: Set<AnyCancellable> = []
        
        
        init(document: Document) {
            
            self.document = document
        }
    }
    
    
    @ObservedObject var model: Model
    
    
    var body: some View {
        
        ScrollView(.vertical) {
            VStack(spacing: 8) {
                DocumentFileView(attributes: self.model.attributes, fileURL: self.model.fileURL)
                Divider()
                TextSettingsView(encoding: self.model.encoding, lineEnding: self.model.lineEnding)
                Divider()
                CountLocationView(result: self.model.countResult)
                Divider()
                CharacterPaneView(character: self.model.countResult.character)
            }
            .padding(.top, 4)
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
            .disclosureGroupStyle(InspectorDisclosureGroupStyle())
            .labeledContentStyle(InspectorLabeledContentStyle())
        }
        .onAppear {
            self.model.isAppeared = true
        }
        .onDisappear {
            self.model.isAppeared = false
        }
        .accessibilityLabel(Text("Document Inspector", tableName: "Inspector"))
        .controlSize(.small)
    }
}


private struct DocumentFileView: View {
    
    var attributes: DocumentFile.Attributes?
    var fileURL: URL?
    
    @State private var isExpanded = true
    
    
    var body: some View {
        
        DisclosureGroup(String(localized: "Document File", table: "Inspector", comment: "section title"), isExpanded: $isExpanded) {
            Form {
                OptionalLabeledContent(String(localized: "Created", table: "Inspector"),
                                       value: self.attributes?.creationDate?.formatted(date: .abbreviated, time: .shortened))
                OptionalLabeledContent(String(localized: "Modified", table: "Inspector"),
                                       value: self.attributes?.modificationDate?.formatted(date: .abbreviated, time: .shortened))
                OptionalLabeledContent(String(localized: "Size", table: "Inspector"),
                                       value: self.attributes?.size.formatted(.byteCount(style: .file, includesActualByteCount: true)))
                OptionalLabeledContent(String(localized: "Permissions", table: "Inspector"),
                                       value: self.attributes?.permissions.formatted())
                OptionalLabeledContent(String(localized: "Owner", table: "Inspector"),
                                       value: self.attributes?.owner)
                OptionalLabeledContent(String(localized: "Full Path", table: "Inspector"),
                                       value: self.fileURL?.path)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}


private struct TextSettingsView: View {
    
    var encoding: FileEncoding
    var lineEnding: LineEnding
    
    @State private var isExpanded = true
    
    
    var body: some View {
        
        DisclosureGroup(String(localized: "Text Settings", table: "Inspector", comment: "section title"), isExpanded: $isExpanded) {
            Form {
                LabeledContent(String(localized: "Encoding", table: "Inspector"),
                               value: self.encoding.localizedName)
                LabeledContent(String(localized: "Line Endings", table: "Inspector"),
                               value: self.lineEnding.name)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}


private struct CountLocationView: View {
    
    var result: EditorCountResult
    
    @State private var isExpanded = true
    
    
    var body: some View {
        
        DisclosureGroup(String(localized: "Count", table: "Inspector", comment: "section title"), isExpanded: $isExpanded) {
            Form {
                OptionalLabeledContent(String(localized: "Lines", table: "Inspector"),
                                       value: self.result.lines.formatted)
                OptionalLabeledContent(String(localized: "Characters", table: "Inspector"),
                                       value: self.result.characters.formatted)
                OptionalLabeledContent(String(localized: "Words", table: "Inspector"),
                                       value: self.result.words.formatted)
                .padding(.bottom, 8)
                
                OptionalLabeledContent(String(localized: "Location", table: "Inspector"),
                                       value: self.result.location?.formatted())
                OptionalLabeledContent(String(localized: "Line", table: "Inspector"),
                                       value: self.result.line?.formatted())
                OptionalLabeledContent(String(localized: "Column", table: "Inspector"),
                                       value: self.result.column?.formatted())
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}


private struct CharacterPaneView: View {
    
    var character: Character?
    
    @State private var isExpanded = true
    
    
    var body: some View {
    
        DisclosureGroup(String(localized: "Character", table: "Inspector", comment: "section title"), isExpanded: $isExpanded) {
            Form {
                if let character {
                    LabeledContent(String(localized: "Code Points", table: "Inspector")) {
                        ForEach(Array(character.unicodeScalars.enumerated()), id: \.offset) { (_, scalar) in
                            Text(scalar.codePoint)
                                .monospacedDigit()
                                .textSelection(.enabled)
                                .padding(.horizontal, 2)
                                .overlay(RoundedRectangle(cornerRadius: 3.5).inset(by: 0.5)
                                    .stroke(Color.tertiaryLabel))
                                .fixedSize()
                        }
                    }
                } else {
                    Text("Not selected", tableName: "Inspector", comment: "placeholder")
                        .foregroundStyle(Color.tertiaryLabel)
                        .help(String(localized: "Select a single character to show Unicode information.", table: "Inspector", comment: "help"))
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
            } else {
                Text(verbatim: "–").foregroundStyle(Color.tertiaryLabel)
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
    
    func invalidateObservation() {
        
        let analyzer = self.document.analyzer
        
        analyzer.updatesAll = self.isAppeared
        
        if self.isAppeared {
            analyzer.invalidate()
            self.observers = [
                self.document.publisher(for: \.fileURL, options: .initial)
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] in self?.fileURL = $0 },
                self.document.$fileAttributes
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] in self?.attributes = $0 },
                self.document.$fileEncoding
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] in self?.encoding = $0 },
                self.document.$lineEnding
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] in self?.lineEnding = $0 },
                self.document.analyzer.$result
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] in self?.countResult = $0 },
            ]
        } else {
            self.observers.removeAll()
        }
    }
}



// MARK: - Preview

@available(macOS 14, *)
#Preview(traits: .fixedLayout(width: 240, height: 500)) {
    let model = DocumentInspectorView.Model(document: .init())
    model.attributes = .init(
        creationDate: .now,
        modificationDate: .now,
        size: 1024,
        permissions: FilePermissions(mask: 0o420),
        owner: "1024jp"
    )
    model.fileURL = URL(filePath: "/User/Claus/Desktop/My Script.py")
    model.encoding = .init(encoding: .utf8, withUTF8BOM: true)
    model.countResult = .init(
        lines: .init(entire: 10, selected: 4),
        character: "🐈‍⬛"
    )
    
    return DocumentInspectorView(model: model)
}
