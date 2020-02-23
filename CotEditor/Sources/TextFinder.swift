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
//  © 2015-2020 1024jp
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

import Cocoa

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


private struct HighlightItem {
    
    var range: NSRange
    var color: NSColor
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
    
    private lazy var findPanelController = FindPanelController.instantiate(storyboard: "FindPanel")
    private lazy var multipleReplacementPanelController = NSWindowController.instantiate(storyboard: "MultipleReplacementPanel")
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    private override init() {
        
        super.init()
        
        // add to responder chain
        NSApp.nextResponder = self
        
        // observe application activation to sync find string with other apps
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: NSApplication.didBecomeActiveNotification, object: nil)
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    // MARK: Menu Item Validation
    
    /// validate menu item
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
    
    
    
    // MARK: Notifications
    
    /// sync search string on activating application
    @objc private func applicationDidBecomeActive(_ notification: Notification) {
        
        if let sharedFindString = NSPasteboard.findString {
            self.findString = sharedFindString
        }
    }
    
    
    
    // MARK: Public Methods
    
    /// target text view
    var client: NSTextView? {
        
        guard let provider = NSApp.target(forAction: #selector(TextFinderClientProvider.textFinderClient)) as? TextFinderClientProvider else { return nil }
        
        return provider.textFinderClient()
    }
    
    
    
    // MARK: Action Messages
    
    /// jump to selection in client
    @IBAction override func centerSelectionInVisibleArea(_ sender: Any?) {
        
        self.client?.centerSelectionInVisibleArea(sender)
    }
    
    
    /// activate find panel
    @IBAction func showFindPanel(_ sender: Any?) {
        
        self.findPanelController.showWindow(sender)
    }
    
    
    /// activate multiple replacement panel
    @IBAction func showMultipleReplacementPanel(_ sender: Any?) {
        
        self.multipleReplacementPanelController.showWindow(sender)
    }
    
    
    /// find next matched string
    @IBAction func findNext(_ sender: Any?) {
        
        // find backwards if Shift key pressed
        let isShiftPressed = NSEvent.modifierFlags.contains(.shift)
        
        self.find(forward: !isShiftPressed)
    }
    
    
    /// find previous matched string
    @IBAction func findPrevious(_ sender: Any?) {
        
        self.find(forward: false)
    }
    
    
    /// perform find action with the selected string
    @IBAction func findSelectedText(_ sender: Any?) {
        
        self.useSelectionForFind(sender)
        self.findNext(sender)
    }
    
    
    /// select all matched strings
    @IBAction func selectAllMatches(_ sender: Any?) {
        
        guard let (textView, textFind) = self.prepareTextFind(forEditing: false) else { return }
        
        var matchedRanges = [NSRange]()
        textFind.findAll { (matches: [NSRange], _) in
            matchedRanges.append(matches[0])
        }
        
        textView.selectedRanges = matchedRanges as [NSValue]
        
        self.delegate?.textFinder(self, didFind: matchedRanges.count, textView: textView)
        
        UserDefaults.standard.appendHistory(self.findString, forKey: .findHistory)
    }
    
    
    /// find all matched strings and show results in a table
    @IBAction func findAll(_ sender: Any?) {
        
        self.findAll(showsList: true, actionName: "Find All".localized)
    }
    
    
    /// highlight all matched strings
    @IBAction func highlight(_ sender: Any?) {
        
        self.findAll(showsList: false, actionName: "Highlight".localized)
    }
    
    
    /// remove all of current highlights in the frontmost textView
    @IBAction func unhighlight(_ sender: Any?) {
        
        guard let textView = self.client else { return }
        
        let range = textView.string.nsRange
        
        textView.layoutManager?.removeTemporaryAttribute(.backgroundColor, forCharacterRange: range)
    }
    
    
    /// replace matched string in selection with replacementString
    @IBAction func replace(_ sender: Any?) {
        
        if self.replace() {
            self.client?.centerSelectionInVisibleArea(self)
        } else {
            NSSound.beep()
        }
        
        UserDefaults.standard.appendHistory(self.findString, forKey: .findHistory)
        UserDefaults.standard.appendHistory(self.replacementString, forKey: .replaceHistory)
    }
    
    
    /// replace matched string with replacementString and select the next match
    @IBAction func replaceAndFind(_ sender: Any?) {
        
        self.replace()
        self.find(forward: true)
        
        UserDefaults.standard.appendHistory(self.findString, forKey: .findHistory)
        UserDefaults.standard.appendHistory(self.replacementString, forKey: .replaceHistory)
    }
    
    
    /// replace all matched strings with given string
    @IBAction func replaceAll(_ sender: Any?) {
        
        guard let (textView, textFind) = self.prepareTextFind(forEditing: true) else { return }
        
        textView.isEditable = false
        
        let replacementString = self.replacementString
        
        // setup progress sheet
        let progress = TextFindProgress(format: .replacement)
        let indicator = ProgressViewController.instantiate(storyboard: "ProgressView")
        indicator.closesAutomatically = UserDefaults.standard[.findClosesIndicatorWhenDone]
        indicator.setup(progress: progress, message: "Replace All".localized)
        textView.viewControllerForSheet?.presentAsSheet(indicator)
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let (replacementItems, selectedRanges) = textFind.replaceAll(with: replacementString) { (flag, stop) in
                guard !progress.isCancelled else {
                    stop = true
                    return
                }
                
                switch flag {
                    case .findProgress, .foundCount:
                        break
                    case .replacementProgress:
                        progress.completedUnitCount += 1
                }
            }
            
            DispatchQueue.main.sync {
                textView.isEditable = true
                
                guard !progress.isCancelled else { return }
                
                if !replacementItems.isEmpty {
                    let replacementStrings = replacementItems.map { $0.string }
                    let replacementRanges = replacementItems.map { $0.range }
                    
                    // apply found strings to the text view
                    textView.replace(with: replacementStrings, ranges: replacementRanges, selectedRanges: selectedRanges,
                                     actionName: "Replace All".localized)
                }
                
                if replacementItems.isEmpty {
                    NSSound.beep()
                    progress.localizedDescription = "Not Found".localized
                }
                
                indicator.done()
                
                if indicator.closesAutomatically, let panel = self.findPanelController.window, panel.isVisible {
                    panel.makeKey()
                }
                
                let count = Int(progress.completedUnitCount)
                self.delegate?.textFinder(self, didReplace: count, textView: textView)
            }
        }
        
        UserDefaults.standard.appendHistory(self.findString, forKey: .findHistory)
        UserDefaults.standard.appendHistory(self.replacementString, forKey: .replaceHistory)
    }
    
    
    /// set selected string to find field
    @IBAction func useSelectionForFind(_ sender: Any?) {
        
        guard let selectedString = self.selectedString else { return NSSound.beep() }
        
        self.findString = selectedString
        
        // auto-disable regex
        UserDefaults.standard[.findUsesRegularExpression] = false
    }
    
    
    /// set selected string to replace field
    @IBAction func useSelectionForReplace(_ sender: Any?) {
        
        self.replacementString = self.selectedString ?? ""
    }
    
    
    
    // MARK: Private Methods
    
    /// selected string in the current tareget
    private var selectedString: String? {
        
        guard let textView = self.client else { return nil }
        
        return (textView.string as NSString).substring(with: textView.selectedRange)
    }
    
    
    /// find string of which line endings are standardized to LF
    private var sanitizedFindString: String {
        
        return self.findString.replacingLineEndings(with: .lf)
    }
    
    
    /// check Find can be performed and alert if needed
    private func prepareTextFind(forEditing: Bool) -> (NSTextView, TextFind)? {
        
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
        let mode = TextFind.Mode(defaults: UserDefaults.standard)
        let inSelection = UserDefaults.standard[.findInSelection]
        let textFind: TextFind
        do {
            textFind = try TextFind(for: string, findString: self.sanitizedFindString, mode: mode, inSelection: inSelection, selectedRanges: textView.selectedRanges as! [NSRange])
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
            assertionFailure()
            return nil
        }
        
        return (textView, textFind)
    }
    
    
    /// perform "Find Next" or "Find Previous" and return number of found
    @discardableResult
    private func find(forward: Bool) -> Int {
        
        guard let (textView, textFind) = self.prepareTextFind(forEditing: false) else { return 0 }
        
        let result = textFind.find(forward: forward, isWrap: UserDefaults.standard[.findIsWrap])
        
        // found feedback
        if let range = result.range {
            textView.selectedRange = range
            textView.scrollRangeToVisible(range)
            textView.showFindIndicator(for: range)
            
            if result.wrapped {
                if let view = textView.enclosingScrollView?.superview {
                    let hudController = HUDController.instantiate(storyboard: "HUDView")
                    hudController.symbol = .wrap(reversed: !forward)
                    hudController.show(in: view)
                }
                
                if let window = NSApp.mainWindow {
                    NSAccessibility.post(element: window, notification: .announcementRequested,
                                         userInfo: [.announcement: "Search wrapped.".localized])
                }
            }
        } else {
            NSSound.beep()
        }
        
        self.delegate?.textFinder(self, didFind: result.count, textView: textView)
        
        UserDefaults.standard.appendHistory(self.findString, forKey: .findHistory)
        
        return result.count
    }
    
    
    /// replace matched string in selection with replacementString
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
    
    
    /// find all matched strings and apply the result to views
    private func findAll(showsList: Bool, actionName: String) {
        
        guard let (textView, textFind) = self.prepareTextFind(forEditing: false) else { return }
        
        textView.isEditable = false
        
        let highlightColors = NSColor.textHighlighterColors(count: textFind.numberOfCaptureGroups + 1)
        let lineCounter = LineCounter(textFind.string as NSString)
        
        // setup progress sheet
        let progress = TextFindProgress(format: .find)
        let indicator = ProgressViewController.instantiate(storyboard: "ProgressView")
        indicator.closesAutomatically = UserDefaults.standard[.findClosesIndicatorWhenDone]
        indicator.setup(progress: progress, message: actionName)
        textView.viewControllerForSheet?.presentAsSheet(indicator)
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            var highlights = [HighlightItem]()
            var results = [TextFindResult]()  // not used if showsList is false
            
            textFind.findAll { (matches: [NSRange], stop) in
                guard !progress.isCancelled else {
                    stop = true
                    return
                }
                
                // highlight
                highlights += matches.enumerated()
                    .filter { !$0.element.isEmpty }
                    .map { HighlightItem(range: $0.element, color: highlightColors[$0.offset]) }
                
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
                        let inlineRange = range.shifted(offset: -lineRange.location)
                        
                        attrLineString.addAttribute(.backgroundColor, value: color, range: inlineRange)
                    }
                    
                    // calculate inline range
                    let inlineRange = matchedRange.shifted(offset: -lineRange.location)
                    
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
                            layoutManager.addTemporaryAttribute(.backgroundColor, value: highlight.color, forCharacterRange: highlight.range)
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
                
                // -> close also if result view has been shown
                if indicator.closesAutomatically || !results.isEmpty {
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

private class LineCounter: LineRangeCacheable {
    
    let string: NSString
    var lineStartIndexes = IndexSet()
    var firstLineUncoundedIndex = 0
    
    
    init(_ string: NSString) {
        
        self.string = string
    }
    
}



// MARK: - UserDefaults

private extension UserDefaults {
    
    private static let MaxHistorySize = 20
    
    
    /// append given string to history with the user defaults key
    func appendHistory(_ string: String, forKey key: DefaultKey<[String]>) {
        
        assert(key == .findHistory || key == .replaceHistory)
        
        guard !string.isEmpty else { return }
        
        // append new string to history
        var history = self[key] ?? []
        history.removeFirst(string)  // remove duplicated item
        history.append(string)
        if history.count > UserDefaults.MaxHistorySize {  // remove overflow
            history.removeFirst(history.count - UserDefaults.MaxHistorySize)
        }
        
        self[key] = history
    }
    
}


private extension TextFind.Mode {
    
    init(defaults: UserDefaults) {
        
        if defaults[.findUsesRegularExpression] {
            var options = NSRegularExpression.Options()
            if defaults[.findIgnoresCase]                { options.formUnion(.caseInsensitive) }
            if defaults[.findRegexIsSingleline]          { options.formUnion(.dotMatchesLineSeparators) }
            if defaults[.findRegexIsMultiline]           { options.formUnion(.anchorsMatchLines) }
            if defaults[.findRegexUsesUnicodeBoundaries] { options.formUnion(.useUnicodeWordBoundaries) }
            
            self = .regularExpression(options: options, unescapesReplacement: defaults[.findRegexUnescapesReplacementString])
            
        } else {
            var options = NSString.CompareOptions()
            if defaults[.findIgnoresCase]               { options.formUnion(.caseInsensitive) }
            if defaults[.findTextIsLiteralSearch]       { options.formUnion(.literal) }
            if defaults[.findTextIgnoresDiacriticMarks] { options.formUnion(.diacriticInsensitive) }
            if defaults[.findTextIgnoresWidth]          { options.formUnion(.widthInsensitive) }
            
            self = .textual(options: options, fullWord: defaults[.findMatchesFullWord])
        }
    }
    
}



// MARK: Pasteboard

private extension NSPasteboard {
    
    /// find string from global domain
    class var findString: String? {
        
        get {
            let pasteboard = NSPasteboard(name: .find)
            return pasteboard.string(forType: .string)
        }
        
        set {
            guard let string = newValue, !string.isEmpty else { return }
            
            let pasteboard = NSPasteboard(name: .find)
            
            pasteboard.declareTypes([.string], owner: nil)
            pasteboard.setString(string, forType: .string)
        }
    }
    
}
