/*
 
 TextFinder.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2015-01-03.
 
 ------------------------------------------------------------------------------
 
 © 2015-2017 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 https://www.apache.org/licenses/LICENSE-2.0
 
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
    func textFinder(_ textFinder: TextFinder, didFind numberOfFound: Int, textView: NSTextView)
    func textFinder(_ textFinder: TextFinder, didReplace numberOfReplaced: Int, textView: NSTextView)
    
}


struct TextFindResult {
    
    let range: NSRange
    let lineRange: NSRange
    let lineNumber: Int
    let attributedLineString: NSAttributedString
    
}


private protocol TextFinderSettingsProvider {
    
    var usesRegularExpression: Bool { get }
    var isWrap: Bool { get }
    var inSelection: Bool { get }
    var textualOptions: NSString.CompareOptions { get }
    var regexOptions: NSRegularExpression.Options { get }
    var unescapesReplacementString: Bool { get }
    var closesIndicatorWhenDone: Bool { get }
    var sharesFindString: Bool { get }
    
}


private struct HighlightItem {
    
    let range: NSRange
    let color: NSColor
    
}



// MARK:

final class TextFinder: NSResponder {
    
    static let shared = TextFinder()
    
    
    // MARK: Public Properties
    
    dynamic var findString = "" {
        
        didSet {
            if self.settings.sharesFindString {
                NSPasteboard.findString = self.findString
            }
        }
    }
    dynamic var replacementString = ""
    
    weak var delegate: TextFinderDelegate?
    
    
    // MARK: Private Properties
    
    private lazy var findPanelController: FindPanelController = NSStoryboard(name: "FindPanel", bundle: nil).instantiateInitialController() as! FindPanelController
    private let settings: TextFinderSettingsProvider = UserDefaults.standard
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
        // It might better when it can be set in theme also for incompatible characters highlight.
        // Just because I'm lazy.
        
        super.init()
        
        // add to responder chain
        NSApp.nextResponder = self
        
        // observe application activation to sync find string with other apps
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: .NSApplicationDidBecomeActive, object: nil)
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
        
        if self.settings.sharesFindString {
            if let sharedFindString = NSPasteboard.findString {
                self.findString = sharedFindString
            }
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
        let scopeRanges = self.scopeRanges
        
        self.busyTextViews.insert(textView)
        
        let numberOfGroups = self.regex()?.numberOfCaptureGroups ?? 0
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
            guard let strongSelf = self else { return }
            
            var results = [TextFindResult]()
            var highlights = [HighlightItem]()
            
            var lineNumber = 1
            var lineCountedLocation = 0
            
            strongSelf.enumerateMatchs(in: string, ranges: scopeRanges, using: { (matchedRange: NSRange, match: NSTextCheckingResult?, stop) in
                
                guard !progress.isCancelled else {
                    DispatchQueue.main.async {
                        indicator.dismiss(nil)
                    }
                    strongSelf.busyTextViews.remove(textView)
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
                let attrLineString = NSMutableAttributedString(string: lineString)
                
                attrLineString.addAttribute(NSBackgroundColorAttributeName, value: highlightColors.first!, range: inlineRange)
                
                highlights.append(HighlightItem(range: matchedRange, color: highlightColors.first!))
                
                if numberOfGroups > 0 {
                    for index in 1...numberOfGroups {
                        guard let range = match?.rangeAt(index), range.length > 0 else { continue }
                        
                        let color = highlightColors[index]
                        let inlineRange = NSRange(location: range.location - lineRange.location, length: range.length)
                        
                        attrLineString.addAttribute(NSBackgroundColorAttributeName, value: color, range: inlineRange)
                        highlights.append(HighlightItem(range: range, color: color))
                    }
                }
                
                results.append(TextFindResult(range: matchedRange, lineRange: inlineRange, lineNumber: lineNumber, attributedLineString: attrLineString))
                
                // progress indicator
                let informativeFormat = (results.count == 1) ? "%@ string found." : "%@ strings found."
                let informative = String(format: NSLocalizedString(informativeFormat, comment: ""),
                                         integerFormatter.string(from: NSNumber(integerLiteral: highlights.count))!)
                DispatchQueue.main.async { [weak progress] in
                    progress?.localizedDescription = informative
                }
                })
            
            guard !progress.isCancelled else { return }
            
            DispatchQueue.main.sync {
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
                
                strongSelf.delegate?.textFinder(strongSelf, didFinishFindingAll: findString, results: results, textView: textView)
                
                // -> close also if matched since result view will be shown when succeed
                if !results.isEmpty || strongSelf.settings.closesIndicatorWhenDone {
                    indicator.dismiss(nil)
                    if let panel = strongSelf.findPanelController.window, panel.isVisible {
                        panel.makeKey()
                    }
                }
                
                strongSelf.busyTextViews.remove(textView)
            }
        }
        
        UserDefaults.standard.appendHistory(self.findString, forKey: .findHistory)
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
            guard let strongSelf = self else { return }
            
            var highlights = [HighlightItem]()
            strongSelf.enumerateMatchs(in: string, ranges: scopeRanges, using: { (matchedRange: NSRange, match: NSTextCheckingResult?, stop) in
                
                guard !progress.isCancelled else {
                    DispatchQueue.main.async {
                        indicator.dismiss(nil)
                    }
                    strongSelf.busyTextViews.remove(textView)
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
                DispatchQueue.main.async { [weak progress] in
                    progress?.localizedDescription = informative
                }
                })
            
            guard !progress.isCancelled else { return }
            
            DispatchQueue.main.sync {
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
                
                if strongSelf.settings.closesIndicatorWhenDone {
                    indicator.dismiss(nil)
                    if let panel = strongSelf.findPanelController.window, panel.isVisible {
                        panel.makeKey()
                    }
                }
                
                strongSelf.busyTextViews.remove(textView)
            }
        }
        
        UserDefaults.standard.appendHistory(self.findString, forKey: .findHistory)
    }
    
    
    /// remove all of current highlights in the frontmost textView
    @IBAction func unhighlight(_ sender: Any?) {
        
        guard
            let textView = self.client,
            let range = textView.string?.nsRange
            else { return }
        
        textView.layoutManager?.removeTemporaryAttribute(NSBackgroundColorAttributeName, forCharacterRange: range)
    }
    
    
    /// replace matched string in selection with replacementStirng
    @IBAction func replace(_ sender: Any?) {
        
        guard self.checkIsReadyToFind() else { return }
        
        if self.replace() {
            self.client?.centerSelectionInVisibleArea(self)
            
        } else {
            NSBeep()
        }
        
        UserDefaults.standard.appendHistory(self.findString, forKey: .findHistory)
        UserDefaults.standard.appendHistory(self.replacementString, forKey: .replaceHistory)
    }
    
    
    /// replace matched string with replacementStirng and select the next match
    @IBAction func replaceAndFind(_ sender: Any?) {
        
        guard self.checkIsReadyToFind() else { return }
        
        self.replace()
        self.find(forward: true)
        
        UserDefaults.standard.appendHistory(self.findString, forKey: .findHistory)
        UserDefaults.standard.appendHistory(self.replacementString, forKey: .replaceHistory)
    }
    
    
    /// replace all matched strings with given string
    @IBAction func replaceAll(_ sender: Any?) {
        
        guard self.checkIsReadyToFind(),
            let textView = self.client,
            let string = textView.string else { return }
        
        let integerFormatter = self.integerFormatter
        let replacementString = (self.settings.usesRegularExpression && self.settings.unescapesReplacementString)
            ? self.replacementString.unescaped
            : self.replacementString
        let scopeRanges = self.scopeRanges
        let inSelection = self.settings.inSelection
        
        self.busyTextViews.insert(textView)
        
        // setup progress sheet
        guard let documentViewController = textView.window?.windowController?.contentViewController else {
            fatalError("The find target text view must be embedded in a window with its contentViewController.")
        }
        let progress = Progress(totalUnitCount: -1)
        let indicator = ProgressViewController(progress: progress, message: NSLocalizedString("Replace All", comment: ""))!
        documentViewController.presentViewControllerAsSheet(indicator)
        
        DispatchQueue.global().async { [weak self] in
            guard let strongSelf = self else { return }
            
            var replacementStrings = [String]()
            var replacementRanges = [NSRange]()
            var selectedRanges = [NSRange]()
            var count = 0
            
            // variables to calculate new selection ranges
            var locationDelta = 1
            var lengthDelta = 0
            
            strongSelf.enumerateMatchs(in: string, ranges: scopeRanges, using: { (matchedRange: NSRange, match: NSTextCheckingResult?, stop) in
                
                guard !progress.isCancelled else {
                    DispatchQueue.main.async {
                        indicator.dismiss(nil)
                    }
                    strongSelf.busyTextViews.remove(textView)
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
                DispatchQueue.main.async { [weak progress] in
                    progress?.localizedDescription = informative
                }
                
                }, scopeCompletionHandler: { (scopeRange: NSRange) in
                    let selectedRange = NSRange(location: scopeRange.location + locationDelta,
                                                length: scopeRange.length + lengthDelta)
                    locationDelta += selectedRange.length - scopeRange.length
                    lengthDelta = 0
                    selectedRanges.append(selectedRange)
            })
            
            guard !progress.isCancelled else { return }
            
            DispatchQueue.main.sync {
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
                
                if strongSelf.settings.closesIndicatorWhenDone {
                    indicator.dismiss(nil)
                    if let panel = strongSelf.findPanelController.window, panel.isVisible {
                        panel.makeKey()
                    }
                }
                
                strongSelf.delegate?.textFinder(strongSelf, didReplace: count, textView: textView)
                
                strongSelf.busyTextViews.remove(textView)
            }
        }
        
        UserDefaults.standard.appendHistory(self.findString, forKey: .findHistory)
        UserDefaults.standard.appendHistory(self.replacementString, forKey: .replaceHistory)
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
        
        if self.settings.inSelection {
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
        
        return try? NSRegularExpression(pattern: self.sanitizedFindString, options: self.settings.regexOptions)
    }
    
    
    /// perform "Find Next" or "Find Previous" and return number of found
    @discardableResult
    private func find(forward: Bool) -> Int {
        
        guard self.checkIsReadyToFind(),
            let textView = self.client,
            let string = textView.string, !string.isEmpty else { return 0 }
        
        let selectedRange = textView.selectedRange
        let startLocation = forward ? selectedRange.max : selectedRange.location
        
        var forwardMatches = [NSRange]()  // matches after the start location
        let forwardRange = NSRange(location: startLocation, length: string.utf16.count - startLocation)
        self.enumerateMatchs(in: string, ranges: [forwardRange], using: { (matchedRange: NSRange, match: NSTextCheckingResult?, stop) in
            forwardMatches.append(matchedRange)
        })
        
        var wrappedMatches = [NSRange]()  // matches before the start location
        var intersectionMatches = [NSRange]()  // matches including the start location
        self.enumerateMatchs(in: string, ranges: [string.nsRange], using: { (matchedRange: NSRange, match: NSTextCheckingResult?, stop) in
            if matchedRange.location >= startLocation {
                stop = true
                return
            }
            if matchedRange.contains(location: startLocation) {
                intersectionMatches.append(matchedRange)
            } else {
                wrappedMatches.append(matchedRange)
            }
        })
        
        var foundRange: NSRange? = forward ? forwardMatches.first : wrappedMatches.last
        
        // wrap search
        let isWrapped = (foundRange == nil && self.settings.isWrap)
        if isWrapped {
            foundRange = forward ? (wrappedMatches + intersectionMatches).first : (intersectionMatches + forwardMatches).last
        }
        
        let count = forwardMatches.count + wrappedMatches.count + intersectionMatches.count
        
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
        
        self.delegate?.textFinder(self, didFind: count, textView: textView)
        
        UserDefaults.standard.appendHistory(self.findString, forKey: .findHistory)
        
        return count
    }
    
    
    /// replace matched string in selection with replacementStirng
    @discardableResult
    private func replace() -> Bool {
        
        guard let textView = self.client,
            let string = textView.string else { return false }
        
        let matchedRange: NSRange
        let replacedString: String
        if self.settings.usesRegularExpression {
            let regex = self.regex()!
            guard let match = regex.firstMatch(in: string, range: textView.selectedRange) else { return false }
            
            let template = self.settings.unescapesReplacementString ? self.replacementString.unescaped : self.replacementString
            
            matchedRange = match.range
            replacedString = regex.replacementString(for: match, in: string, offset: 0, template: template)
            
        } else {
            matchedRange = (string as NSString).range(of: self.sanitizedFindString, options: self.settings.textualOptions, range: textView.selectedRange)
            guard matchedRange.location != NSNotFound else { return false }
            replacedString = self.replacementString
        }
        
        // apply replacement to text view
        return textView.replace(with: replacedString, range: matchedRange,
                                selectedRange: NSRange(location: matchedRange.location, length: replacedString.utf16.count),
                                actionName: NSLocalizedString("Replace", comment: ""))
    }
    
    
    /// enumerate matchs in string using current settings
    private func enumerateMatchs(in string: String, ranges: [NSRange], using block: (NSRange, NSTextCheckingResult?, inout Bool) -> Void, scopeCompletionHandler: ((NSRange) -> Void)? = nil) {
        
        if self.settings.usesRegularExpression {
            self.enumerateRegularExpressionMatchs(in: string, ranges: ranges, using: block, scopeCompletionHandler: scopeCompletionHandler)
        } else {
            self.enumerateTextualMatchs(in: string, ranges: ranges, using: block, scopeCompletionHandler: scopeCompletionHandler)
        }
    }
    
    
    /// enumerate matchs in string using textual search
    private func enumerateTextualMatchs(in string: String, ranges: [NSRange], using block: (NSRange, NSTextCheckingResult?, inout Bool) -> Void, scopeCompletionHandler: ((NSRange) -> Void)? = nil) {
        
        guard !string.isEmpty else { return }
        
        let nsString = string as NSString
        let findString = self.sanitizedFindString
        let options = self.settings.textualOptions
        
        for scopeRange in ranges {
            var searchRange = scopeRange
            
            while searchRange.location != NSNotFound {
                searchRange.length = nsString.length - searchRange.location
                let foundRange = nsString.range(of: findString, options: options, range: searchRange)
                
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
    private func enumerateRegularExpressionMatchs(in string: String, ranges: [NSRange], using block: (NSRange, NSTextCheckingResult?, inout Bool) -> Void, scopeCompletionHandler: ((NSRange) -> Void)? = nil) {
        
        guard !string.isEmpty else { return }
        
        let regex = self.regex()!
        let options: NSRegularExpression.MatchingOptions = [.withTransparentBounds, .withoutAnchoringBounds]
        
        for scopeRange in ranges {
            regex.enumerateMatches(in: string, options: options, range: scopeRange, using: { (result, flags, stop) in
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
        if self.settings.usesRegularExpression {
            do {
                _ = try NSRegularExpression(pattern: self.sanitizedFindString, options: self.settings.regexOptions)
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
    
}



// MARK: - UserDefaults

extension UserDefaults: TextFinderSettingsProvider {
    
    /// return value from user defaults
    var usesRegularExpression: Bool {
        
        return self[.findUsesRegularExpression]
    }
    
    
    /// return value from user defaults
    var isWrap: Bool {
        
        return self[.findIsWrap]
    }
    
    
    /// return value from user defaults
    var inSelection: Bool {
        
        return self[.findInSelection]
    }
    
    
    /// return value from user defaults
    var textualOptions: NSString.CompareOptions {
        
        var options = NSString.CompareOptions()
        
        if self[.findIgnoresCase]               { options.update(with: .caseInsensitive) }
        if self[.findTextIsLiteralSearch]       { options.update(with: .literal) }
        if self[.findTextIgnoresDiacriticMarks] { options.update(with: .diacriticInsensitive) }
        if self[.findTextIgnoresWidth]          { options.update(with: .widthInsensitive) }
        
        return options
    }
    
    
    /// return value from user defaults
    var regexOptions: NSRegularExpression.Options {
        
        var options = NSRegularExpression.Options()
        
        if self[.findIgnoresCase]                { options.update(with: .caseInsensitive) }
        if self[.findRegexIsSingleline]          { options.update(with: .dotMatchesLineSeparators) }
        if self[.findRegexIsMultiline]           { options.update(with: .anchorsMatchLines) }
        if self[.findRegexUsesUnicodeBoundaries] { options.update(with: .useUnicodeWordBoundaries) }
        
        return options
    }
    
    
    /// return value from user defaults
    var unescapesReplacementString: Bool {
        
        return self[.findRegexUnescapesReplacementString]
    }
    
    
    /// return value from user defaults
    var closesIndicatorWhenDone: Bool {
        
        return self[.findClosesIndicatorWhenDone]
    }
    
    
    /// return if sync search string with other applications
    var sharesFindString: Bool {
        
        return self[.syncFindPboard]
    }
    
}



private extension UserDefaults {
    
    private static let MaxHistorySize = 20
    
    
    /// append given string to history with the user defaults key
    func appendHistory(_ string: String, forKey key: DefaultKey<[String]>) {
        
        assert(key == .findHistory || key == .replaceHistory)
        
        guard !string.isEmpty else { return }
        
        // append new string to history
        var history = self[key] ?? []
        history.remove(string)  // remove duplicated item
        history.append(string)
        if history.count > UserDefaults.MaxHistorySize {  // remove overflow
            history.removeFirst(history.count - UserDefaults.MaxHistorySize)
        }
        
        self[key] = history
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



// MARK: Pasteboard

private extension NSPasteboard {
    
    /// find string from global domain
    class var findString: String? {
        
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
    
}
