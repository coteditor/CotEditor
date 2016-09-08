/*
 
 TextFinder.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2015-01-03.
 
 ------------------------------------------------------------------------------
 
 © 2015-2016 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Cocoa

@objc protocol TextFinderClientProvider: class {
    
    func textFinderClient() -> NSTextView?
    
}


protocol TextFinderDelegate: class {
    
    func textFinder(_ textFinder: TextFinder, didFinishFindingAll findString: String, results: [TextFindResult], textView: NSTextView)
    func textFinder(_ textFinder: TextFinder, didFound numberOfFound: Int, textView: NSTextView)
    
}


struct TextFindResult {
    
    let range: NSRange
    let lineRange: NSRange
    let lineNumber: UInt
    let attributedLineString: NSAttributedString
    
}


private protocol TextFinderSettingsProvider {
    
    var usesRegularExpression: Bool { get }
    var isWrap: Bool { get }
    var inSelection: Bool { get }
    var textualOptions: NSString.CompareOptions { get }
    var regexOptions: NSRegularExpression.Options { get }
    var closesIndicatorWhenDone: Bool { get }
    var sharesFindString: Bool { get }
    
}


private struct HighlightItem {
    
    let range: NSRange
    let color: NSColor
    
}


// constants
private let MaxHistorySize = 20



// MARK:

final class TextFinder: NSResponder, TextFinderSettingsProvider {
    
    static let shared = TextFinder()
    
    
    // MARK: Public Properties
    
    dynamic var findString = ""
    dynamic var replacementString = ""
    
    weak var delegate: TextFinderDelegate?
    
    
    // MARK: Private Properties
    
    private lazy var findPanelController: FindPanelController = NSStoryboard(name: "FindPanel", bundle: nil).instantiateInitialController() as! FindPanelController
    private let integerFormatter: NumberFormatter
    private let highlightColor: NSColor
    private var busyTextViews = Set<NSTextView>()
    
    
    
    // MARK:
    // MARK: Lifecycle
    
    private override init() {
        
        self.integerFormatter = NumberFormatter()
        self.integerFormatter.usesGroupingSeparator = true
        self.integerFormatter.numberStyle = .decimal
        
        self.highlightColor = NSColor(calibratedHue: 0.24, saturation: 0.8, brightness: 0.8, alpha: 0.4)
        // Highlight color is currently not customizable. (2015-01-04)
        // It might better when it can be set in theme also for incompatible chars highlight.
        // Just because I'm lazy.
        
        super.init()
        
        // add to responder chain
        NSApp.nextResponder = self
        
        // observe application activation to sync find string with other apps
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: .NSApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActive), name: .NSApplicationWillResignActive, object: nil)
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    
    // MARK: Responder Methods
    
    /// validate menu item
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        
        guard let action = menuItem.action else { return false }
        
        switch action {
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
            
        default:
            return true
        }
    }
    
    
    
    // MARK: Notifications
    
    /// sync search string on activating application
    func applicationDidBecomeActive(_ notification: Notification) {
        
        if self.sharesFindString {
            if let sharedFindString = self.findStringInPasteboard {
                self.findString = sharedFindString
            }
        }
    }
    
    
    /// sync search string on activating application
    func applicationWillResignActive(_ notification: Notification) {
        
        if self.sharesFindString {
            self.findStringInPasteboard = self.findString
        }
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
    
    
    /// find next matched string
    @IBAction func findNext(_ sender: Any?) {
        
        // find backwards if Shift key pressed
        let isShiftPressed = NSEvent.modifierFlags().contains(.shift)
        
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
    
    
    /// find all matched string in the target and show results in a table
    @IBAction func findAll(_ sender: Any?) {
        
        guard self.checkIsReadyToFind(),
            let textView = self.client else { return }
        
        let integerFormatter = self.integerFormatter
        let findString = self.sanitizedFindString
        let regex = self.regex()!
        let scopeRanges = self.scopeRanges
        
        self.busyTextViews.insert(textView)
        
        let numberOfGroups = regex.numberOfCaptureGroups
        let highlightColors = self.highlightColor.decomposite(into: numberOfGroups + 1)
        
        let lineRegex = try! NSRegularExpression(pattern: "\n")
        let string = textView.string ?? ""
        
        // setup progress sheet
        guard let documentViewController = textView.window?.windowController?.contentViewController else {
            fatalError("The find target text view must be embedded in a window with its contentViewController.")
        }
        let progress = Progress(totalUnitCount: -1)
        let indicator = ProgressViewController(progress: progress, message: NSLocalizedString("Find All", comment: ""))!
        documentViewController.presentViewControllerAsSheet(indicator)
        
        DispatchQueue.global().async { [weak self] in
            guard let `self` = self else { return }
            
            var results = [TextFindResult]()
            var highlights = [HighlightItem]()
            
            var lineNumber = 1
            var lineCountedLocation = 0
            
            self.enumerateMatchs(in: string, ranges: scopeRanges, using: { (matchedRange: NSRange, match: NSTextCheckingResult?, stop) in
                
                guard !progress.isCancelled else {
                    indicator.dismiss(self)
                    self.busyTextViews.remove(textView)
                    stop = true
                    return
                }
                
                // calculate line number
                let diffRange = NSRange(location: lineCountedLocation, length: matchedRange.location - lineCountedLocation)
                lineNumber += lineRegex.numberOfMatches(in: string, range: diffRange)
                lineCountedLocation = matchedRange.location
                
                // highlight both string in textView and line string for result table
                let lineRange = (string as NSString).lineRange(for: matchedRange)
                let inlineRange = NSRange(location: matchedRange.location - lineRange.location,
                                          length: matchedRange.length)
                let lineString = (string as NSString).substring(with: lineRange)
                let lineAttrString = NSMutableAttributedString(string: lineString)
                
                lineAttrString.addAttribute(NSBackgroundColorAttributeName, value: highlightColors.first!, range: inlineRange)
                
                highlights.append(HighlightItem(range: matchedRange, color: highlightColors.first!))
                
                if numberOfGroups > 0 {
                    for index in 1...numberOfGroups {
                        guard let range = match?.rangeAt(index), range.length > 0 else { continue }
                        
                        let color = highlightColors[index]
                        
                        lineAttrString.addAttribute(NSBackgroundColorAttributeName, value: color, range: range)
                        highlights.append(HighlightItem(range: range, color: color))
                    }
                }
                
                results.append(TextFindResult(range: matchedRange, lineRange: inlineRange, lineNumber: UInt(lineNumber), attributedLineString: lineAttrString))
                
                // progress indicator
                let informativeFormat = (results.count == 1) ? "%@ string found." : "%@ strings found."
                let informative = String(format: NSLocalizedString(informativeFormat, comment: ""),
                                         integerFormatter.string(from: NSNumber(integerLiteral: highlights.count))!)
                DispatchQueue.main.async {
                    progress.localizedDescription = informative
                }
                })
            
            guard !progress.isCancelled else { return }
            
            DispatchQueue.main.async {
                // highlight
                textView.layoutManager?.removeTemporaryAttribute(NSBackgroundColorAttributeName, forCharacterRange: string.nsRange)
                for highlight in highlights {
                    textView.layoutManager?.addTemporaryAttribute(NSBackgroundColorAttributeName,
                                                                  value: highlight.color, forCharacterRange: highlight.range)
                }
                
                indicator.done()
                
                if highlights.isEmpty {
                    NSBeep()
                    progress.localizedDescription = NSLocalizedString("Not Found", comment: "")
                } else {
                    self.delegate?.textFinder(self, didFinishFindingAll: findString, results: results, textView: textView)
                }
                
                // -> close also if matched since result view will be shown when succeed
                if !results.isEmpty || self.closesIndicatorWhenDone {
                    indicator.dismiss(nil)
                    if let panel = self.findPanelController.window, panel.isVisible {
                        panel.makeKey()
                    }
                }
                
                self.busyTextViews.remove(textView)
            }
        }
        
        self.appendHistory(self.findString, forKey: .findHistory)
    }
    
    
    /// highlight all matched strings
    @IBAction func highlight(_ sender: Any?) {
        
        guard self.checkIsReadyToFind(),
            let textView = self.client else { return }
        
        let integerFormatter = self.integerFormatter
        let regex = self.regex()!
        let scopeRanges = self.scopeRanges
        
        self.busyTextViews.insert(textView)
        
        let numberOfGroups = regex.numberOfCaptureGroups
        let highlightColors = self.highlightColor.decomposite(into: numberOfGroups + 1)
        
        let string = textView.string ?? ""
        
        // setup progress sheet
        guard let documentViewController = textView.window?.windowController?.contentViewController else {
            fatalError("The find target text view must be embedded in a window with its contentViewController.")
        }
        let progress = Progress(totalUnitCount: -1)
        let indicator = ProgressViewController(progress: progress, message: NSLocalizedString("Highlight", comment: ""))!
        documentViewController.presentViewControllerAsSheet(indicator)
        
        DispatchQueue.global().async { [weak self] in
            guard let `self` = self else { return }
            
            var highlights = [HighlightItem]()
            self.enumerateMatchs(in: string, ranges: scopeRanges, using: { (matchedRange: NSRange, match: NSTextCheckingResult?, stop) in
                
                guard !progress.isCancelled else {
                    indicator.dismiss(self)
                    self.busyTextViews.remove(textView)
                    stop = true
                    return
                }
                
                highlights.append(HighlightItem(range: matchedRange, color: highlightColors.first!))
                
                if numberOfGroups > 0 {
                    for index in 1...numberOfGroups {
                        guard let range = match?.rangeAt(index), range.length > 0 else { continue }
                        let color = highlightColors[index]
                        highlights.append(HighlightItem(range: range, color: color))
                    }
                }
                
                // progress indicator
                let informativeFormat = (highlights.count == 1) ? "%@ string found." : "%@ strings found."
                let informative = String(format: NSLocalizedString(informativeFormat, comment: ""),
                                         integerFormatter.string(from: NSNumber(integerLiteral: highlights.count))!)
                DispatchQueue.main.async {
                    progress.localizedDescription = informative
                }
                })
            
            guard !progress.isCancelled else { return }
            
            DispatchQueue.main.async {
                // highlight
                textView.layoutManager?.removeTemporaryAttribute(NSBackgroundColorAttributeName, forCharacterRange: string.nsRange)
                for highlight in highlights {
                    textView.layoutManager?.addTemporaryAttribute(NSBackgroundColorAttributeName,
                                                                  value: highlight.color, forCharacterRange: highlight.range)
                }
                
                indicator.done()
                
                if highlights.isEmpty {
                    NSBeep()
                    progress.localizedDescription = NSLocalizedString("Not Found", comment: "")
                }
                
                if self.closesIndicatorWhenDone {
                    indicator.dismiss(nil)
                    if let panel = self.findPanelController.window, panel.isVisible {
                        panel.makeKey()
                    }
                }
                
                self.busyTextViews.remove(textView)
            }
        }
        
        self.appendHistory(self.findString, forKey: .findHistory)
    }
    
    
    /// remove all of current highlights in the frontmost textView
    @IBAction func unhighlight(_ sender: Any?) {
        
        guard let textView = self.client else { return }
        
        textView.layoutManager?.removeTemporaryAttribute(NSBackgroundColorAttributeName,
                                                         forCharacterRange: textView.string?.nsRange ?? .notFound)
    }
    
    
    /// replace matched string in selection with replacementStirng
    @IBAction func replace(_ sender: Any?) {
        
        guard self.checkIsReadyToFind() else { return }
        
        if self.replace() {
            self.client?.centerSelectionInVisibleArea(self)
            
        } else {
            NSBeep()
        }
        
        self.appendHistory(self.findString, forKey: .findHistory)
        self.appendHistory(self.replacementString, forKey: .replaceHistory)
    }
    
    
    /// replace matched string with replacementStirng and select the next match
    @IBAction func replaceAndFind(_ sender: Any?) {
        
        guard self.checkIsReadyToFind() else { return }
        
        self.replace()
        self.find(forward: true)
    }
    
    
    /// replace all matched strings with given string
    @IBAction func replaceAll(_ sender: Any?) {
        
        guard self.checkIsReadyToFind(),
            let textView = self.client,
            let string = textView.string else { return }
        
        let integerFormatter = self.integerFormatter
        let replacementString = self.replacementString
        let scopeRanges = self.scopeRanges
        let inSelection = self.inSelection
        
        self.busyTextViews.insert(textView)
        
        // setup progress sheet
        guard let documentViewController = textView.window?.windowController?.contentViewController else {
            fatalError("The find target text view must be embedded in a window with its contentViewController.")
        }
        let progress = Progress(totalUnitCount: -1)
        let indicator = ProgressViewController(progress: progress, message: NSLocalizedString("Replace All", comment: ""))!
        documentViewController.presentViewControllerAsSheet(indicator)
        
        DispatchQueue.global().async { [weak self] in
            guard let `self` = self else { return }
            
            var replacementStrings = [String]()
            var replacementRanges = [NSRange]()
            var selectedRanges = [NSRange]()
            var count = 0
            
            // variables to calcurate new selection ranges
            var locationDelta = 1
            var lengthDelta = 0
            
            self.enumerateMatchs(in: string, ranges: scopeRanges, using: { (matchedRange: NSRange, match: NSTextCheckingResult?, stop) in
                
                guard !progress.isCancelled else {
                    indicator.dismiss(self)
                    self.busyTextViews.remove(textView)
                    stop = true
                    return
                }
                
                let replacedString: String = {
                    guard let match = match, let regex = match.regularExpression else { return replacementString }
                    
                    return regex.replacementString(for: match, in: string, offset: 0, template: replacementString)
                }()
                
                replacementStrings.append(replacedString)
                replacementRanges.append(matchedRange)
                count += 1
                
                lengthDelta -= matchedRange.length - replacementString.utf16.count
                
                // progress indicator
                let informativeFormat = (count == 1) ? "%@ string replaced." : "%@ strings replaced."
                let informative = String(format: NSLocalizedString(informativeFormat, comment: ""),
                                         integerFormatter.string(from: NSNumber(integerLiteral: count))!)
                DispatchQueue.main.async {
                    progress.localizedDescription = informative
                }
                
                }, scopeCompletionHandler: { (scopeRange: NSRange) in
                    let selectedRange = NSRange(location: scopeRange.location + locationDelta,
                                                length: scopeRange.length + lengthDelta)
                    locationDelta += selectedRange.length - scopeRange.length
                    lengthDelta = 0
                    selectedRanges.append(selectedRange)
            })
            
            guard !progress.isCancelled else { return }
            
            DispatchQueue.main.async {
                indicator.done()
                
                if count > 0 {
                    // apply found strings to the text view
                    textView.replace(with: replacementStrings, ranges: replacementRanges,
                                     selectedRanges: inSelection ? selectedRanges : nil,
                                     actionName: NSLocalizedString("Replace All", comment: ""))
                } else {
                    NSBeep()
                    progress.localizedDescription = NSLocalizedString("Not Found", comment: "")
                }
                
                if self.closesIndicatorWhenDone {
                    indicator.dismiss(nil)
                    if let panel = self.findPanelController.window, panel.isVisible {
                        panel.makeKey()
                    }
                }
                
                self.busyTextViews.remove(textView)
            }
        }
        
        self.appendHistory(self.findString, forKey: .findHistory)
        self.appendHistory(self.replacementString, forKey: .replaceHistory)
    }
    
    
    /// set selected string to find field
    @IBAction func useSelectionForFind(_ sender: Any?) {
        
        guard let selectedString = self.selectedString else {
            NSBeep()
            return
        }
        
        self.findString = selectedString
        
        // auto-disable regex
        Defaults[.findUsesRegularExpression] = false
    }
    
    
    /// set selected string to replace field
    @IBAction func useSelectionForReplace(_ sender: Any?) {
        
        self.replacementString = self.selectedString ?? ""
    }
    
    
    
    // MARK: Private Methods
    
    /// target text view
    private var client: NSTextView? {
        
        guard let provider = NSApp.target(forAction: #selector(TextFinderClientProvider.textFinderClient)) as? TextFinderClientProvider else { return nil }
        
        return provider.textFinderClient()
    }
    
    
    /// selected string in the current tareget
    private dynamic var selectedString: String? {
        
        guard let selectedRange = self.client?.selectedRange,
              let string = self.client?.string as NSString? else { return nil }
        
        return string.substring(with: selectedRange)
    }
    
    
    /// ranges to find in
    private dynamic var scopeRanges: [NSRange] {
        
        guard let textView = self.client else { return [] }
        
        if self.inSelection {
            return textView.selectedRanges as [NSRange]
        }
        if let range = textView.string?.nsRange {
            return [range]
        }
        
        return []
    }
    
    
    /// find string of which line endings are standardized to LF
    private dynamic var sanitizedFindString: String {
        
        return self.findString.replacingLineEndings(with: .LF)
    }
    
    
    /// regex object with current settings
    private func regex() -> NSRegularExpression? {
        
        return try? NSRegularExpression(pattern: self.sanitizedFindString, options: self.regexOptions)
    }
    
    
    /// perform "Find Next" or "Find Previous" and return number of found
    @discardableResult
    private func find(forward: Bool) -> Int {
        
        guard self.checkIsReadyToFind(),
            let textView = self.client,
            let string = textView.string, !string.isEmpty else { return 0 }
        
        let startLocation = forward ? textView.selectedRange.max : textView.selectedRange.location
        let range = string.nsRange
        
        var matches = [NSRange]()
        self.enumerateMatchs(in: string, ranges: [range], using: { (matchedRange: NSRange, match: NSTextCheckingResult?, stop) in
            matches.append(matchedRange)
            })
        
        guard !matches.isEmpty else { return 0 }
        
        var foundRange: NSRange?
        var lastMatchedRange: NSRange?
        
        for matchedRange in matches {
            if matchedRange.location >= startLocation {
                foundRange = forward ? matchedRange : lastMatchedRange
                break
            }
            
            lastMatchedRange = matchedRange
        }
        
        // wrap search
        let isWrapped = (foundRange == nil && self.isWrap)
        if isWrapped {
            foundRange = forward ? matches.first : matches.last
        }
        
        // found feedback
        if let range = foundRange {
            textView.selectedRange = range
            textView.scrollRangeToVisible(range)
            textView.showFindIndicator(for: range)
            
            if isWrapped, let view = textView.enclosingScrollView?.superview {
                let hudController = HUDController(symbol: .wrap)!
                hudController.isReversed = !forward
                hudController.show(in: view)
            }
        } else {
            NSBeep()
        }
        
        self.delegate?.textFinder(self, didFound: matches.count, textView: textView)
        
        self.appendHistory(self.findString, forKey: .findHistory)
        
        return matches.count
    }
    
    
    /// replace matched string in selection with replacementStirng
    @discardableResult
    private func replace() -> Bool {
        
        guard let textView = self.client,
            let string = textView.string else { return false }
        
        let matchedRange: NSRange
        let replacedString: String
        if self.usesRegularExpression {
            let regex = self.regex()!
            guard let match = regex.firstMatch(in: string, range: textView.selectedRange) else { return false }
            
            matchedRange = match.range
            replacedString = regex.replacementString(for: match, in: string, offset: 0, template: self.replacementString)
            
        } else {
            matchedRange = (string as NSString).range(of: self.sanitizedFindString, options: self.textualOptions, range: textView.selectedRange)
            guard matchedRange.location != NSNotFound else { return false }
            replacedString = self.replacementString
        }
        
        // apply replacement to text view
        return textView.replace(with: replacedString, range: matchedRange,
                                selectedRange: NSRange(location: matchedRange.location, length: replacedString.utf16.count),
                                actionName: NSLocalizedString("Replace", comment: ""))
    }
    
    
    /// enumerate matchs in string using current settings
    private func enumerateMatchs(in string: String?, ranges: [NSRange], using block: (NSRange, NSTextCheckingResult?, inout Bool) -> Void, scopeCompletionHandler: ((NSRange) -> Void)? = nil) {
        
        if self.usesRegularExpression {
            self.enumerateRegularExpressionMatchs(in: string, ranges: ranges, using: block, scopeCompletionHandler: scopeCompletionHandler)
        } else {
            self.enumerateTextualMatchs(in: string, ranges: ranges, using: block, scopeCompletionHandler: scopeCompletionHandler)
        }
    }
    
    
    /// enumerate matchs in string using textual search
    private func enumerateTextualMatchs(in string: String?, ranges: [NSRange], using block: (NSRange, NSTextCheckingResult?, inout Bool) -> Void, scopeCompletionHandler: ((NSRange) -> Void)? = nil) {
        
        guard let string = string as NSString?, string.length > 0 else { return }
        
        let findString = self.sanitizedFindString
        let options = self.textualOptions
        
        for scopeRange in ranges {
            var searchRange = scopeRange
            
            while searchRange.location != NSNotFound {
                searchRange.length = string.length - searchRange.location
                let foundRange = string.range(of: findString, options: options, range: searchRange)
                
                guard foundRange.max <= scopeRange.max else { break }
                
                var stop = false
                block(foundRange, nil, &stop)
                
                guard !stop else { return }
                
                searchRange.location = foundRange.max
            }
            
            scopeCompletionHandler?(scopeRange)
        }
    }
    
    
    /// enumerate matchs in string using regular expression
    private func enumerateRegularExpressionMatchs(in string: String?, ranges: [NSRange], using block: (NSRange, NSTextCheckingResult?, inout Bool) -> Void, scopeCompletionHandler: ((NSRange) -> Void)? = nil) {
        
        guard let string = string, !string.isEmpty else { return }
        
        let regex = self.regex()!
        
        for scopeRange in ranges {
            regex.enumerateMatches(in: string, range: scopeRange, using: { (result, flags, stop) in
                guard let result = result else { return }
                
                var ioStop = false
                block(result.range, result, &ioStop)
                stop.pointee = ObjCBool(ioStop)
            })
            
            scopeCompletionHandler?(scopeRange)
        }
    }
    
    
    /// check Find can be performed and alert if needed
    private func checkIsReadyToFind() -> Bool {
        
        guard let client = self.client else {
            NSBeep()
            return false
        }
        
        guard !self.busyTextViews.contains(client) else {
            NSBeep()
            return false
        }
        
        guard self.findPanelController.window?.attachedSheet == nil else {
            self.findPanelController.showWindow(self)
            NSBeep()
            return false
        }
        
        guard !self.findString.isEmpty else {
            NSBeep()
            return false
        }
        
        // check regular expression syntax
        if self.usesRegularExpression {
            do {
                _ = try NSRegularExpression(pattern: self.sanitizedFindString, options: self.regexOptions)
            } catch let error {
                let failureReason: String? = (error as? LocalizedError)?.failureReason
                let newError = TextFinderError.regularExpression(reason: failureReason)
                
                self.findPanelController.showWindow(self)
                self.presentError(newError, modalFor: self.findPanelController.window!, delegate: nil, didPresent: nil, contextInfo: nil)
                
                NSBeep()
                return false
            }
        }
        
        return true
    }
    
    
    /// find string from global domain
    private var findStringInPasteboard: String? {
        
        get {
            let pasteboard = NSPasteboard(name: NSFindPboard)
            return pasteboard.string(forType: NSStringPboardType)
        }
        
        set {
            guard let string = newValue, !string.isEmpty else { return }
            
            let pasteboard = NSPasteboard(name: NSFindPboard)
            
            pasteboard.declareTypes([NSStringPboardType], owner: nil)
            pasteboard.setString(string, forType: NSStringPboardType)
        }
    }
    
    
    /// append given string to history with the user defaults key
    private func appendHistory(_ string: String, forKey key: DefaultKey<[String]>) {
        
        guard !string.isEmpty else { return }
        
        // append new string to history
        var history = Defaults[key] ?? []
        history.remove(string)  // remove duplicated item
        history.append(string)
        if history.count > MaxHistorySize {  // remove overflow
            history.removeFirst(history.count - MaxHistorySize)
        }
        
        Defaults[key] = history
    }
    
    
    
    // MARK: TextFinder Settings Provider Protocol
    
    /// return value from user defaults
    fileprivate var usesRegularExpression: Bool {
        
        return Defaults[.findUsesRegularExpression]
    }
    
    
    /// return value from user defaults
    fileprivate var isWrap: Bool {
        
        return Defaults[.findIsWrap]
    }
    
    
    /// return value from user defaults
    fileprivate var inSelection: Bool {
        
        return Defaults[.findInSelection]
    }
    
    
    /// return value from user defaults
    fileprivate var textualOptions: NSString.CompareOptions {
        
        var options = NSString.CompareOptions()
        
        if Defaults[.findIgnoresCase]               { options.update(with: .caseInsensitive) }
        if Defaults[.findTextIsLiteralSearch]       { options.update(with: .literal) }
        if Defaults[.findTextIgnoresDiacriticMarks] { options.update(with: .diacriticInsensitive) }
        if Defaults[.findTextIgnoresWidth]          { options.update(with: .widthInsensitive) }
        
        return options
    }
    
    
    /// return value from user defaults
    fileprivate var regexOptions: NSRegularExpression.Options {
        
        var options = NSRegularExpression.Options()
        
        if Defaults[.findIgnoresCase]                { options.update(with: .caseInsensitive) }
        if Defaults[.findRegexIsSingleline]          { options.update(with: .dotMatchesLineSeparators) }
        if Defaults[.findRegexIsMultiline]           { options.update(with: .anchorsMatchLines) }
        if Defaults[.findRegexUsesUnicodeBoundaries] { options.update(with: .useUnicodeWordBoundaries) }
        
        return options
    }
    
    
    /// return value from user defaults
    fileprivate var closesIndicatorWhenDone: Bool {
        
        return Defaults[.findClosesIndicatorWhenDone]
    }
    
    
    /// return if sync search string with other applications
    fileprivate var sharesFindString: Bool {
        
        return Defaults[.syncFindPboard]
    }
    
}



// MARK: - Error

private enum TextFinderError: LocalizedError {
    
    case regularExpression(reason: String?)
    
    
    var errorDescription: String? {
        
        return NSLocalizedString("Invalid regular expression", comment: "")
    }
    
    
    var recoverySuggestion: String? {
        
        switch self {
        case .regularExpression(let reason):
            return reason
        }
    }
    
}
