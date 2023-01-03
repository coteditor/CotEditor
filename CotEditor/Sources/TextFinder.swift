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
//  © 2015-2023 1024jp
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

import Combine
import Cocoa
import SwiftUI

@objc protocol TextFinderClientProvider: AnyObject {
    
    func textFinderClient() -> NSTextView?
}


enum TextFindResult {
    
    case found(_ matches: [NSRange])
    case replaced(_ count: Int)
    
    
    /// The number of processed.
    var count: Int {
        
        switch self {
            case .found(let ranges):
                return ranges.count
            case .replaced(let count):
                return count
        }
    }
    
    
    /// Short result message for user.
    var message: String {
        
        switch self {
            case .found:
                switch self.count {
                    case ...0:
                        return String(localized: "Not found")
                    default:
                        return String(localized: "\(self.count) found")
                }
                
            case .replaced:
                switch self.count {
                    case ...0:
                        return String(localized: "Not replaced")
                    default:
                        return String(localized: "\(self.count) replaced")
                }
        }
    }
}



struct TextFindAllResult {
    
    struct Match {
        
        var range: NSRange
        var lineNumber: Int
        var attributedLineString: NSAttributedString
        var inlineRange: NSRange
    }
    
    
    var findString: String
    var matches: [Match]
    weak var textView: NSTextView?
}



// MARK: -

final class TextFinder {
    
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
    }
    
    
    // MARK: Public Properties
    
    static let shared = TextFinder()
    
    @Published private(set) var result: TextFindResult?
    let didFindAll: PassthroughSubject<TextFindAllResult, Never> = .init()
    

    // MARK: Private Properties
    
    private var findTask: Task<Void, any Error>?
    private var resultAvailabilityObserver: AnyCancellable?
    private var highlightObserver: AnyCancellable?
    
    
    
    // MARK: -
    // MARK: UI Validations
    
    /// Allows validation of the find action before performing.
    ///
    /// - Parameter action: The sender’s tag.
    /// - Returns: `true` if the operation is valid; otherwise `false`.
    func validateAction(_ action: Action) -> Bool {
        
        switch action {
            case .showFindInterface,
                 .showMultipleReplaceInterface:
                return true
                
            case .nextMatch,
                 .previousMatch,
                 .setSearchString,
                 .selectAll,
                 .findAll,
                 .setReplaceString:
                return self.client?.isSelectable == true
                
            case .replaceAll,
                 .replace,
                 .replaceAndFind:
                return self.client?.isEditable == true &&
                       self.client?.window?.attachedSheet == nil
                
            case .highlight,
                 .unhighlight:
                return self.client != nil
                
            case .selectAllInSelection,
                 .replaceAllInSelection,
                 .hideFindInterface,
                 .showReplaceInterface,
                 .hideReplaceInterface:
                // not supported in TextFinder
                return false
        }
    }
    
    
    
    // MARK: Public Methods
    
    /// Target text view.
    var client: NSTextView? {
        
        guard let provider = NSApp.target(forAction: #selector(TextFinderClientProvider.textFinderClient)) as? TextFinderClientProvider else { return nil }
        
        return provider.textFinderClient()
    }
    
    
    /// Schedule incremental search.
    func incrementalSearch() {
        
        self.findTask?.cancel()
        self.findTask = Task.detached(priority: .userInitiated) {
            // debounce
            try await Task.sleep(nanoseconds: 200_000_000)  // 200 milliseconds
            
            try await self.find(forward: true, isIncremental: true)
        }
    }
    
    
    /// Performs the specified text finding action.
    ///
    /// - Parameter action: The text finding action.
    @MainActor func performAction(_ action: Action) {
        
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
                self.selectAllMatches()
                
            case .replaceAllInSelection,
                 .selectAllInSelection,
                 .hideFindInterface,
                 .showReplaceInterface,
                 .hideReplaceInterface:
                // not supported in TextFinder
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
        }
    }
    
    
    
    // MARK: Private Actions
    
    /// Find next matched string.
    @MainActor private func nextMatch() {
        
        self.findTask?.cancel()
        self.findTask = Task(priority: .userInitiated) {
            try await self.find(forward: true)
        }
    }
    
    
    /// Find previous matched string.
    @MainActor private func previousMatch() {
        
        self.findTask?.cancel()
        self.findTask = Task(priority: .userInitiated) {
            try await self.find(forward: false)
        }
    }
    
    
    /// Select all matched strings.
    @MainActor private func selectAllMatches() {
        
        guard
            let textView = self.client,
            let textFind = self.prepareTextFind(for: textView)
        else { return NSSound.beep() }
        
        guard let matchedRanges = try? textFind.matches else { return }
        
        textView.selectedRanges = matchedRanges as [NSValue]
        
        self.notifyResult(.found(matchedRanges), textView: textView)
        TextFinderSettings.shared.noteFindHistory()
    }
    
    
    /// Find all matched strings and show results in a table.
    @MainActor private func findAll() {
        
        Task {
            await self.findAll(showsList: true, actionName: "Find All")
        }
    }
    
    
    /// Highlight all matched strings.
    @MainActor private func highlight() {
        
        Task {
            await self.findAll(showsList: false, actionName: "Highlight All")
        }
    }
    
    
    /// Remove all of current highlights in the frontmost textView.
    @MainActor private func unhighlight() {
        
        self.client?.unhighlight(nil)
    }
    
    
    /// Replace matched string in selection with replacementString.
    @MainActor private func replace() {
        
        if self.replaceSelected() {
            self.client?.centerSelectionInVisibleArea(self)
        } else {
            NSSound.beep()
        }
        
        TextFinderSettings.shared.noteReplaceHistory()
    }
    
    
    /// Replace matched string with replacementString and select the next match.
    @MainActor private func replaceAndFind() {
        
        self.replaceSelected()
        
        self.findTask?.cancel()
        self.findTask = Task(priority: .userInitiated) {
            try await self.find(forward: true)
        }
        
        TextFinderSettings.shared.noteReplaceHistory()
    }
    
    
    /// Replace all matched strings with given string.
    @MainActor private func replaceAll() {
        
        Task {
            await self.replaceAll()
        }
    }
    
    
    /// Set selected string to find field.
    @MainActor private func setSearchString() {
        
        guard let client = self.client else { return }
        
        TextFinderSettings.shared.findString = client.selectedString
        TextFinderSettings.shared.usesRegularExpression = false  // auto-disable regex
    }
    
    
    /// Set selected string to replace field.
    @MainActor private func setReplaceString() {
        
        guard let client = self.client else { return }
        
        TextFinderSettings.shared.replacementString = client.selectedString
    }
    
    
    
    // MARK: Private Methods
    
    /// Check Find can be performed and alert if needed.
    ///
    /// - Parameters:
    ///   - client: The client view where perform action.
    /// - Returns: The target textView and a TextFind object.
    @MainActor private func prepareTextFind(for client: NSTextView) -> TextFind? {
        
        guard FindPanelController.shared.window?.attachedSheet == nil else {
            FindPanelController.shared.showWindow(self)
            return nil
        }
        
        // apply the client's line ending to the find string
        let lineEnding = (client as? EditorTextView)?.lineEnding ?? .lf
        let findString = TextFinderSettings.shared.findString
            .replacingLineEndings(with: lineEnding)
        
        let string = client.string.immutable
        let mode = TextFinderSettings.shared.mode
        let inSelection = TextFinderSettings.shared.inSelection
        
        do {
            return try TextFind(for: string, findString: findString, mode: mode, inSelection: inSelection, selectedRanges: client.selectedRanges.map(\.rangeValue))
            
        } catch let error as TextFind.Error {
            switch error {
                case .regularExpression, .emptyInSelectionSearch:
                    FindPanelController.shared.showWindow(self)
                    FindPanelController.shared.presentError(error, modalFor: FindPanelController.shared.window!, delegate: nil, didPresent: nil, contextInfo: nil)
                case .emptyFindString:
                    break
            }
            return nil
            
        } catch {
            assertionFailure(error.localizedDescription)
            return nil
        }
    }
    
    
    /// Perform single find.
    ///
    /// - Parameters:
    ///   - forward: The flag whether finds forward or backward.
    ///   - isIncremental: Whether is the incremental search.
    /// - Throws: `CancellationError`
    @MainActor private func find(forward: Bool, isIncremental: Bool = false) async throws {
        
        assert(forward || !isIncremental)
        
        guard
            let textView = self.client,
            let textFind = self.prepareTextFind(for: textView)
        else { return NSSound.beep() }
        
        // find in background thread
        let result = try await Task.detached(priority: .userInitiated) {
            return try textFind.find(forward: forward, isWrap: TextFinderSettings.shared.isWrap, includingSelection: isIncremental)
        }.value
        
        // mark all matches
        if isIncremental, let layoutManager = textView.layoutManager {
            layoutManager.groupTemporaryAttributesUpdate(in: textView.string.nsRange) {
                layoutManager.removeTemporaryAttribute(.backgroundColor, forCharacterRange: textView.string.nsRange)
                for range in result.ranges {
                    layoutManager.addTemporaryAttribute(.backgroundColor, value: NSColor.unemphasizedSelectedTextBackgroundColor, forCharacterRange: range)
                }
            }
            
            // unmark either when the client view resigned the key window or when the Find panel closed
            self.highlightObserver = NotificationCenter.default.publisher(for: NSWindow.didResignKeyNotification)
                .sink { [weak self, weak textView] _ in
                    textView?.unhighlight(nil)
                    self?.highlightObserver = nil
                }
        }
        
        // found feedback
        if let range = result.range {
            textView.select(range: range)
            textView.showFindIndicator(for: range)
            
            if result.wrapped {
                if let view = textView.enclosingScrollView?.superview {
                    let hudView = NSHostingView(rootView: HUDView(symbol: .wrap, flipped: !forward))
                    hudView.rootView.parent = hudView
                    hudView.translatesAutoresizingMaskIntoConstraints = false
                    
                    // remove previous HUD if any
                    for subview in view.subviews where subview is NSHostingView<HUDView> {
                        subview.removeFromSuperview()
                    }
                    
                    view.addSubview(hudView)
                    hudView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
                    hudView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
                    hudView.layout()
                }
                
                // feedback for VoiceOver
                textView.requestAccessibilityAnnouncement("Search wrapped.".localized)
            }
        } else if !isIncremental {
            NSSound.beep()
        }
        
        self.notifyResult(.found(result.ranges), textView: textView)
        if !isIncremental {
            TextFinderSettings.shared.noteFindHistory()
        }
    }
    
    
    /// Replace matched string in selection with replacementString.
    @discardableResult
    @MainActor private func replaceSelected() -> Bool {
        
        guard
            let textView = self.client,
            let textFind = self.prepareTextFind(for: textView)
        else { NSSound.beep(); return false }
        
        let replacementString = TextFinderSettings.shared.replacementString
        
        guard let result = textFind.replace(with: replacementString) else { return false }
        
        // apply replacement to text view
        return textView.replace(with: result.string, range: result.range,
                                selectedRange: NSRange(location: result.range.location,
                                                       length: result.string.length),
                                actionName: "Replace".localized)
    }
    
    
    /// Notify find/replacement result to the user.
    ///
    /// - Parameters:
    ///   - result: The result of the process.
    ///   - textView: The text view where find/replacement was performed.
    private func notifyResult(_ result: TextFindResult, textView: NSTextView) {
        
        self.resultAvailabilityObserver = nil
        self.result = result
        
        // feedback for VoiceOver
        textView.requestAccessibilityAnnouncement(result.message)
        
        // observe target textView to know the timing to remove the result
        if case .found = result {
            self.resultAvailabilityObserver = Publishers.Merge(
                NotificationCenter.default.publisher(for: NSTextStorage.didProcessEditingNotification, object: textView.textStorage),
                NotificationCenter.default.publisher(for: NSWindow.willCloseNotification, object: textView.window))
            .sink { [weak self] _ in
                self?.result = nil
                self?.resultAvailabilityObserver = nil
            }
        }
    }
    
    
    /// Find all matched strings and apply the result to views.
    ///
    /// - Parameters:
    ///   - showsList: Whether shows the result view when finished.
    ///   - actionName: The name of the action to display in the progress sheet.
    @MainActor private func findAll(showsList: Bool, actionName: LocalizedStringKey) async {
        
        guard
            let textView = self.client,
            let textFind = self.prepareTextFind(for: textView)
        else { return NSSound.beep() }
        
        textView.isEditable = false
        
        let highlightColors = NSColor.textHighlighterColor.usingColorSpace(.genericRGB)!.decomposite(into: textFind.numberOfCaptureGroups + 1)
        let lineCounter = LineCounter(textFind.string as NSString)
        
        // setup progress sheet
        let progress = FindProgress(scope: textFind.scopeRange)
        let indicatorView = FindProgressView(actionName, progress: progress, unit: .find)
        let indicator = NSHostingController(rootView: indicatorView)
        indicator.rootView.parent = indicator
        textView.viewControllerForSheet?.presentAsSheet(indicator)
        
        let (highlights, matches) = await Task.detached(priority: .userInitiated) {
            var highlights: [ItemRange<NSColor>] = []
            var resultMatches: [TextFindAllResult.Match] = []  // not used if showsList is false
            
            textFind.findAll { (matches: [NSRange], stop) in
                guard !progress.isCancelled else {
                    stop = true
                    return
                }
                
                // highlight
                highlights += matches.enumerated()
                    .filter { !$0.element.isEmpty }
                    .map { ItemRange(item: highlightColors[$0.offset], range: $0.element) }
                
                // build TextFindResult for table
                if showsList {
                    let matchedRange = matches[0]
                    
                    // calculate line number
                    let lineNumber = lineCounter.lineNumber(at: matchedRange.location)
                    
                    // build a highlighted line string for result table
                    let lineRange = (textFind.string as NSString).lineRange(for: matchedRange)
                    let lineString = (textFind.string as NSString).substring(with: lineRange)
                    let attrLineString = NSMutableAttributedString(string: lineString)
                    for (index, range) in matches.enumerated() where !range.isEmpty {
                        attrLineString.addAttribute(.backgroundColor,
                                                    value: highlightColors[index],
                                                    range: range.shifted(by: -lineRange.location))
                    }
                    
                    // calculate inline range
                    let inlineRange = matchedRange.shifted(by: -lineRange.location)
                    
                    resultMatches.append(.init(range: matchedRange, lineNumber: lineNumber, attributedLineString: attrLineString, inlineRange: inlineRange))
                }
                
                progress.completedUnit = matches[0].upperBound
                progress.count += 1
            }
            
            return (highlights, resultMatches)
        }.value
        
        textView.isEditable = true
        
        guard !progress.isCancelled else { return }
        
        // highlight
        if let layoutManager = textView.layoutManager {
            let wholeRange = textFind.string.nsRange
            layoutManager.groupTemporaryAttributesUpdate(in: wholeRange) {
                layoutManager.removeTemporaryAttribute(.backgroundColor, forCharacterRange: wholeRange)
                for highlight in highlights {
                    layoutManager.addTemporaryAttribute(.backgroundColor, value: highlight.item, forCharacterRange: highlight.range)
                }
            }
        }
        
        if highlights.isEmpty {
            NSSound.beep()
        }
        
        progress.isFinished = true
        
        if showsList {
            self.notifyResult(.found(matches.map(\.range)), textView: textView)
            self.didFindAll.send(.init(findString: textFind.findString, matches: matches, textView: textView))
        }
        
        if !matches.isEmpty, let panel = FindPanelController.shared.window, panel.isVisible {
            panel.makeKey()
        }
        
        TextFinderSettings.shared.noteFindHistory()
    }
    
    
    /// Replace all matched strings and apply the result to views.
    @MainActor private func replaceAll() async {
        
        guard
            let textView = self.client,
            let textFind = self.prepareTextFind(for: textView)
        else { return NSSound.beep() }
        
        textView.isEditable = false
        
        let replacementString = TextFinderSettings.shared.replacementString
        
        // setup progress sheet
        let progress = FindProgress(scope: textFind.scopeRange)
        let indicatorView = FindProgressView("Replace All", progress: progress, unit: .replacement)
        let indicator = NSHostingController(rootView: indicatorView)
        indicator.rootView.parent = indicator
        textView.viewControllerForSheet?.presentAsSheet(indicator)
        
        let (replacementItems, selectedRanges) = await Task.detached(priority: .userInitiated) {
            textFind.replaceAll(with: replacementString) { (range, stop) in
                guard !progress.isCancelled else {
                    stop = true
                    return
                }
                
                progress.completedUnit = range.upperBound
                progress.count += 1
            }
        }.value
        
        textView.isEditable = true
        
        guard !progress.isCancelled else { return }
        
        if !replacementItems.isEmpty {
            // apply found strings to the text view
            textView.replace(with: replacementItems.map(\.string), ranges: replacementItems.map(\.range), selectedRanges: selectedRanges,
                             actionName: "Replace All".localized)
        }
        
        if progress.count > 0 {
            NSSound.beep()
        }
        
        progress.isFinished = true
        
        if let panel = FindPanelController.shared.window, panel.isVisible {
            panel.makeKey()
        }
        
        self.notifyResult(.replaced(progress.count), textView: textView)
        TextFinderSettings.shared.noteReplaceHistory()
    }
}



// MARK: -

extension NSTextView {
    
    @IBAction func unhighlight(_ sender: Any?) {
        
        self.layoutManager?.removeTemporaryAttribute(.backgroundColor, forCharacterRange: self.string.nsRange)
    }
}



// MARK: -

private final class LineCounter: LineRangeCacheable {
    
    let string: NSString
    var lineRangeCache = LineRangeCache()
    
    
    init(_ string: NSString) {
        
        self.string = string
    }
}
