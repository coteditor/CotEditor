//
//  FolderTextSearchPanelController.swift
//  CotEditor
//
//  ---------------------------------------------------------------------------
//
//  © 2026 sdraeger
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

import AppKit
import Combine
import SwiftUI
import Defaults
import StringUtils
import TextFind
import URLUtils

@MainActor final class FolderTextSearchPanelController: NSWindowController {
    
    private let model: FolderTextSearchModel
    
    
    init(directoryDocument: DirectoryDocument) {
        
        let rootURL = directoryDocument.fileURL!
        let model = FolderTextSearchModel(rootURL: rootURL) { [weak directoryDocument] match in
            guard let directoryDocument else { return }
            
            Task {
                guard
                    await directoryDocument.openDocument(at: match.fileURL, asPlainText: true),
                    let document = directoryDocument.currentDocument as? Document,
                    let textView = document.textView,
                    textView.string.length >= match.range.upperBound
                else { return }
                
                textView.selectedRange = match.range
                textView.scrollRangeToVisible(match.range)
                textView.showFindIndicator(for: match.range)
                directoryDocument.fileBrowserViewController?.selectCurrentDocument()
            }
        }
        self.model = model
        
        let hostingController = NSHostingController(rootView: FolderTextSearchView(model: model))
        let window = NSPanel(contentViewController: hostingController)
        window.title = String(localized: "Search in Folder", table: "TextFind", comment: "window title")
        window.styleMask.insert([.closable, .miniaturizable, .resizable])
        window.collectionBehavior.insert(.fullScreenAuxiliary)
        window.isReleasedWhenClosed = false
        window.setContentSize(NSSize(width: 760, height: 460))
        
        super.init(window: window)
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
}


@MainActor final class FolderTextSearchModel: ObservableObject {
    
    @Published var findString: String
    @Published var usesRegularExpression: Bool {
        
        didSet { UserDefaults.standard[.findUsesRegularExpression] = self.usesRegularExpression }
    }
    @Published var ignoresCase: Bool {
        
        didSet { UserDefaults.standard[.findIgnoresCase] = self.ignoresCase }
    }
    @Published var includesHiddenFiles: Bool
    @Published var matches: [FolderTextSearch.Match] = []
    @Published var isSearching = false
    @Published var didSearch = false
    @Published var errorMessage: String?
    
    let rootURL: URL
    
    private var searchTask: Task<Void, Never>?
    private let openMatch: (FolderTextSearch.Match) -> Void
    
    
    init(rootURL: URL, openMatch: @escaping (FolderTextSearch.Match) -> Void) {
        
        let settings = TextFinderSettings.shared
        
        self.rootURL = rootURL
        self.findString = settings.findString
        self.usesRegularExpression = UserDefaults.standard[.findUsesRegularExpression]
        self.ignoresCase = UserDefaults.standard[.findIgnoresCase]
        self.includesHiddenFiles = UserDefaults.standard[.fileBrowserShowsHiddenFiles]
        self.openMatch = openMatch
    }
    
    
    deinit {
        
        self.searchTask?.cancel()
    }
    
    
    var resultMessage: String {
        
        guard self.didSearch else { return self.rootURL.lastPathComponent }
        
        return String(localized: "\(self.matches.count) matches in “\(self.rootURL.lastPathComponent)”",
                      table: "TextFind", comment: "folder search result count")
    }
    
    
    func search() {
        
        guard !self.findString.isEmpty else { return }
        
        self.searchTask?.cancel()
        self.isSearching = true
        self.didSearch = true
        self.errorMessage = nil
        self.matches = []
        
        let settings = TextFinderSettings.shared
        settings.findString = self.findString
        settings.noteFindHistory()
        
        let rootURL = self.rootURL
        let findString = self.findString
        let mode = settings.mode
        let includesHiddenFiles = self.includesHiddenFiles
        
        self.searchTask = Task {
            do {
                let matches = try await FolderTextSearch.matches(in: rootURL,
                                                                 findString: findString,
                                                                 mode: mode,
                                                                 options: FolderTextSearch.Options(includesHiddenFiles: includesHiddenFiles))
                guard !Task.isCancelled else { return }
                
                self.matches = matches
            } catch is CancellationError {
                return
            } catch {
                self.errorMessage = error.localizedDescription
            }
            
            self.isSearching = false
        }
    }
    
    
    func selectMatch(id: FolderTextSearch.Match.ID?) {
        
        guard let match = self.matches[id: id] else { return }
        
        self.openMatch(match)
    }
}


private struct FolderTextSearchView: View {
    
    @ObservedObject var model: FolderTextSearchModel
    
    @State private var selection: FolderTextSearch.Match.ID?
    
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                TextField(String(localized: "Find", table: "TextFind", comment: "placeholder"),
                          text: self.$model.findString)
                .textFieldStyle(.roundedBorder)
                .onSubmit { self.model.search() }
                
                ProgressView()
                    .controlSize(.small)
                    .opacity(self.model.isSearching ? 1 : 0)
                
                Button(String(localized: "Search", table: "TextFind", comment: "button label"), systemImage: "magnifyingglass") {
                    self.model.search()
                }
                .disabled(self.model.findString.isEmpty || self.model.isSearching)
            }
            
            HStack {
                Toggle(String(localized: "Regular Expression", table: "TextFind", comment: "toggle button label"),
                       isOn: self.$model.usesRegularExpression)
                Toggle(String(localized: "Ignore Case", table: "TextFind", comment: "toggle button label"),
                       isOn: self.$model.ignoresCase)
                Toggle(String(localized: "Hidden Files", table: "TextFind", comment: "toggle button label"),
                       isOn: self.$model.includesHiddenFiles)
                
                Spacer()
                
                Text(self.model.errorMessage ?? self.model.resultMessage)
                    .foregroundColor(self.model.errorMessage == nil ? .secondary : .red)
                    .lineLimit(1)
            }
            
            Table(self.model.matches, selection: self.$selection) {
                TableColumn(String(localized: "File", table: "TextFind", comment: "table column header")) { match in
                    Text(match.fileURL.path(relativeTo: self.model.rootURL))
                        .truncationMode(.middle)
                }
                .width(min: 140, ideal: 220)
                
                TableColumn(String(localized: "Line", table: "TextFind", comment: "table column header")) { match in
                    Text(match.lineNumber, format: .number)
                        .monospacedDigit()
                }
                .width(ideal: 48, max: 72)
                .alignment(.trailing)
                
                TableColumn(String(localized: "Matched Text", table: "TextFind", comment: "table column header")) { match in
                    Text(AttributedString(match.attributedLineString(offset: 16)))
                        .truncationMode(.tail)
                }
            }
            .environment(\.defaultMinListRowHeight, 20)
            .tableStyle(.bordered)
            .onChange(of: self.selection) { _, newValue in
                self.model.selectMatch(id: newValue)
            }
        }
        .padding(12)
        .frame(minWidth: 640, minHeight: 360)
    }
}


private extension FolderTextSearch.Match {
    
    func attributedLineString(offset: Int) -> NSAttributedString {
        
        let attributedString = NSMutableAttributedString(string: self.lineString)
        let inlineRange = NSRange(location: self.inlineLocation,
                                  length: min(self.range.length, max(attributedString.length - self.inlineLocation, 0)))
        if !inlineRange.isEmpty {
            attributedString.addAttribute(.backgroundColor, value: NSColor.textHighlighterColor, range: inlineRange)
        }
        
        return attributedString.truncatedHead(until: self.inlineLocation, offset: offset)
    }
}
