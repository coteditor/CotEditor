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
//  © 2015-2022 1024jp
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


protocol TextFinderDelegate: AnyObject {
    
    func textFinder(_ textFinder: TextFinder, didFinishFindingAll findString: String, results: [TextFindResult], textView: NSTextView)
    func textFinder(_ textFinder: TextFinder, didFind numberOfFound: Int, textView: NSTextView)
    func textFinder(_ textFinder: TextFinder, didReplace numberOfReplaced: Int, textView: NSTextView)
}


struct TextFindResult {
    
    var range: NSRange
    var lineNumber: Int
    var attributedLineString: NSAttributedString
    var inlineRange: NSRange
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
    
    weak var delegate: TextFinderDelegate?
    
    
    // MARK: Private Properties
    
    private var searchTask: Task<Void, any Error>?
    private var applicationActivationObserver: AnyCancellable?
    private var highlightObserver: AnyCancellable?
    
    private lazy var findPanelController = FindPanelController.instantiate(storyboard: "FindPanel")
    private lazy var multipleReplacementPanelController = NSWindowController.instantiate(storyboard: "MultipleReplacementPanel")
    
    
    
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
                 #selector(useSelectionForReplace(_:)),  // replacement string accepts empty string
                 #selector(centerSelectionInVisibleArea(_:)):
                return self.client != nil
            
            case #selector(useSelectionForFind(_:)):
                return self.selectedString != nil
            
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
        
        guard let (textView, textFind) = self.prepareTextFind(forEditing: false) else { return }
        
        var matchedRanges: [NSRange] = []
        textFind.findAll { (matches: [NSRange], _) in
            matchedRanges.append(matches[0])
        }
        
        textView.selectedRanges = matchedRanges as [NSValue]
        
        self.delegate?.textFinder(self, didFind: matchedRanges.count, textView: textView)
        
        UserDefaults.standard.appendHistory(self.findString, forKey: .findHistory)
    }
    
    
    /// Find all matched strings and show results in a table.
    @IBAction func findAll(_ sender: Any?) {
        
        self.findAll(showsList: true, actionName: "Find All".localized)
    }
    
    
    /// Highlight all matched strings.
    @IBAction func highlight(_ sender: Any?) {
        
        self.findAll(showsList: false, actionName: "Highlight".localized)
    }
    
    
    /// Remove all of current highlights in the frontmost textView.
    @IBAction func unhighlight(_ sender: Any?) {
        
        guard let textView = self.client else { return }
        
        let range = textView.string.nsRange
        
        textView.layoutManager?.removeTemporaryAttribute(.backgroundColor, forCharacterRange: range)
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
        
        guard let (textView, textFind) = self.prepareTextFind(forEditing: true) else { return }
        
        textView.isEditable = false
        
        let replacementString = self.replacementString
        
        // setup progress sheet
        let progress = TextFindProgress(format: .replacement)
        let closesAutomatically = UserDefaults.standard[.findClosesIndicatorWhenDone]
        let indicator = NSStoryboard(name: "ProgressView").instantiateInitialController { (coder) in
            ProgressViewController(coder: coder, progress: progress, message: "Replace All".localized, closesAutomatically: closesAutomatically)
        }!
        textView.viewControllerForSheet?.presentAsSheet(indicator)
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let (replacementItems, selectedRanges) = textFind.replaceAll(with: replacementString) { (flag, stop) in
                guard !progress.isCancelled else {
                    stop = true
                    return
                }
                
                switch flag {
                    case .findProgress:
                        break
                    case .replacementProgress:
                        progress.completedUnitCount += 1
                }
            }
            
            DispatchQueue.main.sync {
                textView.isEditable = true
                
                guard !progress.isCancelled else { return }
                
                if !replacementItems.isEmpty {
                    let replacementStrings = replacementItems.map(\.string)
                    let replacementRanges = replacementItems.map(\.range)
                    
                    // apply found strings to the text view
                    textView.replace(with: replacementStrings, ranges: replacementRanges, selectedRanges: selectedRanges,
                                     actionName: "Replace All".localized)
                }
                
                if replacementItems.isEmpty {
                    NSSound.beep()
                    progress.localizedDescription = "Not Found".localized
                }
                
                indicator.done()
                
                if closesAutomatically, let panel = self.findPanelController.window, panel.isVisible {
                    panel.makeKey()
                }
                
                let count = Int(progress.completedUnitCount)
                self.delegate?.textFinder(self, didReplace: count, textView: textView)
            }
        }
        
        UserDefaults.standard.appendHistory(self.findString, forKey: .findHistory)
        UserDefaults.standard.appendHistory(self.replacementString, forKey: .replaceHistory)
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
    
    /// Selected string in the current tareget.
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
    private nonisolated func find(forward: Bool, marksAllMatches: Bool = false, isIncremental: Bool = false) async throws {
        
        assert(forward || !isIncremental)
        
        guard let (textView, textFind) = await self.prepareTextFind(forEditing: false) else { return }
        
        let result = try textFind.find(forward: forward, isWrap: UserDefaults.standard[.findIsWrap], includingSelection: isIncremental)
        
        Task { @MainActor in
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
                        let hudView = NSHostingView(rootView: HUDView(symbol: .wrap, rotated: !forward))
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
                    
                    if let window = NSApp.mainWindow {
                        NSAccessibility.post(element: window, notification: .announcementRequested,
                                             userInfo: [.announcement: "Search wrapped.".localized])
                    }
                }
            } else if !isIncremental {
                NSSound.beep()
            }
            
            self.delegate?.textFinder(self, didFind: result.ranges.count, textView: textView)
            
            if !isIncremental {
                UserDefaults.standard.appendHistory(self.findString, forKey: .findHistory)
            }
        }
    }
    
    
    /// Replace matched string in selection with replacementString.
    @discardableResult
    private func replace() -> Bool {
        
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
    
    
    /// Find all matched strings and apply the result to views.
    ///
    /// - Parameters:
    ///   - showsList: Whether shows the result view when finished.
    ///   - actionName: The name of the action to display in the progress sheet.
    private func findAll(showsList: Bool, actionName: String) {
        
        guard let (textView, textFind) = self.prepareTextFind(forEditing: false) else { return }
        
        textView.isEditable = false
        
        let highlightColors = NSColor.textHighlighterColor.usingColorSpace(.genericRGB)!.decomposite(into: textFind.numberOfCaptureGroups + 1)
        let lineCounter = LineCounter(textFind.string as NSString)
        
        // setup progress sheet
        let progress = TextFindProgress(format: .find)
        let closesAutomatically = UserDefaults.standard[.findClosesIndicatorWhenDone]
        let indicator = NSStoryboard(name: "ProgressView").instantiateInitialController { (coder) in
            ProgressViewController(coder: coder, progress: progress, message: actionName, closesAutomatically: closesAutomatically)
        }!
        textView.viewControllerForSheet?.presentAsSheet(indicator)
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            var highlights: [ItemRange<NSColor>] = []
            var results: [TextFindResult] = []  // not used if showsList is false
            
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
                        let color = highlightColors[index]
                        let inlineRange = range.shifted(by: -lineRange.location)
                        
                        attrLineString.addAttribute(.backgroundColor, value: color, range: inlineRange)
                    }
                    
                    // calculate inline range
                    let inlineRange = matchedRange.shifted(by: -lineRange.location)
                    
                    results.append(TextFindResult(range: matchedRange, lineNumber: lineNumber, attributedLineString: attrLineString, inlineRange: inlineRange))
                }
                
                progress.completedUnitCount += 1
            }
            
            DispatchQueue.main.sync {
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
                    progress.localizedDescription = "Not Found".localized
                }
                
                indicator.done()
                
                if showsList {
                    self.delegate?.textFinder(self, didFinishFindingAll: textFind.findString, results: results, textView: textView)
                }
                
                // close also if result view has been shown
                if closesAutomatically || !results.isEmpty {
                    indicator.dismiss(nil)
                    if let panel = self.findPanelController.window, panel.isVisible {
                        panel.makeKey()
                    }
                }
            }
        }
        
        UserDefaults.standard.appendHistory(self.findString, forKey: .findHistory)
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
            let options = NSString.CompareOptions()
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
