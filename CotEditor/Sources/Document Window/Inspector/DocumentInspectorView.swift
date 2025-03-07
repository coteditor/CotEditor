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
//  © 2016-2025 1024jp
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
import FileEncoding
import FilePermissions
import LineEnding
import Syntax

final class DocumentInspectorViewController: NSHostingController<DocumentInspectorView> {
    
    // MARK: Public Properties
    
    var document: DataDocument? {
        
        didSet {
            if self.isViewShown {
                self.model.updateDocument(to: document)
            }
        }
    }
    
    
    // MARK: Private Properties
    
    private let model = DocumentInspectorView.Model()
    
    
    // MARK: Lifecycle
    
    required init(document: DataDocument?) {
        
        self.document = document
        
        super.init(rootView: DocumentInspectorView(model: self.model))
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        self.model.updateDocument(to: self.document)
    }
    
    
    override func viewDidDisappear() {
        
        super.viewDidDisappear()
        
        self.model.updateDocument(to: nil)
    }
}


@Observable final class TextSettings {
    
    var encoding: FileEncoding
    var lineEnding: LineEnding
    var mode: Mode
    
    
    init(encoding: FileEncoding, lineEnding: LineEnding, mode: Mode) {
        
        self.encoding = encoding
        self.lineEnding = lineEnding
        self.mode = mode
    }
}


struct DocumentInspectorView: View {
    
    @MainActor @Observable final class Model {
        
        fileprivate var attributes: FileAttributes?
        fileprivate var fileURL: URL?
        fileprivate var textSettings: TextSettings?
        fileprivate var countResult: EditorCounter.Result?
        
        private(set) var document: DataDocument?
        
        private var observers: Set<AnyCancellable> = []
        
        
        /// Updates the represented document.
        ///
        /// - Parameter document: The new data document, or `nil`.
        func updateDocument(to document: DataDocument?) {
            
            self.invalidateObservation(document: document)
            self.document = document
        }
    }
    
    
    @State var model: Model
    
    
    var body: some View {
        
        ScrollView(.vertical) {
            VStack(spacing: 8) {
                DocumentFileView(attributes: self.model.attributes, fileURL: self.model.fileURL)
                
                if let textSettings = self.model.textSettings {
                    Divider()
                    TextSettingsView(value: textSettings)
                }
                
                if let countResult = self.model.countResult {
                    Divider()
                    CountLocationView(result: countResult)
                    
                    Divider()
                    CharacterPaneView(character: countResult.character)
                }
            }
            .padding(EdgeInsets(top: 4, leading: 12, bottom: 12, trailing: 12))
            .disclosureGroupStyle(InspectorDisclosureGroupStyle())
            .labeledContentStyle(InspectorLabeledContentStyle())
            .onChange(of: self.model.document?.fileAttributes, initial: true) { (_, newValue) in
                self.model.attributes = newValue
            }
        }
        .accessibilityLabel(Text("Document Inspector", tableName: "Document"))
        .controlSize(.small)
    }
}


private struct DocumentFileView: View {
    
    var attributes: FileAttributes?
    var fileURL: URL?
    
    @State private var isExpanded = true
    
    
    var body: some View {
        
        DisclosureGroup(String(localized: "File", table: "Document", comment: "section title in inspector"), isExpanded: $isExpanded) {
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
                
                LabeledContent(String(localized: "Tags", table: "Document", comment: "label in document inspector")) {
                    if let tags = self.attributes?.tags, !tags.isEmpty {
                        WrappingHStack(horizontalSpacing: 7) {
                            ForEach(Array(tags.enumerated()), id: \.offset) { (_, tag) in
                                HStack(spacing: 4) {
                                    TagColorView(color: tag.color)
                                        .frame(height: 9)
                                    Text(tag.name)
                                }.accessibilityLabel(tag.name)
                            }
                        }
                    } else {
                        NoneTextView()
                    }
                }
                OptionalLabeledContent(String(localized: "Permissions", table: "Document",
                                              comment: "label in document inspector"),
                                       value: self.attributes?.permissions.formatted())
                OptionalLabeledContent(String(localized: "Owner", table: "Document",
                                              comment: "label in document inspector"),
                                       value: self.attributes?.owner)
                
                LabeledContent(String(localized: "Full Path", table: "Document", comment: "label in document inspector")) {
                    if let fileURL = self.fileURL {
                        HStack(alignment: .lastTextBaseline, spacing: 0) {
                            Text(fileURL, format: .url.scheme(.never))
                                .lineLimit(5)
                                .truncationMode(.middle)
                                .textSelection(.enabled)
                                .foregroundStyle(.primary)
                                .help(fileURL.formatted(.url.scheme(.never)))
                            Button(String(localized: "Show in Finder", table: "Document"), systemImage: "arrow.forward") {
                                NSWorkspace.shared.activateFileViewerSelecting([fileURL])
                            }
                            .symbolVariant(.circle.fill)
                            .fontWeight(.bold)
                            .labelStyle(.iconOnly)
                            .controlSize(.mini)
                            .buttonStyle(.borderless)
                        }
                    } else {
                        NoneTextView()
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}


private struct TextSettingsView: View {
    
    var value: TextSettings
    
    @State private var isExpanded = true
    
    
    var body: some View {
        
        DisclosureGroup(String(localized: "Text Settings", table: "Document", comment: "section title in inspector"), isExpanded: $isExpanded) {
            Form {
                LabeledContent(String(localized: "Encoding", table: "Document",
                                      comment: "label in document inspector"),
                               value: self.value.encoding.localizedName)
                LabeledContent(String(localized: "Line Endings", table: "Document",
                                      comment: "label in document inspector"),
                               value: self.value.lineEnding.label)
                LabeledContent(String(localized: "Mode", table: "Document",
                                      comment: "label in document inspector"),
                               value: self.value.mode.label)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}


private struct CountLocationView: View {
    
    var result: EditorCounter.Result
    
    @State private var isExpanded = true
    
    
    var body: some View {
        
        DisclosureGroup(String(localized: "Count", table: "Document", comment: "section title in inspector"), isExpanded: $isExpanded) {
            Form {
                OptionalLabeledContent(String(localized: "Lines", table: "Document",
                                              comment: "label in document inspector"),
                                       value: self.result.lines.formatted)
                .accessibilityAddTraits(.updatesFrequently)
                OptionalLabeledContent(String(localized: "Characters", table: "Document",
                                              comment: "label in document inspector"),
                                       value: self.result.characters.formatted)
                .accessibilityAddTraits(.updatesFrequently)
                OptionalLabeledContent(String(localized: "Words", table: "Document",
                                              comment: "label in document inspector"),
                                       value: self.result.words.formatted)
                .accessibilityAddTraits(.updatesFrequently)
                .padding(.bottom, 8)
                
                OptionalLabeledContent(String(localized: "Location", table: "Document",
                                              comment: "label in document inspector"),
                                       value: self.result.location?.formatted())
                .accessibilityAddTraits(.updatesFrequently)
                OptionalLabeledContent(String(localized: "Line", table: "Document",
                                              comment: "label in document inspector"),
                                       value: self.result.line?.formatted())
                .accessibilityAddTraits(.updatesFrequently)
                OptionalLabeledContent(String(localized: "Column", table: "Document",
                                              comment: "label in document inspector"),
                                       value: self.result.column?.formatted())
                .accessibilityAddTraits(.updatesFrequently)
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
                if let scalars = self.character?.unicodeScalars {
                    let label = (scalars.count == 1)
                    ? String(localized: "Code Point", table: "Document",
                             comment: "label in document inspector")
                    : String(localized: "Code Points", table: "Document",
                             comment: "label in document inspector")
                    LabeledContent(label) {
                        WrappingHStack {
                            ForEach(Array(scalars.enumerated()), id: \.offset) { (_, scalar) in
                                Text(scalar.codePoint)
                                    .monospacedDigit()
                                    .textSelection(.enabled)
                                    .padding(.horizontal, 2)
                                    .overlay(RoundedRectangle(cornerRadius: 3.5)
                                        .strokeBorder(.tertiary))
                            }
                        }
                    }
                    if scalars.count == 1, let scalar = scalars.first {
                        OptionalLabeledContent(String(localized: "Name", table: "Document",
                                                      comment: "label in document inspector"),
                                               value: scalar.name)
                        OptionalLabeledContent(String(localized: "Block", table: "Document",
                                                      comment: "label in document inspector"),
                                               value: scalar.localizedBlockName)
                        let category = scalar.properties.generalCategory
                        OptionalLabeledContent(String(localized: "Category", table: "Document",
                                                      comment: "label in document inspector"),
                                               value: "\(category.longName) (\(category.shortName))")
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
    
    /// Updates observations.
    func invalidateObservation(document: DataDocument?) {
        
        (self.document as? Document)?.counter.updatesAll = false
        self.countResult = (document as? Document)?.counter.result
        
        if let document = document as? Document {
            document.counter.updatesAll = true
            
            self.textSettings = TextSettings(encoding: document.fileEncoding,
                                             lineEnding: document.lineEnding,
                                             mode: .kind(.general))
            self.observers = [
                document.publisher(for: \.fileURL, options: .initial)
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] in self?.fileURL = $0 },
                document.didChangeFileEncoding
                    .sink { [weak self] in self?.textSettings?.encoding = $0 },
                document.$lineEnding
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] in self?.textSettings?.lineEnding = $0 },
                document.$mode
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] in self?.textSettings?.mode = $0 },
            ]
            
        } else if let document {
            self.textSettings = nil
            self.observers = [
                document.publisher(for: \.fileURL, options: .initial)
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] in self?.fileURL = $0 },
            ]
            
        } else {
            self.textSettings = nil
            self.observers.removeAll()
            self.fileURL = nil
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
        owner: "clarus",
        tags: [FinderTag(name: "Green", color: .green),
               FinderTag(name: "Blue", color: .blue),
               FinderTag(name: "None")]
    )
    model.fileURL = URL(filePath: "/Users/clarus/Desktop/My Script.py")
    model.textSettings = .init(encoding: .init(encoding: .utf8, withUTF8BOM: true),
                               lineEnding: .lf,
                               mode: .kind(.general))
    
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
