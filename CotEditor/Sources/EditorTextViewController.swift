//
//  EditorTextViewController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-06-18.
//
//  ---------------------------------------------------------------------------
//
//  © 2004-2007 nakamuxu
//  © 2014-2023 1024jp
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
import Combine
import SwiftUI

final class EditorTextViewController: NSViewController, NSTextViewDelegate {
    
    // MARK: Enums
    
    private enum SerializationKey {
        
        static let showsAdvancedCounter = "showsAdvancedCounter"
    }
    
    
    // MARK: Public Properties
    
    private(set) weak var textView: EditorTextView?
    
    
    // MARK: Private Properties
    
    private var stackView: NSStackView?  { self.view as? NSStackView }
    private weak var lineNumberView: LineNumberView?
    
    private weak var advancedCounterView: NSView?
    private weak var horizontalCounterConstraint: NSLayoutConstraint?
    
    private var orientationObserver: AnyCancellable?
    private var writingDirectionObserver: AnyCancellable?
    private var defaultsObserver: Set<AnyCancellable> = []
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    override func loadView() {
        
        let textView = if #available(macOS 14, *) { EditorTextView() } else { LegacyEditorTextView() }
        textView.delegate = self
        
        let scrollView = BidiScrollView()
        scrollView.verticalScroller = BidiScroller()
        scrollView.horizontalScroller = BidiScroller()
        scrollView.hasVerticalScroller = true
        scrollView.documentView = textView
        scrollView.identifier = NSUserInterfaceItemIdentifier("EditorScrollView")
        
        let lineNumberView = LineNumberView(textView: textView)
        
        let stackView = NSStackView(views: [lineNumberView, scrollView])
        stackView.spacing = 0
        stackView.distribution = .fill
        
        self.view = stackView
        self.lineNumberView = lineNumberView
        self.textView = textView
    }
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // set identifier for state restoration
        self.identifier = NSUserInterfaceItemIdentifier("EditorTextViewController")
        
        // observe text orientation for line number view
        self.orientationObserver = self.textView!.publisher(for: \.layoutOrientation, options: .initial)
            .sink { [weak self] (orientation) in
                guard let self else { return assertionFailure() }
                
                self.stackView?.orientation = switch orientation {
                    case .horizontal: .horizontal
                    case .vertical: .vertical
                    @unknown default: fatalError()
                }
                
                self.lineNumberView?.orientation = orientation
            }
        
        // let line number view position follow writing direction
        self.writingDirectionObserver = self.textView!.publisher(for: \.baseWritingDirection)
            .removeDuplicates()
            .map { $0 == .rightToLeft }
            .sink { [weak self] (isRTL) in
                guard
                    let stackView = self?.stackView,
                    let lineNumberView = self?.lineNumberView
                else { return assertionFailure() }
                
                // set scroller location
                (self?.textView?.enclosingScrollView as? BidiScrollView)?.scrollerDirection = isRTL ? .rightToLeft : .leftToRight
                
                // set line number view location
                let index = isRTL ? stackView.arrangedSubviews.endIndex - 1 : 0
                
                guard stackView.arrangedSubviews[safe: index] != lineNumberView else { return }
                
                stackView.removeArrangedSubview(lineNumberView)
                stackView.insertArrangedSubview(lineNumberView, at: index)
                stackView.needsLayout = true
                stackView.layoutSubtreeIfNeeded()
            }
        
        // toggle visibility of the separator of the line number view
        UserDefaults.standard.publisher(for: .showLineNumberSeparator, initial: true)
            .assign(to: \.drawsSeparator, on: self.lineNumberView!)
            .store(in: &self.defaultsObserver)
    }
    
    
    override func encodeRestorableState(with coder: NSCoder, backgroundQueue queue: OperationQueue) {
        
        super.encodeRestorableState(with: coder, backgroundQueue: queue)
        
        if self.advancedCounterView != nil {
            coder.encode(true, forKey: SerializationKey.showsAdvancedCounter)
        }
    }
    
    
    override func restoreState(with coder: NSCoder) {
        
        super.restoreState(with: coder)
        
        if coder.decodeBool(forKey: SerializationKey.showsAdvancedCounter) {
            self.showAdvancedCharacterCounter()
        }
    }
    
    
    
    // MARK: Text View Delegate
    
    func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
        
        if textView.undoManager?.isUndoing == true { return true }  // = undo
        
        guard let textView = textView as? EditorTextView else { return true }
        
        if textView.isApprovedTextChange { return true }
        
        // standardize line endings to the document line ending
        if let replacementString,  // = only attributes changed
           replacementString.lineEndingRanges().map(\.value).contains(where: { $0 != textView.lineEnding })
        {
            return !textView.replace(with: replacementString.replacingLineEndings(with: textView.lineEnding),
                                     range: affectedCharRange, selectedRange: nil)
        }
        
        return true
    }
    
    
    func textView(_ view: NSTextView, menu: NSMenu, for event: NSEvent, at charIndex: Int) -> NSMenu? {
        
        // append Script menu
        if let scriptMenu = ScriptManager.shared.contextualMenu {
            let item = NSMenuItem()
            item.title = ""
            item.setAccessibilityLabel(String(localized: "Script"))
            item.image = NSImage(systemSymbolName: "applescript.fill", accessibilityDescription: String(localized: "Script"))
            item.toolTip = String(localized: "Script")
            item.submenu = scriptMenu
            
            menu.addItem(item)
        }
        
        // add "Inspect Character" menu item if single character is selected
        if self.textView?.selectsSingleCharacter == true {
            menu.insertItem(withTitle: String(localized: "Inspect Character"),
                            action: #selector(showSelectionInfo),
                            keyEquivalent: "",
                            at: 1)
        }
        
        return menu
    }
    
    
    
    // MARK: Action Messages
    
    /// Show the Go To sheet.
    @IBAction func gotoLocation(_ sender: Any?) {
        
        guard let textView = self.textView else { return assertionFailure() }
        
        let string = textView.string
        let lineNumber = string.lineNumber(at: textView.selectedRange.location)
        let lineCount = (string as NSString).substring(with: textView.selectedRange).numberOfLines
        let lineRange = FuzzyRange(location: lineNumber, length: lineCount)
        
        let view = GoToLineView(lineRange: lineRange) { (lineRange) in
            guard let range = textView.string.rangeForLine(in: lineRange) else { return false }
            
            textView.select(range: range)
            
            return true
        }
        let viewController = NSHostingController(rootView: view)
        viewController.rootView.parent = viewController
        
        self.presentAsSheet(viewController)
    }
    
    
    /// Show the Unicode input view.
    @IBAction func showUnicodeInputPanel(_ sender: Any?) {
        
        guard let textView = self.textView else { return assertionFailure() }
        
        let view = UnicodeInputView { [unowned textView] (character) in
            // flag to skip line ending sanitization
            textView.isApprovedTextChange = true
            defer { textView.isApprovedTextChange = false }
            
            textView.replace(with: String(character), range: textView.rangeForUserTextChange, selectedRange: nil)
        }
        let viewController = NSHostingController(rootView: view)
        viewController.view.frame.size = viewController.view.intrinsicContentSize
        
        let positioningRect = textView.boundingRect(for: textView.selectedRange)?.insetBy(dx: -1, dy: -1) ?? .zero
        let edge: NSRectEdge = (textView.layoutOrientation == .vertical) ? .maxX : .minY
        
        textView.scrollRangeToVisible(textView.selectedRange)
        self.present(viewController, asPopoverRelativeTo: positioningRect, of: textView, preferredEdge: edge, behavior: .transient)
    }
    
    
    /// Show the advanced counter.
    @IBAction func toggleAdvancedCounter(_ sender: Any?) {
        
        // hide counter
        if self.advancedCounterView != nil {
            return self.dismissAdvancedCharacterCounter()
        }
        
        // show counter
        let sheetView = CharacterCountOptionsSheetView { [weak self] in
            self?.showAdvancedCharacterCounter()
        }
        let optionViewController = NSHostingController(rootView: sheetView)
        optionViewController.rootView.parent = optionViewController
        
        self.presentAsSheet(optionViewController)
    }
    
    
    /// Show the character information by popover.
    @IBAction func showSelectionInfo(_ sender: Any?) {
        
        guard
            let textView = self.textView,
            textView.selectsSingleCharacter,
            let character = textView.selectedString.first
        else { return assertionFailure() }
        
        let characterInfo = CharacterInfo(character: character)
        let popoverController = DetachablePopoverViewController()
        popoverController.view = NSHostingView(rootView: CharacterInspectorView(info: characterInfo))
        popoverController.view.frame.size = popoverController.view.intrinsicContentSize
        
        let positioningRect = textView.boundingRect(for: textView.selectedRange)?.insetBy(dx: -4, dy: -4) ?? .zero
        
        textView.scrollRangeToVisible(textView.selectedRange)
        textView.showFindIndicator(for: textView.selectedRange)
        self.present(popoverController, asPopoverRelativeTo: positioningRect, of: textView, preferredEdge: .minY, behavior: .semitransient)
    }
    
    
    
    // MARK: Public Methods
    
    /// The visibility of the line number view.
    var showsLineNumber: Bool {
        
        get { self.lineNumberView?.isHidden == false }
        set { self.lineNumberView?.isHidden = !newValue }
    }
    
    
    
    // MARK: Private Methods
    
    /// Hide existing advanced character counter.
    ///
    /// - Parameter counterView: The advanced character counter to dismiss.
    private func dismissAdvancedCharacterCounter() {
        
        guard let counterView = self.advancedCounterView else { return assertionFailure() }
        
        NSAnimationContext.runAnimationGroup { _ in
            counterView.animator().alphaValue = 0
        } completionHandler: {
            counterView.removeFromSuperview()
        }
        
        self.invalidateRestorableState()
    }
    
    
    /// Setup and show advanced character counter.
    private func showAdvancedCharacterCounter() {
        
        guard let textView = self.textView else { return assertionFailure() }
        
        let counter = AdvancedCharacterCounter(textView: textView)
        let rootView = AdvancedCharacterCounterView(counter: counter) { [weak self] in
            self?.dismissAdvancedCharacterCounter()
        }
        let counterView = DraggableHostingView(rootView: rootView)
        counterView.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(counterView)
        self.advancedCounterView = counterView
        
        if textView.layoutOrientation == .horizontal, textView.baseWritingDirection != .rightToLeft {
            counterView.frame.origin.x = self.view.frame.width - counterView.frame.width
        }
        
        self.invalidateRestorableState()
    }
}



extension EditorTextViewController: NSUserInterfaceValidations {
    
    func validateUserInterfaceItem(_ item: any NSValidatedUserInterfaceItem) -> Bool {
        
        switch item.action {
            case #selector(toggleAdvancedCounter):
                (item as? NSMenuItem)?.title = (self.advancedCounterView == nil)
                    ? String(localized: "Advanced Character Count…")
                    : String(localized: "Stop Advanced Character Count")
                return true
                
            case #selector(showSelectionInfo):
                return self.textView?.selectsSingleCharacter == true
                
            case nil:
                return false
                
            default:
                return true
        }
    }
}



extension EditorTextViewController: NSFontChanging {
    
    // MARK: Font Changing Methods
    
    /// Restrict items in the font panel toolbar.
    func validModesForFontPanel(_ fontPanel: NSFontPanel) -> NSFontPanel.ModeMask {
        
        [.collection, .face, .size]
    }
}



// MARK: -

private extension MultiCursorEditing {
    
    var selectsSingleCharacter: Bool {
        
        !self.hasMultipleInsertions && self.selectedString.compareCount(with: 1) == .equal
    }
}
