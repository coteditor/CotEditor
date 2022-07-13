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
//  © 2014-2022 1024jp
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

final class EditorTextViewController: NSViewController, NSTextViewDelegate {
    
    // MARK: Enums
    
    private enum SerializationKey {
        
        static let showsAdvancedCounter = "showsAdvancedCounter"
    }
    
    
    // MARK: Public Properties
    
    @IBOutlet private(set) weak var textView: EditorTextView?
    
    
    // MARK: Private Properties
    
    private weak var advancedCounterView: NSView?
    private weak var horizontalCounterConstraint: NSLayoutConstraint?
    
    private var orientationObserver: AnyCancellable?
    private var writingDirectionObserver: AnyCancellable?
    
    private var stackView: NSStackView?  { self.view as? NSStackView }
    
    @IBOutlet private weak var lineNumberView: LineNumberView?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // observe text orientation for line number view
        self.orientationObserver = self.textView!.publisher(for: \.layoutOrientation, options: .initial)
            .sink { [weak self] (orientation) in
                guard let self = self else { return assertionFailure() }
                
                self.alignAdvancedCharacterCounter()
                
                self.stackView?.orientation = {
                    switch orientation {
                        case .horizontal: return .horizontal
                        case .vertical: return .vertical
                        @unknown default: fatalError()
                    }
                }()
                
                self.lineNumberView?.orientation = orientation
            }
        
        // let line number view position follow writing direction
        self.writingDirectionObserver = self.textView!.publisher(for: \.baseWritingDirection)
            .removeDuplicates()
            .sink { [weak self] (writingDirection) in
                self?.alignAdvancedCharacterCounter()
                
                guard let stackView = self?.stackView,
                      let lineNumberView = self?.lineNumberView
                else { return assertionFailure() }
                
                // set scroller location
                (self?.textView?.enclosingScrollView as? BidiScrollView)?.scrollerDirection = (writingDirection == .rightToLeft) ? .rightToLeft : .leftToRight
                
                // set line number view location
                let index = writingDirection == .rightToLeft ? stackView.arrangedSubviews.count - 1 : 0
                
                guard stackView.arrangedSubviews[safe: index] != lineNumberView else { return }
                
                stackView.removeArrangedSubview(lineNumberView)
                stackView.insertArrangedSubview(lineNumberView, at: index)
                stackView.needsLayout = true
                stackView.layoutSubtreeIfNeeded()
            }
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
    
    /// text will be edited
    func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
        
        if textView.undoManager?.isUndoing == true { return true }  // = undo
        
        guard let textView = textView as? EditorTextView else { return true }
        
        if textView.isApprovedTextChange { return true }
        
        // standardize line endings to the document line ending
        if let replacementString = replacementString,  // = only attributes changed
           replacementString.lineEndingRanges().map(\.item).contains(where: { $0 != textView.lineEnding })
        {
            return !textView.replace(with: replacementString.replacingLineEndings(with: textView.lineEnding),
                                     range: affectedCharRange, selectedRange: nil)
        }
        
        return true
    }
    
    
    /// add script menu to context menu
    func textView(_ view: NSTextView, menu: NSMenu, for event: NSEvent, at charIndex: Int) -> NSMenu? {
        
        // append Script menu
        if let scriptMenu = ScriptManager.shared.contexualMenu {
            let item = NSMenuItem(title: "", action: nil, keyEquivalent: "")
            item.image = NSImage(systemSymbolName: "applescript.fill", accessibilityDescription: "Scripts".localized)
            item.toolTip = "Scripts".localized
            item.submenu = scriptMenu
            menu.addItem(item)
        }
        
        // add "Inspect Character" menu item if single character is selected
        if self.textView?.selectsSingleCharacter == true {
            menu.insertItem(withTitle: "Inspect Character".localized,
                            action: #selector(showSelectionInfo),
                            keyEquivalent: "",
                            at: 1)
        }
        
        return menu
    }
    
    
    
    // MARK: Action Messages
    
    /// show Go To sheet
    @IBAction func gotoLocation(_ sender: Any?) {
        
        guard let textView = self.textView else { return assertionFailure() }
        
        let viewController = GoToLineViewController.instantiate(storyboard: "GoToLineView")
        
        let string = textView.string
        let lineNumber = string.lineNumber(at: textView.selectedRange.location)
        let lineCount = (string as NSString).substring(with: textView.selectedRange).numberOfLines
        viewController.lineRange = FuzzyRange(location: lineNumber, length: lineCount)
        
        viewController.completionHandler = { (lineRange) in
            guard let range = textView.string.rangeForLine(in: lineRange) else { return false }
            
            textView.select(range: range)
            
            return true
        }
        
        self.presentAsSheet(viewController)
    }
    
    
    /// show Unicode input view
    @IBAction func showUnicodeInputPanel(_ sender: Any?) {
        
        guard let textView = self.textView else { return assertionFailure() }
        
        let inputViewController = UnicodeInputViewController.instantiate(storyboard: "UnicodeInputView")
        inputViewController.completionHandler = { [unowned textView] (character) in
            // flag to skip line ending sanitization
            textView.isApprovedTextChange = true
            defer { textView.isApprovedTextChange = false }
            
            textView.replace(with: String(character), range: textView.rangeForUserTextChange, selectedRange: nil)
        }
        
        let positioningRect = textView.boundingRect(for: textView.selectedRange)?.insetBy(dx: -1, dy: -1) ?? .zero
        let edge: NSRectEdge = (textView.layoutOrientation == .vertical) ? .maxX : .minY
        
        textView.scrollRangeToVisible(textView.selectedRange)
        self.present(inputViewController, asPopoverRelativeTo: positioningRect, of: textView, preferredEdge: edge, behavior: .transient)
    }
    
    
    @IBAction func toggleAdvancedCounter(_ sender: Any?) {
        
        // hide counter
        if let counterView = self.advancedCounterView {
            return self.dismissAdvancedCharacterCounter(counterView)
        }
        
        // show counter
        let sheetView = CharacterCountOptionsSheetView { [weak self] (performs) in
            guard performs else { return }
            self?.showAdvancedCharacterCounter()
        }
        let optionViewController = NSHostingController(rootView: sheetView)
        optionViewController.rootView.parent = optionViewController
        self.presentAsSheet(optionViewController)
    }
    
    
    /// display character information by popover
    @IBAction func showSelectionInfo(_ sender: Any?) {
        
        guard
            let textView = self.textView,
            textView.selectsSingleCharacter,
            let character = (textView.string as NSString).substring(with: textView.selectedRange).first
        else { return assertionFailure() }
        
        let popoverController = CharacterPopoverController.instantiate(for: character)
        let positioningRect = textView.boundingRect(for: textView.selectedRange)?.insetBy(dx: -4, dy: -4) ?? .zero
        
        textView.scrollRangeToVisible(textView.selectedRange)
        textView.showFindIndicator(for: textView.selectedRange)
        self.present(popoverController, asPopoverRelativeTo: positioningRect, of: textView, preferredEdge: .minY, behavior: .semitransient)
    }
    
    
    
    // MARK: Public Methods
    
    var showsLineNumber: Bool {
        
        get { self.lineNumberView?.isHidden == false }
        set { self.lineNumberView?.isHidden = !newValue }
    }
    
    
    
    // MARK: Private Methods
    
    /// Hide existing advanced character counter.
    /// - Parameter counterView: The advanced character counter to dismiss.
    private func dismissAdvancedCharacterCounter(_ counterView: NSView) {
        
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
        let counterView = NSHostingView(rootView: AdvancedCharacterCounterView(counter: counter))
        counterView.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(counterView)
        self.advancedCounterView = counterView
        
        counterView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -20).isActive = true
        self.alignAdvancedCharacterCounter()
        
        self.invalidateRestorableState()
    }
    
    
    /// Align advanced character count view by taking the writing direction into consideration.
    private func alignAdvancedCharacterCounter() {
        
        guard
            let textView = self.textView,
            let counterView = self.advancedCounterView
        else { return }
        
        let followsTrailing = textView.layoutOrientation == .vertical || textView.baseWritingDirection == .rightToLeft
        
        self.horizontalCounterConstraint?.isActive = false
        self.horizontalCounterConstraint = followsTrailing
            ? counterView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 20)
            : counterView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -20)
        self.horizontalCounterConstraint?.isActive = true
    }
    
}



extension EditorTextViewController: NSUserInterfaceValidations {
    
    func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        
        switch item.action {
            case #selector(toggleAdvancedCounter):
                (item as? NSMenuItem)?.title = (self.advancedCounterView == nil)
                    ? "Advanced Character Count…".localized
                    : "Stop Advanced Character Count".localized
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
    
    /// restrict items in the font panel toolbar
    func validModesForFontPanel(_ fontPanel: NSFontPanel) -> NSFontPanel.ModeMask {
        
        return [.collection, .face, .size]
    }
    
}



// MARK: -

private extension MultiCursorEditing {
    
    var selectsSingleCharacter: Bool {
        
        return !self.hasMultipleInsertions && (self.string as NSString).substring(with: self.selectedRange).compareCount(with: 1) == .equal
    }
    
}
