//
//  FolderFindView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-05-17.
//
//  ---------------------------------------------------------------------------
//
//  © 2026 1024jp
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
import UniformTypeIdentifiers
import Defaults
import FolderFind
import StringUtils

struct FolderFindView: View {
    
    @Bindable var model: FolderFinder
    
    @State private var selection: Set<FolderFind.ResultID> = []
    
    
    var body: some View {
        
        List(selection: $selection) {
            if case .finished(let summary) = self.model.state {
                ForEach(summary.files) { file in
                    FolderFindFileResultView(file: file, revision: self.model.resultRevision)
                }
            }
        }
        .safeAreaBar(edge: .top) {
            VStack(spacing: 0) {
                FolderFindControlView(model: self.model)
                    .padding(10)
                FolderFindMetricsBarView(state: self.model.state)
            }
        }
        .scrollContentBackground(.hidden)
        .scrollEdgeEffectStyle(.hard, for: .top)
        .overlay {
            FolderFindOverlayView(state: self.model.state)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .controlSize(.small)
        }
        .contextMenu(forSelectionType: FolderFind.ResultID.self) { selections in
            if selections.count == 1,
               let selection = selections.first,
               let result = self.summary?.result(for: selection)
            {
                self.contextMenu(for: result.file)
            }
        }
        .dragPreviewsFormation(.list)
        .onChange(of: self.model.resultRevision) {
            self.selection.removeAll()
        }
        .onChange(of: self.selection) { _, newValue in
            guard
                newValue.count == 1,
                let selection = newValue.first,
                let result = self.summary?.result(for: selection)
            else { return }
            
            self.model.selectResult(fileURL: result.file.fileURL, range: result.match?.range)
        }
        .onDeleteCommand {
            for resultID in self.selection {
                self.model.removeResult(for: resultID)
            }
            self.selection.removeAll()
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(SidebarPane.find.label)
    }
    
    
    /// The current search summary if results are available.
    private var summary: FolderFind.Summary? {
        
        guard case .finished(let summary) = self.model.state else { return nil }
        
        return summary
    }
    
    
    /// Builds the context menu for a file result.
    ///
    /// - Parameter file: The file result represented by the selected row.
    /// - Returns: The context menu content.
    @ContentBuilder private func contextMenu(for file: FolderFind.FileResult) -> some View {
        
        Button(String(localized: "Reveal in File Browser", table: "Document"), systemImage: "folder") {
            self.model.document.revealInFileBrowser(fileURL: file.fileURL)
        }
        
        Button(String(localized: "Show in Finder", table: "Document"), systemImage: "finder") {
            NSWorkspace.shared.activateFileViewerSelecting([file.fileURL])
        }
        
        Button(String(localized: "Open in New Window", table: "Document"), systemImage: "macwindow.badge.plus") {
            self.model.document.openInNewWindow(fileURL: file.fileURL)
        }
        
        Divider()
        
        Button(String(localized: "Open with External Editor", table: "Document"), systemImage: "arrow.up.forward.square") {
            NSWorkspace.shared.openWithOtherApplication([file.fileURL])
        }
    }
}


private struct FolderFindControlView: View {
    
    var model: FolderFinder
    
    @State private var textFinderSettings: TextFinderSettings = .shared
    @State private var fileScopeSelection = FileScopeSelection()
    
    @AppStorage(.folderFindUsesRegularExpression) private var usesRegularExpression: Bool
    @AppStorage(.folderFindIgnoresCase) private var ignoresCase: Bool
    @AppStorage(.folderFindIncludesHiddenFiles) private var includesHiddenFiles: Bool
    @AppStorage(.folderFindIncludesOtherFileTypes) private var includesOtherFileTypes: Bool
    
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Picker(String(localized: "Search method", table: "Document"), selection: $usesRegularExpression) {
                    Text("Text", tableName: "TextFind")
                        .tag(false)
                    Text("Regular Expression", tableName: "TextFind")
                        .tag(true)
                } currentValueLabel: {
                    self.usesRegularExpression
                        ? Text("Regular Expression", tableName: "TextFind")
                            .foregroundStyle(.tint)
                        : Text("Text", tableName: "TextFind")
                }
                .pickerStyle(.menu)
                .labelsVisibility(.hidden)
                
                Spacer()
                
                Toggle(isOn: Binding(get: { !self.ignoresCase }, set: { self.ignoresCase = !$0 })) {
                    Label {
                        Text(String(localized: "Case Sensitive", table: "TextFind", comment: "toggle button label"))
                    } icon: {
                        Image(systemName: "textformat")
                            .environment(\.locale, Locale(script: .latin))
                    }
                }
                .help(String(localized: "Case Sensitive", table: "TextFind", comment: "toggle button label"))
                .toggleStyle(.button)
                .fontWeight(self.ignoresCase ? .medium : .bold)
                .labelStyle(.iconOnly)
                .frame(width: 16, alignment: .center)
            }
            .buttonStyle(.borderless)
            .controlSize(.small)
            
            SearchField(text: $textFinderSettings.findString,
                        placeholder: String(localized: "Search in Folder", table: "Document", comment: "placeholder"))
            .autosaveName("FolderSearch")
            .isRegex(self.usesRegularExpression)
            .onSubmit { findString in
                self.model.find(findString: findString,
                                usesRegularExpression: self.usesRegularExpression,
                                ignoresCase: self.ignoresCase,
                                includesHiddenFiles: self.includesHiddenFiles,
                                includesOtherFileTypes: self.includesOtherFileTypes,
                                fileScope: self.fileScopeSelection.fileScope.isEmpty ? nil : self.fileScopeSelection.fileScope)
            }
            .onTextChange { findString in
                self.model.findStringDidChange(to: findString)
            }
            
            FileScopeMenu(selection: $fileScopeSelection,
                          includesHiddenFiles: $includesHiddenFiles,
                          includesOtherFileTypes: $includesOtherFileTypes)
        }
    }
}


private struct FileScopeSelection {
    
    var name: String?
    var fileScope = FileScope()
}


private struct FileScopeMenu: View {
    
    @Binding var selection: FileScopeSelection
    @Binding var includesHiddenFiles: Bool
    @Binding var includesOtherFileTypes: Bool
    
    @State private var savedScopesData: [String: Data] = [:]
    @State private var isFileScopeEditorPresented = false
    @State private var isSavedScopesEditorPresented = false
    
    
    var body: some View {
        
        let savedScopes = self.savedScopesData.compactMapValues { try? JSONDecoder().decode(FileScope.self, from: $0) }
        
        Menu {
            Section {
                Toggle(String(localized: "Include Hidden Files", table: "Document", comment: "toggle button label"), isOn: $includesHiddenFiles)
                Toggle(String(localized: "Include Other File Types", table: "Document", comment: "toggle button label"), isOn: $includesOtherFileTypes)
            }
            
            Button(String(localized: "Edit File Scope…", table: "Document")) {
                self.isFileScopeEditorPresented = true
            }
            Button(String(localized: "Clear File Scope", table: "Document")) {
                self.selection = FileScopeSelection()
            }
            .disabled(self.selection.fileScope.isEmpty)
            
            if !savedScopes.isEmpty {
                Picker(String(localized: "Saved Scopes", table: "Document"), selection: $selection.name) {
                    ForEach(savedScopes.keys.sorted(using: .localizedStandard), id: \.self) { name in
                        Label(name, systemImage: "text.magnifyingglass")
                            .tag(name)
                    }
                }
                .pickerStyle(.inline)
                .labelStyle(.titleAndIcon)
                
                Button(String(localized: "Manage Saved Scopes…", table: "Document")) {
                    self.isSavedScopesEditorPresented = true
                }
            }
        } label: {
            Label(self.selection.name ?? String(localized: "File Scope", table: "Document"), systemImage: "text.magnifyingglass")
                .foregroundStyle(self.selection.fileScope.isEmpty ? .secondary : Color.accentColor)
                .labelIconToTitleSpacing(6)
        }
        .buttonStyle(.plain)
        .controlSize(.small)
        .onChange(of: self.selection.name) { _, newValue in
            // fired also on programmatic selection updates, in which case the reassignment below
            // is harmless because the looked-up scope is identical to the one already assigned
            if let newValue, let fileScope = savedScopes[newValue] {
                self.selection.fileScope = fileScope
            }
        }
        .sheet(isPresented: $isFileScopeEditorPresented) {
            FolderFindFileScopeView(fileScope: self.selection.fileScope, name: self.selection.name, savedScopeNames: Set(self.savedScopesData.keys)) { fileScope, name in
                self.apply(fileScope, name: name)
            }
            .scenePadding()
            .presentationSizing(FolderFindFileScopeView.sheetPresentationSizing)
        }
        .sheet(isPresented: $isSavedScopesEditorPresented) {
            FolderFindSavedScopesView(scopes: savedScopes,
                                      savedScopeNames: Set(self.savedScopesData.keys),
                                      changeHandler: self.handleSavedScopesChange)
            .scenePadding()
            .presentationSizing(.fitted)
        }
        .onReceive(UserDefaults.standard.publisher(for: .folderFindSavedScopes, initial: true)) { scopesData in
            self.savedScopesData = scopesData
            
            if let name = self.selection.name {
                if let data = scopesData[name], let fileScope = try? JSONDecoder().decode(FileScope.self, from: data) {
                    self.selection.fileScope = fileScope
                } else {
                    self.selection.name = nil
                }
            }
        }
    }
    
    
    /// Applies a file scope edited from the scope menu.
    ///
    /// - Parameters:
    ///   - fileScope: The edited file scope.
    ///   - name: The name under which the file scope is saved, or `nil` for an unnamed scope.
    private func apply(_ fileScope: FileScope, name: String?) {
        
        if let name {
            self.save(fileScope, name: name, replacing: self.selection.name)
        }
        
        self.selection = FileScopeSelection(name: name, fileScope: fileScope)
        
        if name != nil {
            self.persistSavedScopes()
        }
    }
    
    
    /// Applies a change from the saved scopes editor.
    ///
    /// - Parameter change: The change to apply.
    private func handleSavedScopesChange(_ change: FolderFindSavedScopesView.Change) {
        
        switch change {
            case .add(let name, let fileScope):
                self.save(fileScope, name: name)
                
            case .update(let originalName, let name, let fileScope):
                self.save(fileScope, name: name, replacing: originalName)
                
                if self.selection.name == originalName {
                    self.selection = FileScopeSelection(name: name, fileScope: fileScope)
                }
                
            case .delete(let name):
                self.savedScopesData[name] = nil
                
                if self.selection.name == name {
                    self.selection.name = nil
                }
        }
        
        self.persistSavedScopes()
    }
    
    
    /// Saves a file scope in the persisted representation.
    ///
    /// - Parameters:
    ///   - fileScope: The file scope to save.
    ///   - name: The name under which to save the file scope.
    ///   - originalName: The current name to remove, or `nil` when adding a scope.
    private func save(_ fileScope: FileScope, name: String, replacing originalName: String? = nil) {
        
        let data: Data
        do {
            data = try JSONEncoder().encode(fileScope)
        } catch {
            assertionFailure("Failed to encode a saved file scope: \(error)")
            return
        }
        
        if let originalName {
            self.savedScopesData[originalName] = nil
        }
        self.savedScopesData[name] = data
    }
    
    
    /// Writes the saved scopes to the user defaults.
    private func persistSavedScopes() {
        
        UserDefaults.standard[.folderFindSavedScopes] = self.savedScopesData
    }
}


private struct FolderFindMetricsBarView: View {
    
    var state: FolderFinder.SearchState
    
    
    var body: some View {
        
        switch self.state {
            case .searching(let progress):
                TimelineView(.periodic(from: .now, by: 0.1)) { _ in
                    MessageView(metrics: progress.snapshot)
                }
                
            case .finished(let summary):
                MessageView(metrics: summary.metrics)
                
            case .idle, .failed:
                EmptyView()
        }
    }
    
    
    private struct MessageView: View {
        
        var metrics: FolderFind.Metrics
        
        
        var body: some View {
            
            VStack(spacing: 6) {
                Divider()
                Text(self.metrics.message)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .controlSize(.small)
                    .padding(.horizontal, 10)
                Divider()
            }
        }
    }
}


private struct FolderFindOverlayView: View {
    
    var state: FolderFinder.SearchState
    
    
    var body: some View {
        
        switch self.state {
            case .searching:
                ProgressView(String(localized: "FolderFind.SearchState.searching.label",
                                    defaultValue: "Searching in folder…", table: "Document"))
                
            case .finished(let summary) where summary.metrics.matchCount == 0:
                UnavailableView(title: String(localized: "FolderFind.SearchState.finished.zero.label",
                                              defaultValue: "No Results", table: "Document"),
                                systemImage: "magnifyingglass",
                                description: String(localized: "FolderFind.SearchState.finished.zero.description",
                                                    defaultValue: "No matches for “\(summary.metrics.findString)” were found.",
                                                    table: "Document"))
                
            case .failed(let error):
                UnavailableView(title: String(localized: "FolderFind.SearchState.failed.label",
                                              defaultValue: "Search Failed", table: "Document"),
                                systemImage: "exclamationmark.triangle",
                                description: error.localizedDescription)
                
            case .idle, .finished:
                EmptyView()
        }
    }
}


private struct FolderFindFileResultView: View {
    
    var file: FolderFind.FileResult
    var revision: Int
    
    @State private var isExpanded = true
    
    
    var body: some View {
        
        DisclosureGroup(isExpanded: $isExpanded) {
            ForEach(self.file.matches) { match in
                ItemView(match: match)
                    .tag(FolderFind.ResultID.match(fileID: self.file.id, matchID: match.id))
            }
        } label: {
            Label {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(self.file.filename)
                        .fontWeight(.medium)
                        .layoutPriority(1)
                    
                    if !self.file.directoryPathComponents.isEmpty {
                        let path = self.file.directoryPathComponents.joined(separator: "/")
                        Text(path)
                            .foregroundStyle(.secondary)
                            .help(path)
                    }
                }
            } icon: {
                Image(systemName: "doc.text")
            }
            .lineLimit(1)
            .draggable(item: FolderFindDraggedFile(id: .file(self.file.id)))
        }
        .labelIconToTitleSpacing(4)
        .listRowSeparator(.hidden)
        .tag(FolderFind.ResultID.file(self.file.id))
        .onChange(of: self.revision) {
            self.isExpanded = true
        }
    }
    
    
    private struct ItemView: View {
        
        var match: FolderFind.Match
        
        private static let truncationHeadOffset = 32
        
        
        var body: some View {
            
            Label {
                // realize character line break, which is currently not available in SwiftUI (2026-06, macOS 27)
                Text(self.highlightedLine.lineBreakableByCharacter())
                    .accessibilityLabel(self.accessibilityLine)
            } icon: {
                Image(.textSquareFill)
                    .symbolRenderingMode(.hierarchical)
            }
            .foregroundStyle(.secondary)
            .lineLimit(3)
        }
        
        
        /// The line text with the matched substring emphasized.
        private var highlightedLine: AttributedString {
            
            var attributedLine = AttributedString(self.match.line)
            var rangeInLine = self.match.rangeInLine
            
            // trim leading whitespace
            let indentationLength = self.match.line.prefix(while: \.isWhitespace).utf16.count
            if indentationLength > 0,
               rangeInLine.location >= indentationLength,
               let range = Range(NSRange(0..<indentationLength), in: attributedLine)
            {
                attributedLine.removeSubrange(range)
                rangeInLine.location -= indentationLength
            }
            
            guard let range = Range(rangeInLine, in: attributedLine) else {
                return attributedLine
            }
            
            attributedLine[range].inlinePresentationIntent = .stronglyEmphasized
            attributedLine[range].foregroundColor = .primary
            
            return attributedLine.truncatedHead(until: range.lowerBound, offset: Self.truncationHeadOffset)
        }
        
        
        /// The line text for accessibility.
        private var accessibilityLine: String {
            
            let index = String.Index(utf16Offset: self.match.rangeInLine.lowerBound, in: self.match.line)
            
            return self.match.line.truncatedHead(until: index, offset: Self.truncationHeadOffset)
        }
    }
}


private struct UnavailableView: View {
    
    var title: String
    var systemImage: String
    var description: String
    
    
    var body: some View {
        
        ContentUnavailableView {
            Label {
                Text(self.title)
                    .font(.system(size: 16))
                    .fontWeight(.medium)
            } icon: {
                Image(systemName: self.systemImage)
            }
        } description: {
            Text(self.description)
        }
    }
}


// MARK: - Private Models

private struct FolderFindDraggedFile: Transferable, Identifiable {
    
    var id: FolderFind.ResultID
    
    
    /// The transfer representations of a dragged file result.
    ///
    /// The exported file is currently passed to receivers as a temporary copy in the app's
    /// own sandbox container (`Caches/com.apple.SwiftUI.Drag-*`) instead of
    /// the actual file URL (FB23578716): dropping on the Finder still creates the file and
    /// application icons still open it, but receivers interpreting the URL itself, such as
    /// browser windows and text views accepting file paths, observe the container path.
    ///
    /// A `DataRepresentation` exporting the actual file URL data as `.fileURL` doesn't
    /// work around the issue either; the data is likewise replaced with the copy's URL,
    /// and moreover, drops onto application icons are not accepted anymore.
    static var transferRepresentation: some TransferRepresentation {
        
        FileRepresentation(exportedContentType: .data) { item in
            SentTransferredFile(item.fileURL, allowAccessingOriginalFile: true)
        }
        .suggestedFileName(\.fileURL.lastPathComponent)
        
        ProxyRepresentation(exporting: \.fileURL.absoluteString)
    }
    
    
    private var fileURL: URL {
        
        switch self.id {
            case .file(let fileURL), .match(let fileURL, _): fileURL
        }
    }
}


// MARK: - Private Extensions

extension FolderFinder.Error: LocalizedError {
    
    /// The localized description of the error.
    var errorDescription: String? {
        
        switch self {
            case .folderUnavailable:
                String(localized: "FolderFinder.Error.folderUnavailable.message",
                       defaultValue: "The folder cannot be found.", table: "Document")
            case .invalidQuery(let error):
                error.errorDescription
            case .searchFailed(let message):
                message
        }
    }
}


private extension FolderFind.Metrics {
    
    /// The localized summary message.
    var message: String {
        
        String(localized: "FolderFind.Metrics.message",
               defaultValue: "\(self.matchCount) matches in \(self.matchedFileCount) files",
               table: "Document", comment: "folder find result summary")
    }
}


private extension AttributedString {
    
    /// Inserts zero-width spaces (ZWS) between characters to allow character-by-character line wrapping.
    ///
    /// - Returns: An attributed string with zero-width spaces inserted between characters.
    func lineBreakableByCharacter() -> AttributedString {
        
        // rebuild the string at once instead of inserting ZWSs one by one, which is too slow for long lines
        self.runs.reduce(into: .init()) { attrString, run in
            // convert into String first because iterating AttributedString.CharacterView is slow
            let text = String(self[run.range].characters)
                .map(String.init)
                .joined(separator: "\u{200B}")
            
            let piece = AttributedString(text, attributes: run.attributes)
            if !attrString.characters.isEmpty {
                attrString.append(AttributedString("\u{200B}"))
            }
            attrString.append(piece)
        }
    }
}
