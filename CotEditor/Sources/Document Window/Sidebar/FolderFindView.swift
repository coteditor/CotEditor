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
import Defaults
import FileEncoding
import FolderFind
import SyntaxFormat
import TextFind

@MainActor @Observable final class FolderFinder {
    
    enum Error: Swift.Error, Equatable, Sendable {
        
        case folderUnavailable
        case invalidQuery(TextFind.Error)
        case searchFailed(String)
    }
    
    
    enum SearchState: Equatable {
        
        case idle
        case searching
        case finished(FolderFind.Summary)
        case failed(Error)
    }
    
    
    let document: DirectoryDocument
    
    private(set) var state: SearchState = .idle
    
    private var searchTask: Task<Void, Never>?
    private var selectionTask: Task<Void, Never>?
    private var submittedFindString = ""
    
    
    /// Initializes a folder find model.
    ///
    /// - Parameter document: The directory document whose folder is searched.
    init(document: DirectoryDocument) {
        
        self.document = document
    }
    
    
    isolated deinit {
        
        self.searchTask?.cancel()
        self.selectionTask?.cancel()
    }
    
    
    /// Updates the search state after the find string changes.
    ///
    /// - Parameter findString: The new find string.
    func findStringDidChange(to findString: String) {
        
        guard findString != self.submittedFindString else { return }
        
        self.searchTask?.cancel()
        self.selectionTask?.cancel()
        if case .searching = self.state {
            self.state = .idle
        }
    }
    
    
    /// Searches files in the directory document.
    ///
    /// - Parameters:
    ///   - findString: The string to find.
    ///   - usesRegularExpression: Whether the search string should be treated as a regular expression.
    ///   - ignoresCase: Whether character case should be ignored.
    func find(findString: String, usesRegularExpression: Bool, ignoresCase: Bool) {
        
        self.searchTask?.cancel()
        self.selectionTask?.cancel()
        
        guard !findString.isEmpty else {
            self.submittedFindString = findString
            self.state = .idle
            return
        }
        
        guard let rootURL = self.document.fileURL else {
            self.state = .failed(.folderUnavailable)
            return
        }
        
        let mode = TextFind.Mode(usesRegularExpression: usesRegularExpression, ignoresCase: ignoresCase)
        let query = FolderFind.Query(findString: findString, mode: mode)
        
        self.submittedFindString = findString
        
        do {
            try query.validate()
        } catch {
            self.state = .failed(.invalidQuery(error))
            return
        }
        
        let options = FolderFind.Options(
            decodingOptions: .init(candidates: EncodingManager.shared.fileEncodingCandidates,
                                   considersDeclaration: UserDefaults.standard[.referToEncodingTag])
        )
        let syntaxMappingTable = SyntaxManager.shared.fileMappingTable
        
        self.state = .searching
        
        self.searchTask = .detached(priority: .userInitiated) {
            do {
                let summary = try await FolderFind.find(in: rootURL, query: query, options: options) { candidate in
                    FolderFind.isSearchableText(candidate) ||
                    syntaxMappingTable.syntaxName(forFilename: candidate.fileURL.lastPathComponent) != nil
                }
                
                try Task.checkCancellation()
                
                await MainActor.run { [weak self] in
                    guard self?.submittedFindString == findString else { return }
                    
                    self?.state = .finished(summary)
                }
                
            } catch is CancellationError {
                return
                
            } catch {
                let error = FolderFinder.Error.searchFailed(error.localizedDescription)
                
                await MainActor.run { [weak self] in
                    guard self?.submittedFindString == findString else { return }
                    
                    self?.state = .failed(error)
                }
            }
        }
    }
    
    
    /// Opens the file for the selected result and selects the matched range if supplied.
    ///
    /// - Parameters:
    ///   - fileURL: The file URL to open.
    ///   - range: The matched character range to select.
    func selectResult(fileURL: URL, range: NSRange?) {
        
        self.selectionTask?.cancel()
        self.selectionTask = Task { @MainActor in
            guard
                await self.document.openDocument(at: fileURL),
                !Task.isCancelled
            else { return }
            
            guard
                let range,
                let document = self.document.currentDocument as? Document,
                let textView = document.textView,
                range.upperBound <= textView.string.utf16.count
            else { return }
            
            textView.selectedRange = range
            textView.scrollRangeToVisible(range)
            textView.showFindIndicator(for: range)
        }
    }
    
    
    /// Removes the selected result from the current search results.
    ///
    /// - Parameter id: The result ID to remove.
    func removeResult(for id: FolderFind.ResultID) {
        
        guard case .finished(var summary) = self.state else { return }
        
        summary.removeResult(for: id)
        self.selectionTask?.cancel()
        self.selectionTask = nil
        self.state = .finished(summary)
    }
}


struct FolderFindView: View {
   
    @Bindable var model: FolderFinder
    
    @State private var textFinderSettings: TextFinderSettings = .shared
    
    @AppStorage(.folderFindUsesRegularExpression) private var usesRegularExpression: Bool
    @AppStorage(.folderFindIgnoresCase) private var ignoresCase: Bool
    
    
    var body: some View {
    
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                SearchField(text: $textFinderSettings.findString,
                            placeholder: String(localized: "Search in Folder", table: "Document", comment: "placeholder"))
                    .autosaveName("FolderSearch")
                    .onSubmit { findString in
                        self.model.find(findString: findString,
                                        usesRegularExpression: self.usesRegularExpression,
                                        ignoresCase: self.ignoresCase)
                    }
                    .onChange(of: self.textFinderSettings.findString) { _, newValue in
                        self.model.findStringDidChange(to: newValue)
                    }
                
                HStack(spacing: 12) {
                    Toggle(String(localized: "Regular Expression", table: "TextFind", comment: "toggle button label"), isOn: $usesRegularExpression)
                        .help(String(localized: "Select to search with regular expression.", table: "TextFind", comment: "tooltip"))
                    Toggle(String(localized: "Ignore Case", table: "TextFind", comment: "toggle button label"), isOn: $ignoresCase)
                        .help(String(localized: "Select to ignore character case on search.", table: "TextFind", comment: "tooltip"))
                }
                .controlSize(.small)
                .fixedSize()
            }
            .padding(10)
            
            Divider()
            
            FolderFindResultView(model: self.model)
        }
        .accessibilityLabel(SidebarPane.find.label)
    }
}


private struct FolderFindResultView: View {
    
    var model: FolderFinder
    
    
    var body: some View {
        
        switch self.model.state {
            case .idle:
                Spacer()
                
            case .searching:
                ProgressView(String(localized: "FolderFind.SearchState.searching.label",
                                    defaultValue: "Searching in folder…", table: "Document"))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .controlSize(.small)
                
            case .finished(let summary) where summary.matchCount == 0:
                UnavailableView(title: String(localized: "FolderFind.SearchState.finished.zero.label",
                                              defaultValue: "No Results", table: "Document"),
                                systemName: "magnifyingglass",
                                description: String(localized: "FolderFind.SearchState.finished.zero.description",
                                                    defaultValue: "No matches for “\(summary.findString)” were found.",
                                                    table: "Document"))
                    .controlSize(.small)
                
            case .finished(let summary):
                FolderFindSummaryView(summary: summary, model: self.model)
                
            case .failed(let error):
                UnavailableView(title: String(localized: "FolderFind.SearchState.failed.label",
                                              defaultValue: "Search Failed", table: "Document"),
                                systemName: "exclamationmark.triangle",
                                description: error.localizedDescription)
                    .controlSize(.small)
        }
    }
}


private struct FolderFindSummaryView: View {
    
    var summary: FolderFind.Summary
    var model: FolderFinder
    
    @Namespace private var namespace
    
    @State private var selection: Set<FolderFind.ResultID> = []
    @State private var expandedFileURLs: Set<URL>
    
    
    /// Initializes a folder find summary view.
    ///
    /// - Parameters:
    ///   - summary: The search summary to display.
    ///   - model: The folder find model.
    init(summary: FolderFind.Summary, model: FolderFinder) {
        
        self.summary = summary
        self.model = model
        self._expandedFileURLs = State(initialValue: Set(summary.files.map(\.id)))
    }
    
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 0) {
            Text(self.summary.message)
                .foregroundStyle(.secondary)
                .controlSize(.small)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
            
            Divider()
            
            List(selection: $selection) {
                ForEach(self.summary.files) { file in
                    DisclosureGroup(isExpanded: $expandedFileURLs.contains(file.id)) {
                        ForEach(file.matches) { match in
                            FolderFindMatchView(match: match)
                                .tag(FolderFind.ResultID.match(fileID: file.id, matchID: match.id))
                        }
                    } label: {
                        FolderFindFileResultView(file: file)
                            .draggable(FolderFindDraggedFile.self,
                                       item: FolderFindDraggedFile(id: .file(file.id), fileURL: file.fileURL),
                                       containerNamespace: self.namespace)
                    }
                    .listRowSeparator(.hidden)
                    .tag(FolderFind.ResultID.file(file.id))
                }
            }
            .scrollContentBackground(.hidden)
            .contextMenu(forSelectionType: FolderFind.ResultID.self) { selections in
                if selections.count == 1, let selection = selections.first, let result = self.summary.result(for: selection) {
                    FolderFindResultContextMenu(file: result.file, model: self.model)
                }
            }
            .dragContainerSelection(Array(self.selection), containerNamespace: self.namespace)
            .dragPreviewsFormation(.list)
            .onChange(of: self.summary) { _, newValue in
                self.selection.removeAll()
                self.expandedFileURLs = Set(newValue.files.map(\.id))
            }
            .onChange(of: self.selection) { _, newValue in
                guard
                    newValue.count == 1,
                    let selection = newValue.first,
                    let result = self.summary.result(for: selection)
                else { return }
                
                self.model.selectResult(fileURL: result.file.fileURL, range: result.match?.range)
            }
            .onDeleteCommand {
                guard !self.selection.isEmpty else { return }
                
                let selection = self.selection
                self.selection = []
                for resultID in selection {
                    self.model.removeResult(for: resultID)
                }
            }
        }
    }
}


private struct FolderFindResultContextMenu: View {
    
    var file: FolderFind.FileResult
    var model: FolderFinder
    
    
    var body: some View {
        
        Button(String(localized: "Reveal in File Browser", table: "Document", comment: "menu item label"),
               systemImage: "folder") {
            self.model.document.revealInFileBrowser(fileURL: self.file.fileURL)
        }
        
        Button(String(localized: "Show in Finder", table: "Document", comment: "menu item label"),
               systemImage: "finder") {
            NSWorkspace.shared.activateFileViewerSelecting([self.file.fileURL])
        }
        
        Divider()
        
        Button(String(localized: "Open in New Window", table: "Document", comment: "menu item label"),
               systemImage: "macwindow.badge.plus") {
            self.model.document.openInNewWindow(fileURL: self.file.fileURL)
        }
    }
}


private struct FolderFindDraggedFile: Transferable, Identifiable {
    
    var id: FolderFind.ResultID
    var fileURL: URL
    
    
    /// The transfer representations of a dragged file result.
    static var transferRepresentation: some TransferRepresentation {
        
        ProxyRepresentation(exporting: \.fileURL)
    }
}


private struct FolderFindFileResultView: View {
    
    var file: FolderFind.FileResult
    
    
    var body: some View {
        
        Label {
            HStack(spacing: 4) {
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
            .lineLimit(1)
        } icon: {
            Image(systemName: "doc.text")
        }
    }
}


private struct FolderFindMatchView: View {
    
    var match: FolderFind.Match
    
    
    var body: some View {
        
        Text(self.highlightedLine)
            .foregroundStyle(.secondary)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
    }
    
    
    /// The line text with the matched substring emphasized.
    private var highlightedLine: AttributedString {
        
        var attributedLine = AttributedString(self.match.line)
        
        guard let range = Range(self.match.rangeInLine, in: attributedLine) else {
            return attributedLine
        }
        
        attributedLine[range].inlinePresentationIntent = .stronglyEmphasized
        attributedLine[range].foregroundColor = .primary
        
        return attributedLine
    }
}


private struct UnavailableView: View {
    
    var title: String
    var systemName: String
    var description: String
    
    
    var body: some View {
        
        ContentUnavailableView {
            Label {
                Text(self.title)
                    .font(.system(size: 16))
                    .fontWeight(.medium)
            } icon: {
                Image(systemName: self.systemName)
            }
        } description: {
            Text(self.description)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}


// MARK: Private Extensions

private extension TextFind.Mode {
    
    /// Initializes a text find mode for the given options.
    ///
    /// - Parameters:
    ///   - usesRegularExpression: Whether the search string should be treated as a regular expression.
    ///   - ignoresCase: Whether character case should be ignored.
    init(usesRegularExpression: Bool, ignoresCase: Bool) {
        
        self = if usesRegularExpression {
            .regularExpression(options: ignoresCase ? .caseInsensitive : [], unescapesReplacement: false)
        } else {
            .textual(options: ignoresCase ? .caseInsensitive : [], fullWord: false)
        }
    }
}


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
    
    /// The localized summary message.
    var message: String {
        
        if self.skippedFileCount == 0 {
            String(localized: "FolderFind.Summary.message",
                   defaultValue: "\(self.matchCount) matches in \(self.matchedFileCount) files",
                   table: "Document", comment: "folder find result summary")
        } else {
            String(localized: "FolderFind.Summary.skipped.message",
                   defaultValue: "\(self.matchCount) matches in \(self.matchedFileCount) files, \(self.skippedFileCount) skipped",
                   table: "Document", comment: "folder find result summary with skipped file count")
        }
    }
}
