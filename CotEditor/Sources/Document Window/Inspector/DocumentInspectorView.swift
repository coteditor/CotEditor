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
//  © 2016-2026 1024jp
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
import CharacterInfo
import DocumentFile
import FileEncoding
import LineEnding
import SyntaxFormat

@MainActor @Observable private final class DocumentInspectorViewModel: DocumentInspectorView.ModelProtocol {
    
    var isPresented = false  { didSet { self.invalidateObservation() } }
    var document: DataDocument?  { willSet { self.cancelObservation() } didSet { self.didUpdateDocument() } }
    
    var attributes: FileAttributes?  { self.document?.fileAttributes }
    var fileURL: URL?
    var countResult: EditorCounter.Result?  { (self.document as? Document)?.counter.result }
    
    private var urlObserver: AnyCancellable?
    
    
    // MARK: Public Methods
    
    var textSettings: TextSettings? {
        
        if let document = self.document as? Document {
            TextSettings(encoding: document.fileEncoding, lineEnding: document.lineEnding, mode: document.mode)
        } else {
            nil
        }
    }
    
    
    // MARK: Private Methods
    
    /// Updates observations.
    private func didUpdateDocument() {
        
        self.fileURL = self.document?.fileURL
        
        if self.isPresented {
            self.startObservation()
        }
    }
    
    
    /// Invalidates observation on the document depending on the current view visibility state.
    private func invalidateObservation() {
        
        if self.isPresented {
            self.startObservation()
        } else {
            self.cancelObservation()
        }
    }
    
    
    /// Starts observations on the document.
    private func startObservation() {
        
        (document as? Document)?.counter.updatesAll = true
        
        self.urlObserver = document?.publisher(for: \.fileURL, options: .initial)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.fileURL = $0 }
    }
    
    
    /// Cancels the observations on the document.
    private func cancelObservation() {
        
        (self.document as? Document)?.counter.updatesAll = false
        self.urlObserver = nil
    }
}


// MARK: - View

struct TextSettings {
    
    var encoding: FileEncoding
    var lineEnding: LineEnding
    var mode: Mode
}


struct DocumentInspectorView: View, HostedPaneView {
    
    @MainActor protocol ModelProtocol {
        
        var document: DataDocument? { get set }
        var isPresented: Bool { get set }
        
        var attributes: FileAttributes? { get }
        var fileURL: URL? { get }
        var textSettings: TextSettings? { get }
        var countResult: EditorCounter.Result? { get }
    }
    
    
    var document: DataDocument?
    var isPresented: Bool = false
    
    @State var model: any ModelProtocol = DocumentInspectorViewModel()
    
    
    var body: some View {
        
        ScrollView(.vertical) {
            VStack(spacing: 8) {
                DocumentFileView(attributes: self.model.attributes, fileURL: self.model.fileURL)
                
                if let textSettings = self.model.textSettings {
                    TextSettingsView(value: textSettings)
                }
                
                if let countResult = self.model.countResult {
                    EditorCountView(result: countResult)
                    CharacterPaneView(character: countResult.character)
                }
            }
            .disclosureGroupStyle(InspectorDisclosureGroupStyle())
            .labeledContentStyle(InspectorLabeledContentStyle())
            .formStyle(.grouped)
            .padding(12)
        }
        .onChange(of: self.document, initial: true) { _, newValue in
            self.model.document = newValue
        }
        .onChange(of: self.isPresented, initial: true) { _, newValue in
            self.model.isPresented = newValue
        }
        .accessibilityLabel(.init("InspectorPane.document.label", defaultValue: "Document Inspector", table: "Document"))
        .controlSize(.small)
    }
}


private struct DocumentFileView: View {
    
    var attributes: FileAttributes?
    var fileURL: URL?
    
    @State private var isExpanded = true
    
    
    var body: some View {
        
        DisclosureGroup(.init("File", table: "Document", comment: "section title in inspector"), isExpanded: $isExpanded) {
            Form {
                LabeledContent(.init("Created", table: "Document", comment: "label in document inspector"),
                               optional: self.attributes?.creationDate?.formatted(date: .abbreviated, time: .shortened))
                LabeledContent(.init("Modified", table: "Document", comment: "label in document inspector"),
                               optional: self.attributes?.modificationDate?.formatted(date: .abbreviated, time: .shortened))
                LabeledContent(.init("Size", table: "Document", comment: "label in document inspector"),
                               optional: self.attributes?.size.formatted(.byteCount(style: .file, includesActualByteCount: true)))
                
                LabeledContent(.init("Tags", table: "Document", comment: "label in document inspector")) {
                    if let tags = self.attributes?.tags, !tags.isEmpty {
                        WrappingHStack(alignment: .trailing, horizontalSpacing: 7) {
                            ForEach(tags.enumerated(), id: \.offset) { _, tag in
                                HStack(spacing: 4) {
                                    TagColorView(color: tag.color)
                                        .frame(height: 9)
                                    Text(tag.name)
                                }.accessibilityLabel(tag.name)
                            }
                        }
                    } else {
                        Text.none
                    }
                }
                LabeledContent(.init("Permissions", table: "Document", comment: "label in document inspector"),
                               optional: self.attributes?.permissions.formatted())
                LabeledContent(.init("Owner", table: "Document", comment: "label in document inspector"),
                               optional: self.attributes?.owner)
                
                LabeledContent(.init("Full Path", table: "Document", comment: "label in document inspector")) {
                    if let fileURL = self.fileURL {
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text(fileURL, format: .url.scheme(.never))
                                .lineLimit(5)
                                .truncationMode(.middle)
                                .textSelection(.enabled)
                                .help(fileURL.formatted(.url.scheme(.never)))
                            Button(.init("Show in Finder", table: "Document"), systemImage: "arrow.forward") {
                                NSWorkspace.shared.activateFileViewerSelecting([fileURL])
                            }
                            .symbolVariant(.circle.fill)
                            .fontWeight(.bold)
                            .labelStyle(.iconOnly)
                            .controlSize(.mini)
                            .buttonStyle(.borderless)
                        }
                    } else {
                        Text.none
                    }
                }
            }
        }
    }
}


private struct TextSettingsView: View {
    
    var value: TextSettings
    
    @State private var isExpanded = true
    
    
    var body: some View {
        
        DisclosureGroup(.init("Text Settings", table: "Document", comment: "section title in inspector"), isExpanded: $isExpanded) {
            Form {
                LabeledContent(.init("Encoding", table: "Document", comment: "label in document inspector"),
                               value: self.value.encoding.localizedName)
                LabeledContent(.init("Line Endings", table: "Document", comment: "label in document inspector"),
                               value: self.value.lineEnding.label)
                LabeledContent(.init("Mode", table: "Document", comment: "label in document inspector"),
                               value: self.value.mode.label)
            }
        }
    }
}


private struct EditorCountView: View {
    
    var result: EditorCounter.Result
    
    @State private var isExpanded = true
    
    
    var body: some View {
        
        DisclosureGroup(.init("Count", table: "Document", comment: "section title in inspector"), isExpanded: $isExpanded) {
            Form {
                Section {
                    ForEach(CountType.countCases, id: \.self) { type in
                        LabeledContent(type.label, optional: self.result.formattedValue(type: type))
                            .accessibilityAddTraits(.updatesFrequently)
                    }
                }
                Section {
                    ForEach(CountType.positionCases, id: \.self) { type in
                        LabeledContent(type.label, optional: self.result.formattedValue(type: type))
                            .accessibilityAddTraits(.updatesFrequently)
                    }
                }
            }
            .monospacedDigit()
        }
    }
}


private struct CharacterPaneView: View {
    
    var character: Character?
    
    @State private var isExpanded = true
    
    
    var body: some View {
        
        DisclosureGroup(.init("Character", table: "Document", comment: "section title in inspector"), isExpanded: $isExpanded) {
            Form {
                if let scalars = self.character?.unicodeScalars {
                    LabeledContent {
                        WrappingHStack(alignment: .trailing) {
                            ForEach(Array(scalars).enumerated(), id: \.offset) { _, scalar in
                                Text(scalar.codePoint)
                                    .monospacedDigit()
                                    .textSelection(.enabled)
                                    .padding(.horizontal, 2)
                                    .overlay(RoundedRectangle(cornerRadius: 3.5)
                                        .strokeBorder(.tertiary))
                            }
                        }
                    } label: {
                        (scalars.count == 1)
                            ? Text("Code Point", tableName: "Document", comment: "label in document inspector")
                            : Text("Code Points", tableName: "Document", comment: "label in document inspector")
                    }
                    if scalars.count == 1, let scalar = scalars.first {
                        LabeledContent(.init("Name", table: "Document", comment: "label in document inspector"),
                                       optional: scalar.name)
                        LabeledContent(.init("Block", table: "Document", comment: "label in document inspector"),
                                       optional: scalar.localizedBlockName)
                        let category = scalar.properties.generalCategory
                        LabeledContent(.init("Category", table: "Document", comment: "label in document inspector"),
                                       value: "\(category.longName) (\(category.shortName))")
                    }
                } else {
                    Text("Not selected", tableName: "Document", comment: "placeholder")
                        .foregroundStyle(.tertiary)
                        .help(.init("Select a single character to show Unicode information.", table: "Document", comment: "tooltip"))
                }
            }
        }
    }
}


private struct InspectorDisclosureGroupStyle: DisclosureGroupStyle {
    
    func makeBody(configuration: Configuration) -> some View {
        
        DisclosureGroup(isExpanded: configuration.$isExpanded) {
            // specify negative paddings to cancel paddings implicitly added to Form.formStyle(.grouped)
            // (2026-04, macOS 26.4)
            configuration.content
                .padding(.top, -6)
                .padding(.horizontal, -12)
        } label: {
            configuration.label
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .fixedSize()
        }
    }
}


private struct InspectorLabeledContentStyle: LabeledContentStyle {
    
    @Environment(\.controlSize) private var controlSize
    
    
    func makeBody(configuration: Configuration) -> some View {
        
        LabeledContent {
            configuration.content
        } label: {
            configuration.label
                // forcibly set font size since the label in grouped form ignores the controlSize (2026-04, macOS 26.4)
                .font(.system(size: NSFont.systemFontSize(for: self.controlSize.nsControlSize)))
        }
    }
}


private extension ControlSize {
    
    var nsControlSize: NSControl.ControlSize {
        
        switch self {
            case .mini: .mini
            case .small: .small
            case .regular: .regular
            case .large: .large
            case .extraLarge: .extraLarge
            @unknown default: .regular
        }
    }
}


// MARK: - Preview

@MainActor private struct MockedModel: DocumentInspectorView.ModelProtocol {
    
    var document: DataDocument?
    var isPresented: Bool = true
    
    var attributes: FileAttributes?
    var fileURL: URL?
    var textSettings: TextSettings?
    var countResult: EditorCounter.Result?
}


#Preview {
    let model = MockedModel(
        attributes: .init(
            creationDate: .now,
            modificationDate: .now,
            size: 1024,
            permissions: FilePermissions(mask: 0o644),
            owner: "clarus",
            tags: [FinderTag(name: "Green", color: .green),
                   FinderTag(name: "Blue", color: .blue),
                   FinderTag(name: "None")]
        ),
        fileURL: URL(filePath: "/Users/clarus/Desktop/My Script.py"),
        textSettings: .init(
            encoding: .init(encoding: .utf8, withUTF8BOM: true),
            lineEnding: .lf,
            mode: .kind(.general)
        ),
        countResult: .init())
    model.countResult?.characters = .init(entire: 1024, selected: 4)
    model.countResult?.lines = .init(entire: 10, selected: 1)
    model.countResult?.character = "🐈‍⬛"
    
    return DocumentInspectorView(model: model)
        .frame(width: 240)
}


#Preview {
    DocumentInspectorView(isPresented: true, model: MockedModel())
        .frame(width: 240)
}
