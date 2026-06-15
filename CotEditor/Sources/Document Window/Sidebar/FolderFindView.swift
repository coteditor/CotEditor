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
                    FolderFindFileResultView(file: file)
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
        .onChange(of: self.resultIDs) {
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
        .accessibilityLabel(SidebarPane.find.label)
    }
    
    
    /// The current search summary if results are available.
    private var summary: FolderFind.Summary? {
        
        guard case .finished(let summary) = self.model.state else { return nil }
        
        return summary
    }
    
    
    /// The result IDs in the current search summary.
    private var resultIDs: [FolderFind.ResultID] {
        
        self.summary?.resultIDs ?? []
    }
    
    
    /// Builds the context menu for a file result.
    ///
    /// - Parameter file: The file result represented by the selected row.
    /// - Returns: The context menu content.
    @ViewBuilder private func contextMenu(for file: FolderFind.FileResult) -> some View {
        
        Button(String(localized: "Reveal in File Browser", table: "Document"), systemImage: "folder") {
            self.model.document.revealInFileBrowser(fileURL: file.fileURL)
        }
        
        Button(String(localized: "Show in Finder", table: "Document"), systemImage: "finder") {
            NSWorkspace.shared.activateFileViewerSelecting([file.fileURL])
        }
        
        Divider()
        
        Button(String(localized: "Open in New Window", table: "Document"), systemImage: "macwindow.badge.plus") {
            self.model.document.openInNewWindow(fileURL: file.fileURL)
        }
    }
}


private struct FolderFindControlView: View {
    
    var model: FolderFinder
    
    @State private var textFinderSettings: TextFinderSettings = .shared
    @State private var showsFileScopeSheet = false
    @State private var fileScope = FileScope()
    
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
                
                Menu {
                    Toggle(String(localized: "Include Hidden Files", table: "Document", comment: "toggle button label"), isOn: $includesHiddenFiles)
                    Toggle(String(localized: "Include Other File Types", table: "Document", comment: "toggle button label"), isOn: $includesOtherFileTypes)
                    
                    Divider()
                    
                    Button(String(localized: "File Scope…", table: "Document", comment: "menu item title")) {
                        self.showsFileScopeSheet = true
                    }
                } label: {
                    Label(String(localized: "Advanced options", table: "TextFind", comment: "accessibility label"), systemImage: "ellipsis")
                        .symbolVariant(.circle)
                        .labelStyle(.iconOnly)
                }
                .menuIndicator(.hidden)
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
                                fileScope: self.fileScope)
            }
            .onChange(of: self.textFinderSettings.findString) { _, newValue in
                self.model.findStringDidChange(to: newValue)
            }
        }
        .sheet(isPresented: $showsFileScopeSheet) {
            FolderFindFileScopeView(fileScope: self.fileScope) { fileScope in
                self.fileScope = fileScope
            }
            .scenePadding()
        }
    }
}


private struct FolderFindMetricsBarView: View {
    
    var state: FolderFinder.SearchState
    
    
    var body: some View {
        
        switch self.state {
            case .searching(let progress):
                TimelineView(.periodic(from: .now, by: 0.1)) { _ in
                    FolderFindMetricsMessageView(metrics: progress.snapshot)
                }
                
            case .finished(let summary):
                FolderFindMetricsMessageView(metrics: summary.metrics)
                
            case .idle, .failed:
                EmptyView()
        }
    }
}


private struct FolderFindMetricsMessageView: View {
    
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
    
    @State private var isExpanded = true
    
    
    var body: some View {
        
        DisclosureGroup(isExpanded: $isExpanded) {
            ForEach(self.file.matches) { match in
                Label {
                    Text(Self.highlightedLine(for: match, headOffset: 32))
                } icon: {
                    Image(.textSquareFill)
                        .symbolRenderingMode(.hierarchical)
                }
                .foregroundStyle(.secondary)
                .lineLimit(3)
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
            .draggable(item: FolderFindDraggedFile(id: .file(self.file.id), fileURL: self.file.fileURL))
        }
        .labelIconToTitleSpacing(4)
        .listRowSeparator(.hidden)
        .tag(FolderFind.ResultID.file(self.file.id))
    }
    
    
    /// The line text with the matched substring emphasized.
    private static func highlightedLine(for match: FolderFind.Match, headOffset: Int) -> AttributedString {
        
        var attributedLine = AttributedString(match.line)
        var rangeInLine = match.rangeInLine
        
        if let indentationRange = Self.leadingIndentationRange(in: match.line),
           rangeInLine.location >= indentationRange.length,
           let range = Range(indentationRange, in: attributedLine)
        {
            attributedLine.removeSubrange(range)
            rangeInLine.location -= indentationRange.length
        }
        
        guard let range = Range(rangeInLine, in: attributedLine) else {
            return attributedLine
        }
        
        attributedLine[range].inlinePresentationIntent = .stronglyEmphasized
        attributedLine[range].foregroundColor = .primary
        
        return attributedLine.truncatedHead(until: range.lowerBound, offset: headOffset)
    }
    
    
    /// Returns the range of the leading indentation in the given string.
    ///
    /// - Parameter string: The string to inspect.
    /// - Returns: The range of the leading indentation, or `nil` if the string does not start with indentation.
    private static func leadingIndentationRange(in string: String) -> NSRange? {
        
        guard
            let index = string.firstIndex(where: { !$0.isWhitespace }),
            index > string.startIndex
        else { return nil }
        
        return NSRange(string.startIndex..<index, in: string)
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
    var fileURL: URL
    
    
    /// The file URL string to transfer.
    private var fileURLString: String {
        
        self.fileURL.absoluteString
    }
    
    
    /// The file path to transfer as plain text.
    private var filePath: String {
        
        self.fileURL.path(percentEncoded: false)
    }
    
    
    /// The transfer representations of a dragged file result.
    static var transferRepresentation: some TransferRepresentation {
        
        DataRepresentation(exportedContentType: .url) { item in
            Data(item.fileURLString.utf8)
        }
        DataRepresentation(exportedContentType: .fileURL) { item in
            Data(item.fileURLString.utf8)
        }
        ProxyRepresentation(exporting: \.filePath)
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


private extension FolderFind.Summary {
    
    /// The result IDs in the summary.
    var resultIDs: [FolderFind.ResultID] {
        
        self.files.flatMap { file in
            [FolderFind.ResultID.file(file.id)] + file.matches.map { .match(fileID: file.id, matchID: $0.id) }
        }
    }
}


private extension FolderFind.Metrics {
    
    /// The localized summary message.
    var message: String {
        
        if self.skippedFileCount == 0 {
            String(localized: "FolderFind.Metrics.message",
                   defaultValue: "\(self.matchCount) matches in \(self.matchedFileCount) files",
                   table: "Document", comment: "folder find result summary")
        } else {
            String(localized: "FolderFind.Metrics.skipped.message",
                   defaultValue: "\(self.matchCount) matches in \(self.matchedFileCount) files, \(self.skippedFileCount) skipped",
                   table: "Document", comment: "folder find result summary with skipped file count")
        }
    }
}
