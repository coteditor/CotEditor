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
//  © 2015-2026 1024jp
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
import StringUtils
import TextFind
import ValueRange

@MainActor @objc protocol TextFinderClient: AnyObject {
    
    func performEditorTextFinderAction(_ sender: Any?)
    func matchNext(_ sender: Any?)
    func matchPrevious(_ sender: Any?)
    func incrementalSearch(_ sender: Any?)
}


struct FindResult {
    
    var action: TextFind.Action
    var count: Int
}


struct FindAllMatch: Identifiable {
    
    let id = UUID()
    
    var range: NSRange
    var lineNumber: Int
    var inlineLocation: Int
    nonisolated(unsafe) var attributedLineString: NSAttributedString
}


// MARK: -

@MainActor final class TextFinder {
    
    // MARK: Notification Messages
    
    struct DidFindMessage: NotificationCenter.MainActorMessage {
        
        typealias Subject = TextFinder
        
        static let name = Notification.Name("TextFinderDidFind")
        
        var result: FindResult
    }
    
    
    struct DidFindAllMessage: NotificationCenter.MainActorMessage {
        
        typealias Subject = TextFinder
        
        static let name = Notification.Name("TextFinderDidFindAll")
        
        var findString: String = ""
        var matches: [FindAllMatch] = []
        weak var client: NSTextView?
    }
    
    
    // MARK: Enums
    
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
    
    let settings: TextFinderSettings = .shared
    
    weak var client: NSTextView!
    
    
    // MARK: Private Properties
    
    private var findTask: Task<Void, any Error>?
    private var highlightObservationTask: Task<Void, Never>?
    
    
    // MARK: Public Methods
    
    /// Schedules an incremental search.
    func incrementalSearch() {
        
        self.findTask?.cancel()
        self.findTask = Task(priority: .userInitiated) {
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
        
        self.notify(.find, count: matchedRanges.count)
        self.settings.noteFindHistory()
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
        
        self.settings.noteReplaceHistory()
    }
    
    
    /// Replaces matched string with replacementString and selects the next match.
    private func replaceAndFind() {
        
        self.replaceSelected()
        
        self.findTask?.cancel()
        self.findTask = Task(priority: .userInitiated) {
            try await self.find(forward: true)
        }
        
        self.settings.noteReplaceHistory()
    }
    
    
    /// Replaces all matched strings with given string.
    private func replaceAll() {
        
        Task {
            await self.replaceAll()
        }
    }
    
    
    /// Performs multiple replacement with a specific replacement definition.
    ///
    /// - Parameter name: The name of the Multiple Replace definition.
    private func multiReplaceAll(name: String) {
        
        guard let definition = try? ReplacementManager.shared.setting(name: name) else { return assertionFailure() }
        
        Task {
            try await self.client.replaceAll(definition, inSelection: self.settings.inSelection)
        }
    }
    
    
    /// Sets the selected string to find field.
    private func setSearchString() {
        
        self.settings.findString = self.client.selectedString
        self.settings.usesRegularExpression = false  // auto-disable regex
    }
    
    
    /// Sets the selected string to replace field.
    private func setReplaceString() {
        
        self.settings.replacementString = self.client.selectedString
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
        let findString = self.settings.findString
            .replacingLineEndings(with: lineEnding)
        
        let string = client.string.immutable
        let mode = self.settings.mode
        let inSelection = self.settings.inSelection
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
        let wraps = self.settings.isWrap
        
        // find in background thread
        let task = Task.detached(priority: .userInitiated) {
            let matches = try textFind.matches
            let result = textFind.find(in: matches, forward: forward, includingSelection: isIncremental, wraps: wraps)
            return (matches, result)
        }
        let (matches, result) = try await withTaskCancellationHandler {
            try await task.value
        } onCancel: {
            task.cancel()
        }
        
        // mark all matches
        if isIncremental {
            client.updateBackgroundColor(.unemphasizedSelectedTextBackgroundColor, ranges: matches)
            
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
        
        self.notify(.find, count: matches.count)
        if !isIncremental {
            self.settings.noteFindHistory()
        }
    }
    
    
    /// Replaces a matched string in selection with replacementString.
    @discardableResult private func replaceSelected() -> Bool {
        
        guard let textFind = self.prepareTextFind() else { return false }
        
        let replacementString = self.settings.replacementString
        
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
            var resultMatches: [FindAllMatch] = []  // not used if showsList is false
            
            textFind.findAll { matches, stop in
                guard progress.state != .cancelled else {
                    stop = true
                    return
                }
                
                // highlight
                highlights += matches.enumerated()
                    .filter { !$0.element.isEmpty }
                    .map { ValueRange(value: highlightColors[$0.offset], range: $0.element) }
                
                // build find result for table
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
        let indicatorView = FindProgressView(actionName, progress: progress, action: .find)
        let indicator = NSHostingController(rootView: indicatorView)
        indicator.rootView.dismiss = { indicator.dismiss(nil) }
        client.viewControllerForSheet?.presentAsSheet(indicator)
        
        // perform
        let (highlights, matches) = await task.value
        
        client.isEditable = true
        
        guard progress.state != .cancelled else { return }
        
        client.updateBackgroundColors(highlights)
        
        if highlights.isEmpty {
            NSSound.beep()
        }
        
        progress.finish()
        
        self.notify(.find, count: matches.count)
        
        if showsList {
            let info: [AnyHashable: Any] = ["findString": textFind.findString, "matches": matches, "client": client]
            NotificationCenter.default.post(name: DidFindAllMessage.name, object: self, userInfo: info)
        }
        
        self.settings.noteFindHistory()
    }
    
    
    /// Replaces all matched strings and applies the result to views.
    private func replaceAll() async {
        
        guard let textFind = self.prepareTextFind() else { return }
        
        let client = self.client!
        client.isEditable = false
        defer { client.isEditable = true }
        
        let replacementString = self.settings.replacementString
        
        let progress = FindProgress(scope: textFind.scopeRange)
        let task = Task.detached(priority: .userInitiated) {
            textFind.replaceAll(with: replacementString) { range, count, stop in
                guard progress.state != .cancelled else {
                    stop = true
                    return
                }
                
                progress.updateCompletedUnit(to: range.upperBound)
                progress.incrementCount(by: count)
            }
        }
        
        // setup progress sheet
        let indicatorView = FindProgressView(String(localized: "Replace All", table: "TextFind"), progress: progress, action: .replace)
        let indicator = NSHostingController(rootView: indicatorView)
        indicator.rootView.dismiss = { indicator.dismiss(nil) }
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
        
        self.notify(.replace, count: progress.count)
        self.settings.noteReplaceHistory()
    }
    
    
    /// Notifies the find/replacement result to the user.
    ///
    /// - Parameters:
    ///   - action: The find action type.
    ///   - count: The number o the items proceeded.
    private func notify(_ action: TextFind.Action, count: Int) {
        
        let result = FindResult(action: action, count: count)
        
        NotificationCenter.default.post(name: DidFindMessage.name, object: self, userInfo: ["result": result])
        AccessibilityNotification.Announcement(result.message).post()
    }
}


extension FindResult {
    
    /// The short result message for the user interface.
    var message: String {
        
        switch self.action {
            case .find:
                String(localized: "FindResult.find.message", defaultValue: "\(self.count) matches", table: "TextFind",
                       comment: "short result message for Find All (%lld is number of found)")
            case .replace:
                String(localized: "FindResult.replace.message", defaultValue: "\(self.count) replaced", table: "TextFind",
                       comment: "short result message for Replace All (%lld is number of replaced)")
        }
    }
}
