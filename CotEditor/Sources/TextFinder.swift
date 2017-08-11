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


private struct HighlightItem {
    
    let range: NSRange
    let color: NSColor
    
}



// MARK: -

final class TextFinder: NSResponder {
    
    static let shared = TextFinder()
    
    
    // MARK: Public Properties
    
    dynamic var findString = "" {
        
        didSet {
            if UserDefaults.standard[.syncFindPboard] {
                NSPasteboard.findString = self.findString
            }
        }
    }
    dynamic var replacementString = ""
    
    weak var delegate: TextFinderDelegate?
    
    
    // MARK: Private Properties
    
    private lazy var findPanelController: FindPanelController = NSStoryboard(name: "FindPanel", bundle: nil).instantiateInitialController() as! FindPanelController
    private let highlightColor: NSColor
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    private override init() {
        
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
    @objc private func applicationDidBecomeActive(_ notification: Notification) {
        
        if UserDefaults.standard[.syncFindPboard] {
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
        
        guard let (textView, textFind) = self.prepareTextFind() else { return }
        
        textView.isEditable = false
        
        let highlightColors = self.highlightColor.decomposite(into: textFind.numberOfCaptureGroups + 1)
        let lineRegex = try! NSRegularExpression(pattern: "\n")
        
        // setup progress sheet
        let progress = TextFindProgress(format: .find)
        let indicator = ProgressViewController(progress: progress, message: NSLocalizedString("Find All", comment: ""))
        textView.viewControllerForSheet?.presentViewControllerAsSheet(indicator)
        
        DispatchQueue.global().async { [weak self] in
            guard let strongSelf = self else { return }
            
            var results = [TextFindResult]()
            var highlights = [HighlightItem]()
            
            var lineNumber = 1
            var lineCountedLocation = 0
            
            textFind.findAll { (matches: [NSRange], stop) in
                guard !progress.isCancelled else {
                    stop = true
                    return
                }
                
                let matchedRange = matches[0]
                
                // calculate line number
                let diffRange = NSRange(location: lineCountedLocation, length: matchedRange.location - lineCountedLocation)
                lineNumber += lineRegex.numberOfMatches(in: textFind.string, range: diffRange)
                lineCountedLocation = matchedRange.location
                
                // highlight both string in textView and line string for result table
                let lineRange = (textFind.string as NSString).lineRange(for: matchedRange)
                let inlineRange = NSRange(location: matchedRange.location - lineRange.location,
                                          length: matchedRange.length)
                let lineString = (textFind.string as NSString).substring(with: lineRange)
                let attrLineString = NSMutableAttributedString(string: lineString)
                
                for (index, range) in matches.enumerated() {
                    guard range.length > 0 else { continue }
                    
                    let color = highlightColors[index]
                    let inlineRange = NSRange(location: range.location - lineRange.location, length: range.length)
                    
                    attrLineString.addAttribute(NSBackgroundColorAttributeName, value: color, range: inlineRange)
                    highlights.append(HighlightItem(range: range, color: color))
                }
                
                results.append(TextFindResult(range: matchedRange, lineRange: inlineRange, lineNumber: lineNumber, attributedLineString: attrLineString))
                
                progress.needsUpdateDescription(count: results.count)
            }
            
            DispatchQueue.main.sync {
                textView.isEditable = true
                
                guard !progress.isCancelled else {
                    indicator.dismiss(nil)
                    return
                }
                
                // highlight
                textView.layoutManager?.removeTemporaryAttribute(NSBackgroundColorAttributeName, forCharacterRange: textFind.string.nsRange)
                for highlight in highlights {
                    textView.layoutManager?.addTemporaryAttribute(NSBackgroundColorAttributeName,
                                                                  value: highlight.color, forCharacterRange: highlight.range)
                }
                
                indicator.done()
                
                if highlights.isEmpty {
                    NSBeep()
                    progress.localizedDescription = NSLocalizedString("Not Found", comment: "")
                }
                
                strongSelf.delegate?.textFinder(strongSelf, didFinishFindingAll: textFind.findString, results: results, textView: textView)
                
                // -> close also if matched since result view will be shown when succeed
                if !results.isEmpty || UserDefaults.standard[.findClosesIndicatorWhenDone] {
                    indicator.dismiss(nil)
                    if let panel = strongSelf.findPanelController.window, panel.isVisible {
                        panel.makeKey()
                    }
                }
            }
        }
        
        UserDefaults.standard.appendHistory(self.findString, forKey: .findHistory)
    }
    
    
    /// highlight all matched strings
    @IBAction func highlight(_ sender: Any?) {
        
        guard let (textView, textFind) = self.prepareTextFind() else { return }
        
        textView.isEditable = false
        
        let highlightColors = self.highlightColor.decomposite(into: textFind.numberOfCaptureGroups + 1)
        
        // setup progress sheet
        let progress = TextFindProgress(format: .find)
        let indicator = ProgressViewController(progress: progress, message: NSLocalizedString("Highlight", comment: ""))
        textView.viewControllerForSheet?.presentViewControllerAsSheet(indicator)
        
        DispatchQueue.global().async { [weak self] in
            guard let strongSelf = self else { return }
            
            var highlights = [HighlightItem]()
            
            textFind.findAll { (matches: [NSRange], stop) in
                guard !progress.isCancelled else {
                    stop = true
                    return
                }
                
                for (index, range) in matches.enumerated() {
                    guard range.length > 0 else { continue }
                    
                    let color = highlightColors[index]
                    highlights.append(HighlightItem(range: range, color: color))
                }
                
                progress.needsUpdateDescription(count: highlights.count)
            }
            
            DispatchQueue.main.sync {
                textView.isEditable = true
                
                guard !progress.isCancelled else {
                    indicator.dismiss(nil)
                    return
                }
                
                // highlight
                textView.layoutManager?.removeTemporaryAttribute(NSBackgroundColorAttributeName, forCharacterRange: textFind.string.nsRange)
                for highlight in highlights {
                    textView.layoutManager?.addTemporaryAttribute(NSBackgroundColorAttributeName,
                                                                  value: highlight.color, forCharacterRange: highlight.range)
                }
                
                indicator.done()
                
                if highlights.isEmpty {
                    NSBeep()
                    progress.localizedDescription = NSLocalizedString("Not Found", comment: "")
                }
                
                if UserDefaults.standard[.findClosesIndicatorWhenDone] {
                    indicator.dismiss(nil)
                    if let panel = strongSelf.findPanelController.window, panel.isVisible {
                        panel.makeKey()
                    }
                }
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
        
        self.replace()
        self.find(forward: true)
        
        UserDefaults.standard.appendHistory(self.findString, forKey: .findHistory)
        UserDefaults.standard.appendHistory(self.replacementString, forKey: .replaceHistory)
    }
    
    
    /// replace all matched strings with given string
    @IBAction func replaceAll(_ sender: Any?) {
        
        guard let (textView, textFind) = self.prepareTextFind() else { return }
        
        textView.isEditable = false
        
        let replacementString = self.replacementString
        
        // setup progress sheet
        let progress = TextFindProgress(format: .replacement)
        let indicator = ProgressViewController(progress: progress, message: NSLocalizedString("Replace All", comment: ""))
        textView.viewControllerForSheet?.presentViewControllerAsSheet(indicator)
        
        DispatchQueue.global().async { [weak self] in
            guard let strongSelf = self else { return }
            
            var count = 0
            let (replacementItems, selectedRanges) = textFind.replaceAll(with: replacementString) { (stop) in
                guard !progress.isCancelled else {
                    stop = true
                    return
                }
                
                count += 1
                
                progress.needsUpdateDescription(count: count)
            }
            
            DispatchQueue.main.sync {
                textView.isEditable = true
                
                guard !progress.isCancelled else {
                    indicator.dismiss(nil)
                    return
                }
                
                indicator.done()
                
                if !replacementItems.isEmpty {
                    let replacementStrings = replacementItems.map { $0.string }
                    let replacementRanges = replacementItems.map { $0.range }
                    
                    // apply found strings to the text view
                    textView.replace(with: replacementStrings, ranges: replacementRanges, selectedRanges: selectedRanges,
                                     actionName: NSLocalizedString("Replace All", comment: ""))
                } else {
                    NSBeep()
                    progress.localizedDescription = NSLocalizedString("Not Found", comment: "")
                }
                
                if UserDefaults.standard[.findClosesIndicatorWhenDone] {
                    indicator.dismiss(nil)
                    if let panel = strongSelf.findPanelController.window, panel.isVisible {
                        panel.makeKey()
                    }
                }
                
                strongSelf.delegate?.textFinder(strongSelf, didReplace: count, textView: textView)
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
        UserDefaults.standard[.findUsesRegularExpression] = false
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
    private var selectedString: String? {
        
        guard let selectedRange = self.client?.selectedRange,
              let string = self.client?.string as NSString? else { return nil }
        
        return string.substring(with: selectedRange)
    }
    
    
    /// find string of which line endings are standardized to LF
    private var sanitizedFindString: String {
        
        return self.findString.replacingLineEndings(with: .LF)
    }
    
    
    /// check Find can be performed and alert if needed
    private func prepareTextFind() -> (NSTextView, TextFind)? {
        
        guard
            let textView = self.client,
            textView.isEditable,
            let string = textView.textStorage?.string  // copy string
            else {
                NSBeep()
                return nil
        }
        
        guard self.findPanelController.window?.attachedSheet == nil else {
            self.findPanelController.showWindow(self)
            NSBeep()
            return nil
        }
        
        let settings = TextFind.Settings(defaults: UserDefaults.standard)
        let textFind: TextFind
        do {
            textFind = try TextFind(for: string, findString: self.sanitizedFindString, settings: settings, selectedRanges: textView.selectedRanges as! [NSRange])
        } catch {
            switch error {
            case TextFindError.regularExpression:
                self.findPanelController.showWindow(self)
                self.presentError(error, modalFor: self.findPanelController.window!, delegate: nil, didPresent: nil, contextInfo: nil)
            default: break
            }
            NSBeep()
            return nil
        }
        
        return (textView, textFind)
    }
    
    
    /// perform "Find Next" or "Find Previous" and return number of found
    @discardableResult
    private func find(forward: Bool) -> Int {
        
        guard let (textView, textFind) = self.prepareTextFind() else { return 0 }
        
        let result = textFind.find(forward: forward)
        
        // found feedback
        if let range = result.range {
            textView.selectedRange = range
            textView.scrollRangeToVisible(range)
            textView.showFindIndicator(for: range)
            
            if result.wrapped, let view = textView.enclosingScrollView?.superview {
                let hudController = HUDController(symbol: .wrap)!
                hudController.isReversed = !forward
                hudController.show(in: view)
            }
        } else {
            NSBeep()
        }
        
        self.delegate?.textFinder(self, didFind: result.count, textView: textView)
        
        UserDefaults.standard.appendHistory(self.findString, forKey: .findHistory)
        
        return result.count
    }
    
    
    /// replace matched string in selection with replacementStirng
    @discardableResult
    private func replace() -> Bool {
        
        guard
            let (textView, textFind) = self.prepareTextFind(),
            let result = textFind.replace(with: self.replacementString)
            else { return false }
        
        // apply replacement to text view
        return textView.replace(with: result.string, range: result.range,
                                selectedRange: NSRange(location: result.range.location, length: result.string.utf16.count),
                                actionName: NSLocalizedString("Replace", comment: ""))
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
        history.remove(string)  // remove duplicated item
        history.append(string)
        if history.count > UserDefaults.MaxHistorySize {  // remove overflow
            history.removeFirst(history.count - UserDefaults.MaxHistorySize)
        }
        
        self[key] = history
    }
    
}


private extension TextFind.Settings {
    
    init(defaults: UserDefaults) {
        
        var textualOptions = NSString.CompareOptions()
        if defaults[.findIgnoresCase]               { textualOptions.update(with: .caseInsensitive) }
        if defaults[.findTextIsLiteralSearch]       { textualOptions.update(with: .literal) }
        if defaults[.findTextIgnoresDiacriticMarks] { textualOptions.update(with: .diacriticInsensitive) }
        if defaults[.findTextIgnoresWidth]          { textualOptions.update(with: .widthInsensitive) }
        
        var regexOptions = NSRegularExpression.Options()
        if defaults[.findIgnoresCase]                { regexOptions.update(with: .caseInsensitive) }
        if defaults[.findRegexIsSingleline]          { regexOptions.update(with: .dotMatchesLineSeparators) }
        if defaults[.findRegexIsMultiline]           { regexOptions.update(with: .anchorsMatchLines) }
        if defaults[.findRegexUsesUnicodeBoundaries] { regexOptions.update(with: .useUnicodeWordBoundaries) }
        
        self.init(usesRegularExpression: defaults[.findUsesRegularExpression],
                  isWrap: defaults[.findIsWrap],
                  inSelection: defaults[.findInSelection],
                  textualOptions: textualOptions,
                  regexOptions: regexOptions,
                  unescapesReplacementString: defaults[.findRegexUnescapesReplacementString])
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
