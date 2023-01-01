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

final class TextFinder: NSResponder, NSMenuItemValidation {
    
    static let shared = TextFinder()
    
    
    // MARK: Public Properties
    
    @objc dynamic var findString = "" {
        
        didSet {
            NSPasteboard.findString = findString
        }
    }
    @objc dynamic var replacementString = ""
    
    @Published private(set) var result: TextFindResult?
    let didFindAll: PassthroughSubject<TextFindAllResult, Never> = .init()
    

    // MARK: Private Properties
    
    private var searchTask: Task<Void, any Error>?
    private var applicationActivationObserver: AnyCancellable?
    private var resultAvailabilityObserver: AnyCancellable?
    private var highlightObserver: AnyCancellable?
    
    private lazy var findPanelController: FindPanelController = NSStoryboard(name: "FindPanel").instantiateInitialController()!
    private lazy var multipleReplacementPanelController: NSWindowController = NSStoryboard(name: "MultipleReplacementPanel").instantiateInitialController()!
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    private override init() {
        
        super.init()
        
        // add to responder chain
        NSApp.nextResponder = self
        
        // observe application activation to sync find string with other apps
        self.applicationActivationObserver = NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                if let sharedFindString = NSPasteboard.findString {
                    self?.findString = sharedFindString
                }
            }
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    // MARK: Menu Item Validation
    
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        
        switch menuItem.action {
            case #selector(findNext(_:)),
                 #selector(findPrevious(_:)),
                 #selector(findSelectedText(_:)),
                 #selector(findAll(_:)),
                 #selector(highlight(_:)),
                 #selector(unhighlight(_:)),
                 #selector(replace(_:)),
                 #selector(replaceAndFind(_:)),
                 #selector(replaceAll(_:)),
                 #selector(selectAllMatches(_:)),
                 #selector(useSelectionForFind(_:)),
                 #selector(useSelectionForReplace(_:)),
                 #selector(centerSelectionInVisibleArea(_:)):
                return self.client != nil
                
            case nil:
                return false
                
            default:
                return true
        }
    }
    
    
    
    // MARK: Public Methods
    
    /// Target text view.
    var client: NSTextView? {
        
        guard let provider = NSApp.target(forAction: #selector(TextFinderClientProvider.textFinderClient)) as? TextFinderClientProvider else { return nil }
        
        return provider.textFinderClient()
    }
    
    
    /// Perform incremental search.
    ///
    /// - Returns: The number of found.
    func incrementalSearch() {
        
        self.searchTask?.cancel()
        self.searchTask = Task(priority: .userInitiated) {
            try await self.find(forward: true, marksAllMatches: true, isIncremental: true)
        }
    }
    
    
    
    // MARK: Action Messages
    
    /// Jump to selection in client.
    @IBAction override func centerSelectionInVisibleArea(_ sender: Any?) {
        
        self.client?.centerSelectionInVisibleArea(sender)
    }
    
    
    /// Activate find panel.
    @IBAction func showFindPanel(_ sender: Any?) {
        
        self.findPanelController.showWindow(sender)
    }
    
    
    /// Activate multiple replacement panel.
    @IBAction func showMultipleReplacementPanel(_ sender: Any?) {
        
        self.multipleReplacementPanelController.showWindow(sender)
    }
    
    
    /// Find next matched string.
    @IBAction func findNext(_ sender: Any?) {
        
        // find backwards if Shift key pressed
        let isShiftPressed = NSEvent.modifierFlags.contains(.shift)
        
        self.searchTask?.cancel()
        self.searchTask = Task(priority: .userInitiated) {
            try await self.find(forward: !isShiftPressed)
        }
    }
    
    
    /// Find previous matched string.
    @IBAction func findPrevious(_ sender: Any?) {
        
        self.searchTask?.cancel()
        self.searchTask = Task(priority: .userInitiated) {
            try await self.find(forward: false)
        }
    }
    
    
    /// Perform find action with the selected string.
    @IBAction func findSelectedText(_ sender: Any?) {
        
        self.useSelectionForFind(sender)
        self.findNext(sender)
    }
    
    
    /// Select all matched strings.
    @IBAction func selectAllMatches(_ sender: Any?) {
        
        guard
            let (textView, textFind) = self.prepareTextFind(forEditing: false),
            let matchedRanges = try? textFind.matches
        else { return }
        
        textView.selectedRanges = matchedRanges as [NSValue]
        
        self.notifyResult(.found(matchedRanges), textView: textView)
        
        UserDefaults.standard.appendHistory(self.findString, forKey: .findHistory)
    }
    
    
    /// Find all matched strings and show results in a table.
    @IBAction func findAll(_ sender: Any?) {
        
        Task {
            await self.findAll(showsList: true, actionName: "Find All")
        }
    }
    
    
    /// Highlight all matched strings.
    @IBAction func highlight(_ sender: Any?) {
        
        Task {
            await self.findAll(showsList: false, actionName: "Highlight All")
        }
    }
    
    
    /// Remove all of current highlights in the frontmost textView.
    @IBAction func unhighlight(_ sender: Any?) {
        
        self.client?.unhighlight()
    }
    
    
    /// Replace matched string in selection with replacementString.
    @IBAction func replace(_ sender: Any?) {
        
        if self.replace() {
            self.client?.centerSelectionInVisibleArea(self)
        } else {
            NSSound.beep()
        }
        
        UserDefaults.standard.appendHistory(self.findString, forKey: .findHistory)
        UserDefaults.standard.appendHistory(self.replacementString, forKey: .replaceHistory)
    }
    
    
    /// Replace matched string with replacementString and select the next match.
    @IBAction func replaceAndFind(_ sender: Any?) {
        
        self.replace()
        
        self.searchTask?.cancel()
        self.searchTask = Task(priority: .userInitiated) {
            try await self.find(forward: true)
        }
        
        UserDefaults.standard.appendHistory(self.findString, forKey: .findHistory)
        UserDefaults.standard.appendHistory(self.replacementString, forKey: .replaceHistory)
    }
    
    
    /// Replace all matched strings with given string.
    @IBAction func replaceAll(_ sender: Any?) {
        
        Task {
            await self.replaceAll()
        }
    }
    
    
    /// Set selected string to find field.
    @IBAction func useSelectionForFind(_ sender: Any?) {
        
        guard let selectedString = self.selectedString else { return NSSound.beep() }
        
        self.findString = selectedString
        
        // auto-disable regex
        UserDefaults.standard[.findUsesRegularExpression] = false
    }
    
    
    /// Set selected string to replace field.
    @IBAction func useSelectionForReplace(_ sender: Any?) {
        
        self.replacementString = self.selectedString ?? ""
    }
    
    
    
    // MARK: Private Methods
    
    /// Selected string in the current target.
    private var selectedString: String? {
        
        guard let textView = self.client else { return nil }
        
        return (textView.string as NSString).substring(with: textView.selectedRange)
    }
    
    
    /// Find string of which line endings are standardized to the document line ending.
    private var sanitizedFindString: String {
        
        let lineEnding = (self.client as? EditorTextView)?.lineEnding ?? .lf
        
        return self.findString.replacingLineEndings(with: lineEnding)
    }
    
    
    /// Check Find can be performed and alert if needed.
    ///
    /// - Parameter forEditing: When true, perform only when the textView is editable.
    /// - Returns: The target textView and a TextFind object.
    @MainActor private func prepareTextFind(forEditing: Bool) -> (NSTextView, TextFind)? {
        
        guard
            let textView = self.client,
            (!forEditing || (textView.isEditable && textView.window?.attachedSheet == nil))
        else {
            NSSound.beep()
            return nil
        }
        
        guard self.findPanelController.window?.attachedSheet == nil else {
            self.findPanelController.showWindow(self)
            NSSound.beep()
            return nil
        }
        
        let string = textView.string.immutable
        let mode = UserDefaults.standard.textFindMode
        let inSelection = UserDefaults.standard[.findInSelection]
        let textFind: TextFind
        do {
            textFind = try TextFind(for: string, findString: self.sanitizedFindString, mode: mode, inSelection: inSelection, selectedRanges: textView.selectedRanges.map(\.rangeValue))
        } catch let error as TextFind.Error {
            switch error {
                case .regularExpression, .emptyInSelectionSearch:
                    self.findPanelController.showWindow(self)
                    self.presentError(error, modalFor: self.findPanelController.window!, delegate: nil, didPresent: nil, contextInfo: nil)
                case .emptyFindString:
                    break
            }
            NSSound.beep()
            return nil
        } catch {
            assertionFailure(error.localizedDescription)
            return nil
        }
        
        return (textView, textFind)
    }
    
    
    /// Perform single find.
    ///
    /// - Parameters:
    ///   - forward: The flag whether finds forward or backward.
    ///   - marksAllMatches: Whether marks all matches in the editor.
    ///   - isIncremental: Whether is the incremental search.
    /// - Throws: `CancellationError`
    @MainActor private func find(forward: Bool, marksAllMatches: Bool = false, isIncremental: Bool = false) async throws {
        
        assert(forward || !isIncremental)
        
        guard let (textView, textFind) = self.prepareTextFind(forEditing: false) else { return }
        
        // find in background thread
        let result = try await Task.detached(priority: .userInitiated) {
            return try textFind.find(forward: forward, isWrap: UserDefaults.standard[.findIsWrap], includingSelection: isIncremental)
        }.value
        
        // mark all matches
        if marksAllMatches, let layoutManager = textView.layoutManager {
            layoutManager.groupTemporaryAttributesUpdate(in: textView.string.nsRange) {
                layoutManager.removeTemporaryAttribute(.backgroundColor, forCharacterRange: textView.string.nsRange)
                for range in result.ranges {
                    layoutManager.addTemporaryAttribute(.backgroundColor, value: NSColor.unemphasizedSelectedTextBackgroundColor, forCharacterRange: range)
                }
            }
            
            // unmark either when the client view resigned the key window or when the Find panel closed
            self.highlightObserver = NotificationCenter.default.publisher(for: NSWindow.didResignKeyNotification)
                .sink { [weak self, weak textView] _ in
                    textView?.unhighlight()
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
            UserDefaults.standard.appendHistory(self.findString, forKey: .findHistory)
        }
    }
    
    
    /// Replace matched string in selection with replacementString.
    @discardableResult
    @MainActor private func replace() -> Bool {
        
        guard
            let (textView, textFind) = self.prepareTextFind(forEditing: true),
            let result = textFind.replace(with: self.replacementString)
        else { return false }
        
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
        
        guard let (textView, textFind) = self.prepareTextFind(forEditing: false) else { return }
        
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
        
        if !matches.isEmpty, let panel = self.findPanelController.window, panel.isVisible {
            panel.makeKey()
        }
        
        UserDefaults.standard.appendHistory(self.findString, forKey: .findHistory)
    }
    
    
    /// Replace all matched strings and apply the result to views.
    @MainActor private func replaceAll() async {
        
        guard let (textView, textFind) = self.prepareTextFind(forEditing: true) else { return }
        
        textView.isEditable = false
        
        let replacementString = self.replacementString
        
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
        
        if let panel = self.findPanelController.window, panel.isVisible {
            panel.makeKey()
        }
        
        self.notifyResult(.replaced(progress.count), textView: textView)
        
        UserDefaults.standard.appendHistory(self.findString, forKey: .findHistory)
        UserDefaults.standard.appendHistory(self.replacementString, forKey: .replaceHistory)
    }
}



// MARK: -

extension NSTextView {
    
    @MainActor func unhighlight() {
        
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



// MARK: - UserDefaults

private extension UserDefaults {
    
    private static let maximumRecents = 20
    
    
    /// Add a new value to history as the latest item with the user defaults key.
    ///
    /// - Parameters:
    ///   - value: The value to add.
    ///   - key: The default key to add the value.
    func appendHistory<T: Equatable>(_ value: T, forKey key: DefaultKey<[T]>) {
        
        guard (value as? String)?.isEmpty != true else { return }
        
        self[key].appendUnique(value, maximum: Self.maximumRecents)
    }
}


private extension UserDefaults {
    
    var textFindMode: TextFind.Mode {
        
        if self[.findUsesRegularExpression] {
            let options = NSRegularExpression.Options()
                .union(self[.findIgnoresCase] ? .caseInsensitive : [])
                .union(self[.findRegexIsSingleline] ? .dotMatchesLineSeparators : [])
                .union(self[.findRegexIsMultiline] ? .anchorsMatchLines : [])
                .union(self[.findRegexUsesUnicodeBoundaries] ? .useUnicodeWordBoundaries : [])
            
            return .regularExpression(options: options, unescapesReplacement: self[.findRegexUnescapesReplacementString])
            
        } else {
            let options = String.CompareOptions()
                .union(self[.findIgnoresCase] ? .caseInsensitive : [])
                .union(self[.findTextIsLiteralSearch] ? .literal : [])
                .union(self[.findTextIgnoresDiacriticMarks] ? .diacriticInsensitive : [])
                .union(self[.findTextIgnoresWidth] ? .widthInsensitive : [])
            
            return .textual(options: options, fullWord: self[.findMatchesFullWord])
        }
    }
}



// MARK: Pasteboard

private extension NSPasteboard {
    
    /// Find string from global domain.
    class var findString: String? {
        
        get {
            let pasteboard = NSPasteboard(name: .find)
            return pasteboard.string(forType: .string)
        }
        
        set {
            guard let string = newValue, !string.isEmpty else { return }
            
            let pasteboard = NSPasteboard(name: .find)
            pasteboard.clearContents()
            pasteboard.setString(string, forType: .string)
        }
    }
}
