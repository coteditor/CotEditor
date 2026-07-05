//
//  FolderFinder.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-06-15.
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

import Foundation
import AppKit.NSTextStorage
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
        case searching(FolderFindProgress)
        case finished(FolderFind.Summary)
        case failed(FolderFinder.Error)
    }
    
    
    // MARK: Public Properties
    
    let document: DirectoryDocument
    
    private(set) var state: SearchState = .idle  { didSet { self.updateTextStorageObservation() } }
    private(set) var resultRevision = 0
    
    
    // MARK: Private Properties
    
    private var searchTask: Task<Void, Never>?
    private var selectionTask: Task<Void, Never>?
    private var textEditingObserver: (any NSObjectProtocol)?
    private var submittedFindString = ""
    
    
    // MARK: Lifecycle
    
    /// Initializes a folder find model.
    ///
    /// - Parameter document: The directory document whose folder is searched.
    init(document: DirectoryDocument) {
        
        self.document = document
    }
    
    
    isolated deinit {
        
        self.searchTask?.cancel()
        self.selectionTask?.cancel()
        self.textEditingObserver.map(NotificationCenter.default.removeObserver)
    }
    
    
    // MARK: Public Methods
    
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
    ///   - includesHiddenFiles: Whether hidden files should be searched.
    ///   - includesOtherFileTypes: Whether files that do not look like plain text should also be searched.
    ///   - fileScope: The file scope to search.
    func find(findString: String, usesRegularExpression: Bool, ignoresCase: Bool, includesHiddenFiles: Bool, includesOtherFileTypes: Bool = false, fileScope: FileScope = .init()) {
        
        self.searchTask?.cancel()
        self.selectionTask?.cancel()
        
        guard !findString.isEmpty else {
            self.submittedFindString = findString
            self.state = .idle
            self.resultRevision += 1
            return
        }
        
        guard let rootURL = self.document.fileURL else {
            self.state = .failed(.folderUnavailable)
            self.resultRevision += 1
            return
        }
        
        let mode = TextFind.Mode(usesRegularExpression: usesRegularExpression, ignoresCase: ignoresCase)
        let query = FolderFind.Query(findString: findString, mode: mode)
        
        self.submittedFindString = findString
        
        do {
            try query.validate()
        } catch {
            self.state = .failed(.invalidQuery(error))
            self.resultRevision += 1
            return
        }
        
        let options = FolderFind.Options(
            includesOtherFileTypes: includesOtherFileTypes,
            includesHiddenFiles: includesHiddenFiles,
            fileScope: fileScope,
            decodingOptions: .init(candidates: EncodingManager.shared.fileEncodingCandidates)
        )
        let syntaxMappingTable = SyntaxManager.shared.fileMappingTable
        let progress = FolderFindProgress(findString: findString)
        
        self.state = .searching(progress)
        self.resultRevision += 1
        
        self.searchTask = .detached(priority: .userInitiated) {
            do {
                let summary = try await FolderFind.find(in: rootURL, query: query, options: options, progress: progress) { candidate in
                    syntaxMappingTable.syntaxName(forFilename: candidate.fileURL.lastPathComponent) != nil
                }
                
                try Task.checkCancellation()
                
                await MainActor.run { [weak self] in
                    guard !Task.isCancelled else { return }
                    
                    self?.state = .finished(summary)
                    self?.resultRevision += 1
                }
                
            } catch is CancellationError {
                return
                
            } catch {
                let error = FolderFinder.Error.searchFailed(error.localizedDescription)
                
                await MainActor.run { [weak self] in
                    guard !Task.isCancelled else { return }
                    
                    self?.state = .failed(error)
                    self?.resultRevision += 1
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
            
            // ensure the newly swapped-in editor has its final visible rect before scrolling
            textView.window?.contentView?.layoutSubtreeIfNeeded()
            
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
    
    
    // MARK: Private Methods
    
    /// Starts or stops observing text editing according to the current search state.
    private func updateTextStorageObservation() {
        
        if case .finished = self.state {
            guard self.textEditingObserver == nil else { return }
            self.textEditingObserver = self.observeTextStorage()
        } else {
            self.textEditingObserver.map(NotificationCenter.default.removeObserver)
            self.textEditingObserver = nil
        }
    }
    
    
    /// Observes text editing in open documents.
    ///
    /// - Returns: The notification observer.
    private func observeTextStorage() -> any NSObjectProtocol {
        
        NotificationCenter.default.addObserver(forName: NSTextStorage.didProcessEditingNotification, object: nil, queue: .main) { [weak self] notification in
            let textStorage = notification.object as! NSTextStorage
            
            guard textStorage.editedMask.contains(.editedCharacters) else { return }
            
            MainActor.assumeIsolated {
                self?.documentTextDidChange(textStorage: textStorage)
            }
        }
    }
    
    
    /// Updates match ranges after the text of an open document changes.
    ///
    /// - Parameters:
    ///   - textStorage: The edited text storage.
    private func documentTextDidChange(textStorage: NSTextStorage) {
        
        guard
            case .finished(var summary) = self.state,
            let document = NSDocumentController.shared.documents
                .compactMap({ $0 as? Document })
                .first(where: { $0.textStorage === textStorage }),
            let fileURL = document.fileURL
        else { return }
        
        guard summary.updateMatchRanges(in: fileURL, editedRange: textStorage.editedRange, changeInLength: textStorage.changeInLength, length: textStorage.length) else { return }
        
        self.state = .finished(summary)
    }
}


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
