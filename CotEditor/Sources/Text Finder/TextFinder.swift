//
//  TextFinder.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2015-01-03.
//
//  ---------------------------------------------------------------------------
//
//  © 2015-2024 1024jp
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
import SwiftUI
import LineEnding
import TextFind
import ValueRange

extension NSAttributedString: @retroactive @unchecked Sendable { }


@MainActor @objc protocol TextFinderClient: AnyObject {
    
    func performEditorTextFinderAction(_ sender: Any?)
    func matchNext(_ sender: Any?)
    func matchPrevious(_ sender: Any?)
    func incrementalSearch(_ sender: Any?)
}


enum TextFindResult {
    
    case found(_ matches: [NSRange])
    case replaced(_ count: Int)
    
    
    /// The number of processed.
    var count: Int {
        
        switch self {
            case .found(let ranges):
                ranges.count
            case .replaced(let count):
                count
        }
    }
    
    
    /// Short result message for the user.
    var message: String {
        
        switch self {
            case .found:
                switch self.count {
                    case ...0:
                        String(localized: "Not found", table: "TextFind",
                               comment: "short result message for Find All")
                    default:
                        String(localized: "\(self.count) found", table: "TextFind",
                               comment: "short result message for Find All (%lld is number of found)")
                }
                
            case .replaced:
                switch self.count {
                    case ...0:
                        String(localized: "Not replaced", table: "TextFind",
                               comment: "short result message for Replace All")
                    default:
                        String(localized: "\(self.count) replaced", table: "TextFind",
                               comment: "short result message for Replace All (%lld is number of replaced)")
                }
        }
    }
}


struct TextFindAllResult {
    
    struct Match: Identifiable {
        
        let id = UUID()
        
        var range: NSRange
        var lineNumber: Int
        var inlineLocation: Int
        var attributedLineString: NSAttributedString
    }
    
    
    var findString: String = ""
    var matches: [Match] = []
}


// MARK: -

@MainActor final class TextFinder {
    
    enum Action: Int {
        
        // NSTextFinder.Action
        case showFindInterface = 1
        case nextMatch = 2
        case previousMatch = 3
        case replaceAll = 4
        case replace = 5
        case replaceAndFind = 6
        case setSearchString = 7
        case replaceAllInSelection = 8  // not supported
        case selectAll = 9
        case selectAllInSelection = 10  // not supported
        case hideFindInterface = 11     // not supported
        case showReplaceInterface = 12  // not supported
        case hideReplaceInterface = 13  // not supported
        
        // TextFinder.Action
        case findAll = 101
        case setReplaceString = 102
        case highlight = 103
        case unhighlight = 104
        case showMultipleReplaceInterface = 105
        case multipleReplace = 106
    }
    
    
    // MARK: Public Properties
    
    nonisolated static let didFindNotification = Notification.Name("didFindNotification")
    nonisolated static let didFindAllNotification = Notification.Name("didFindAllNotification")
    
    
    weak var client: NSTextView!
    
    private(set) var findResult: TextFindResult?
    private(set) var findAllResult: TextFindAllResult?
    
    
    // MARK: Private Properties
    
    private var findTask: Task<Void, any Error>?
    private var highlightObservationTask: Task<Void, Never>?
    
    
    // MARK: Public Methods
    
    /// Schedules an incremental search.
    func incrementalSearch() {
        
        self.findTask?.cancel()
        self.findTask = Task.detached(priority: .userInitiated) {
            try await Task.sleep(for: .seconds(0.2), tolerance: .seconds(0.05))  // debounce
            try await self.find(forward: true, isIncremental: true)
        }
    }
    
    
    /// Allows validation of the find action before performing.
    ///
    /// - Parameter action: The sender’s tag.
    /// - Returns: `true` if the operation is valid; otherwise `false`.
    func validateAction(_ action: Action) -> Bool {
        
        switch action {
            case .showFindInterface,
                 .showMultipleReplaceInterface:
                true
                
            case .nextMatch,
                 .previousMatch,
                 .setSearchString,
                 .selectAll,
                 .findAll,
                 .setReplaceString:
                self.client.isSelectable
                
            case .replaceAll,
                 .replace,
                 .replaceAndFind,
                 .multipleReplace:
                self.client.isEditable
                
            case .highlight,
                 .unhighlight:
                true
                
            case .selectAllInSelection,
                 .replaceAllInSelection,
                 .hideFindInterface,
                 .showReplaceInterface,
                 .hideReplaceInterface:
                // not supported in TextFinder
                false
        }
    }
    
    
    /// Performs the specified text finding action.
    ///
    /// - Parameter action: The text finding action.
    func performAction(_ action: Action, representedItem: Any? = nil) {
        
        guard self.validateAction(action) else { return }
        
        switch action {
            case .showFindInterface:
                FindPanelController.shared.showWindow(nil)
                
            case .nextMatch:
                self.nextMatch()
                
            case .previousMatch:
                self.previousMatch()
                
            case .replaceAll:
                self.replaceAll()
                
            case .replace:
                self.replace()
                
            case .replaceAndFind:
                self.replaceAndFind()
                
            case .setSearchString:
                self.setSearchString()
                
            case .selectAll:
                self.selectAll()
                
            case .replaceAllInSelection,
                 .selectAllInSelection,
                 .hideFindInterface,
                 .showReplaceInterface,
                 .hideReplaceInterface:
                // not supported by TextFinder
                assertionFailure()
                
            case .findAll:
                self.findAll()
                
            case .setReplaceString:
                self.setReplaceString()
                
            case .highlight:
                self.highlight()
                
            case .unhighlight:
                self.unhighlight()
                
            case .showMultipleReplaceInterface:
                MultipleReplacePanelController.shared.showWindow(nil)
                
            case .multipleReplace:
                guard let name = representedItem as? String else { return assertionFailure() }
                self.multiReplaceAll(name: name)
        }
    }
    
    
    // MARK: Private Actions
    
    /// Finds the next matched string.
    private func nextMatch() {
        
        self.findTask?.cancel()
        self.findTask = Task(priority: .userInitiated) {
            try await self.find(forward: true)
        }
    }
    
    
    /// Finds the previous matched string.
    private func previousMatch() {
        
        self.findTask?.cancel()
        self.findTask = Task(priority: .userInitiated) {
            try await self.find(forward: false)
        }
    }
    
    
    /// Selects all matched strings.
    private func selectAll() {
        
        guard let textFind = self.prepareTextFind() else { return }
        guard let matchedRanges = try? textFind.matches else { return }
        
        self.client.selectedRanges = matchedRanges as [NSValue]
        
        self.notify(result: .found(matchedRanges))
        TextFinderSettings.shared.noteFindHistory()
    }
    
    
    /// Finds all matched strings and shows results in a table.
    private func findAll() {
        
        Task {
            await self.findAll(showsList: true, actionName: String(localized: "Find All", table: "TextFind"))
        }
    }
    
    
    /// Highlights all matched strings.
    private func highlight() {
        
        Task {
            await self.findAll(showsList: false, actionName: String(localized: "Highlight All", table: "TextFind"))
        }
    }
    
    
    /// Removes all of current highlights in the frontmost textView.
    private func unhighlight() {
        
        self.client.unhighlight(nil)
    }
    
    
    /// Replaces matched string in selection with replacementString.
    private func replace() {
        
        if self.replaceSelected() {
            self.client.centerSelectionInVisibleArea(self)
        } else {
            NSSound.beep()
        }
        
        TextFinderSettings.shared.noteReplaceHistory()
    }
    
    
    /// Replaces matched string with replacementString and selects the next match.
    private func replaceAndFind() {
        
        self.replaceSelected()
        
        self.findTask?.cancel()
        self.findTask = Task(priority: .userInitiated) {
            try await self.find(forward: true)
        }
        
        TextFinderSettings.shared.noteReplaceHistory()
    }
    
    
    /// Replaces all matched strings with given string.
    private func replaceAll() {
        
        Task {
            await self.replaceAll()
        }
    }
    
    
    /// Performs multiple replacement with a specific replacement definition.
    ///
    /// - Parameter name: The name of the multiple replacement definition.
    private func multiReplaceAll(name: String) {
        
        guard let definition = try? ReplacementManager.shared.setting(name: name) else { return assertionFailure() }
        
        Task {
            try await self.client.replaceAll(definition, inSelection: TextFinderSettings.shared.inSelection)
        }
    }
    
    
    /// Sets the selected string to find field.
    private func setSearchString() {
        
        TextFinderSettings.shared.findString = self.client.selectedString
        TextFinderSettings.shared.usesRegularExpression = false  // auto-disable regex
    }
    
    
    /// Sets the selected string to replace field.
    private func setReplaceString() {
        
        TextFinderSettings.shared.replacementString = self.client.selectedString
    }
    
    
    // MARK: Private Methods
    
    /// Checks the Find action can be performed and alerts if needed.
    ///
    /// - Parameter presentsError: Whether shows error dialog on the find panel.
    /// - Returns: A TextFind object with the current state, or `nil` if not ready.
    private func prepareTextFind(presentsError: Bool = true) -> TextFind? {
        
        let client = self.client!
        
        // close previous error dialog if any exists
        FindPanelController.shared.window?.attachedSheet?.close()
        
        // apply the client's line ending to the find string
        let lineEnding = (client as? EditorTextView)?.lineEnding ?? .lf
        let findString = TextFinderSettings.shared.findString
            .replacingLineEndings(with: lineEnding)
        
        let string = client.string.immutable
        let mode = TextFinderSettings.shared.mode
        let inSelection = TextFinderSettings.shared.inSelection
        let selectedRanges = client.selectedRanges.map(\.rangeValue)
        
        do {
            return try TextFind(for: string, findString: findString, mode: mode, inSelection: inSelection, selectedRanges: selectedRanges)
            
        } catch {
            guard presentsError else { return nil }
            
            switch error {
                case .regularExpression, .emptyInSelectionSearch:
                    FindPanelController.shared.showWindow(self)
                    FindPanelController.shared.presentError(error, modalFor: FindPanelController.shared.window!, delegate: nil, didPresent: nil, contextInfo: nil)
                case .emptyFindString:
                    break
            }
            NSSound.beep()
            
            return nil
        }
    }
    
    
    /// Performs a single find.
    ///
    /// - Parameters:
    ///   - forward: The flag whether finds forward or backward.
    ///   - isIncremental: Whether is the incremental search.
    /// - Throws: `CancellationError`
    private func find(forward: Bool, isIncremental: Bool = false) async throws {
        
        assert(forward || !isIncremental)
        
        guard let textFind = self.prepareTextFind(presentsError: !isIncremental) else { return }
        
        let client = self.client!
        let wraps = TextFinderSettings.shared.isWrap
        
        // find in background thread
        let task = Task.detached(priority: .userInitiated) {
            let matches = try textFind.matches
            let result = textFind.find(in: matches, forward: forward, includingSelection: isIncremental, wraps: wraps)
            return (matches, result)
        }
        let (matches, result) = try await task.value
        
        // mark all matches
        if isIncremental, let layoutManager = client.layoutManager {
            layoutManager.groupTemporaryAttributesUpdate(in: client.string.range) {
                layoutManager.removeTemporaryAttribute(.backgroundColor, forCharacterRange: client.string.range)
                for range in matches {
                    layoutManager.addTemporaryAttribute(.backgroundColor, value: NSColor.unemphasizedSelectedTextBackgroundColor, forCharacterRange: range)
                }
            }
            
            // unmark either when the client view resigned the key window or when the Find panel closed
            self.highlightObservationTask?.cancel()
            self.highlightObservationTask = Task { [weak client] in
                for await _ in NotificationCenter.default.notifications(named: NSWindow.didResignKeyNotification).map(\.name) {
                    client?.unhighlight(nil)
                    break
                }
            }
        }
        
        // found feedback
        if let result {
            client.select(range: result.range)
            client.showFindIndicator(for: result.range)
            
            if result.wrapped {
                client.enclosingScrollView?.superview?.showHUD(symbol: .wrap(flipped: !forward))
                AccessibilityNotification.Announcement(String(localized: "Search wrapped.", table: "TextFind", comment: "Announced when the search restarted from the beginning.")).post()
            }
        } else if !isIncremental {
            client.enclosingScrollView?.superview?.showHUD(symbol: forward ? .reachBottom : .reachTop)
            NSSound.beep()
        }
        
        self.notify(result: .found(matches))
        if !isIncremental {
            TextFinderSettings.shared.noteFindHistory()
        }
    }
    
    
    /// Replaces a matched string in selection with replacementString.
    @discardableResult
    private func replaceSelected() -> Bool {
        
        guard let textFind = self.prepareTextFind() else { return false }
        
        let replacementString = TextFinderSettings.shared.replacementString
        
        guard let result = textFind.replace(with: replacementString) else { return false }
        
        // apply replacement to text view
        return self.client.replace(with: result.value, range: result.range,
                                   selectedRange: NSRange(location: result.range.location,
                                                          length: result.value.length),
                                   actionName: String(localized: "Replace", table: "TextFind"))
    }
    
    
    /// Finds all matched strings and applies the result to views.
    ///
    /// - Parameters:
    ///   - showsList: Whether shows the result view when finished.
    ///   - actionName: The name of the action to display in the progress sheet.
    private func findAll(showsList: Bool, actionName: String) async {
        
        guard let textFind = self.prepareTextFind() else { return }
        
        let client = self.client!
        client.isEditable = false
        defer { client.isEditable = true }
        
        let progress = FindProgress(scope: textFind.scopeRange)
        let task = Task.detached(priority: .userInitiated) {
            let highlightColors = NSColor.textHighlighterColor.decompose(into: textFind.numberOfCaptureGroups + 1)
            let lineCounter = LineCounter(string: textFind.string)
            
            var highlights: [ValueRange<NSColor>] = []
            var resultMatches: [TextFindAllResult.Match] = []  // not used if showsList is false
            
            textFind.findAll { (matches: [NSRange], stop) in
                guard progress.state != .cancelled else {
                    stop = true
                    return
                }
                
                // highlight
                highlights += matches.enumerated()
                    .filter { !$0.element.isEmpty }
                    .map { ValueRange(value: highlightColors[$0.offset], range: $0.element) }
                
                // build TextFindResult for table
                if showsList {
                    let matchedRange = matches[0]
                    
                    // build a highlighted line string for result table
                    let lineRange = lineCounter.lineContentsRange(for: matchedRange)
                    let lineString = (textFind.string as NSString).substring(with: lineRange)
                    let attrLineString = NSMutableAttributedString(string: lineString)
                    for (color, range) in zip(highlightColors, matches) where !range.isEmpty {
                        guard let inlineRange = range.shifted(by: -lineRange.location).intersection(attrLineString.range) else { continue }
                        attrLineString.addAttribute(.backgroundColor, value: color, range: inlineRange)
                    }
                    
                    let lineNumber = lineCounter.lineNumber(at: matchedRange.location)
                    let inlineLocation = matchedRange.location - lineRange.location
                    
                    resultMatches.append(.init(range: matchedRange, lineNumber: lineNumber, inlineLocation: inlineLocation, attributedLineString: attrLineString))
                }
                
                progress.updateCompletedUnit(to: matches[0].upperBound)
                progress.incrementCount()
            }
            
            return (highlights, resultMatches)
        }
        
        // setup progress sheet
        let indicatorView = FindProgressView(actionName, progress: progress, unit: .find)
        let indicator = NSHostingController(rootView: indicatorView)
        indicator.rootView.parent = indicator
        client.viewControllerForSheet?.presentAsSheet(indicator)
        
        // perform
        let (highlights, matches) = await task.value
        
        client.isEditable = true
        
        guard progress.state != .cancelled else { return }
        
        // highlight in client
        if let layoutManager = client.layoutManager {
            let wholeRange = textFind.string.nsRange
            layoutManager.groupTemporaryAttributesUpdate(in: wholeRange) {
                layoutManager.removeTemporaryAttribute(.backgroundColor, forCharacterRange: wholeRange)
                for highlight in highlights {
                    layoutManager.addTemporaryAttribute(.backgroundColor, value: highlight.value, forCharacterRange: highlight.range)
                }
            }
        }
        
        if highlights.isEmpty {
            NSSound.beep()
        }
        
        progress.finish()
        
        self.notify(result: .found(matches.map(\.range)))
        
        if showsList {
            self.findAllResult = TextFindAllResult(findString: textFind.findString, matches: matches)
            NotificationCenter.default.post(name: TextFinder.didFindAllNotification, object: self)
        }
        
        TextFinderSettings.shared.noteFindHistory()
    }
    
    
    /// Replaces all matched strings and applies the result to views.
    private func replaceAll() async {
        
        guard let textFind = self.prepareTextFind() else { return }
        
        let client = self.client!
        client.isEditable = false
        defer { client.isEditable = true }
        
        let replacementString = TextFinderSettings.shared.replacementString
        
        let progress = FindProgress(scope: textFind.scopeRange)
        let task = Task.detached(priority: .userInitiated) {
            textFind.replaceAll(with: replacementString) { (range, count, stop) in
                guard progress.state != .cancelled else {
                    stop = true
                    return
                }
                
                progress.updateCompletedUnit(to: range.upperBound)
                progress.incrementCount(by: count)
            }
        }
        
        // setup progress sheet
        let indicatorView = FindProgressView(String(localized: "Replace All", table: "TextFind"), progress: progress, unit: .replacement)
        let indicator = NSHostingController(rootView: indicatorView)
        indicator.rootView.parent = indicator
        client.viewControllerForSheet?.presentAsSheet(indicator)
        
        // perform
        let (replacementItems, selectedRanges) = await task.value
        
        client.isEditable = true
        
        guard progress.state != .cancelled else { return }
        
        if !replacementItems.isEmpty {
            // apply found strings to the text view
            client.replace(with: replacementItems.map(\.value), ranges: replacementItems.map(\.range), selectedRanges: selectedRanges,
                           actionName: String(localized: "Replace All", table: "TextFind"))
        } else {
            NSSound.beep()
        }
        
        progress.finish()
        
        self.notify(result: .replaced(progress.count))
        TextFinderSettings.shared.noteReplaceHistory()
    }
    
    
    /// Notifies the find/replacement result to the user.
    ///
    /// - Parameters:
    ///   - result: The result of the process.
    private func notify(result: TextFindResult) {
        
        self.findResult = result
        NotificationCenter.default.post(name: TextFinder.didFindNotification, object: self)
        
        AccessibilityNotification.Announcement(result.message).post()
    }
}


// MARK: -

extension NSTextView {
    
    @IBAction final func unhighlight(_ sender: Any?) {
        
        self.layoutManager?.removeTemporaryAttribute(.backgroundColor, forCharacterRange: self.string.range)
    }
}
