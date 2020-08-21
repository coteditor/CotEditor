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
//  © 2014-2020 1024jp
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

final class EditorTextViewController: NSViewController, NSTextViewDelegate {
    
    // MARK: Public Properties
    
    @IBOutlet private(set) weak var textView: EditorTextView?
    
    
    // MARK: Private Properties
    
    private var orientationObserver: AnyCancellable?
    
    @IBOutlet private weak var lineNumberView: LineNumberView?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        // observe text orientation for line number view
        self.orientationObserver = self.textView!.publisher(for: \.layoutOrientation, options: .initial)
            .sink { [weak self] (orientation) in
                guard let self = self else { return assertionFailure() }
                
                self.stackView?.orientation = {
                    switch orientation {
                        case .horizontal: return .horizontal
                        case .vertical: return .vertical
                        @unknown default: fatalError()
                    }
                }()
                
                self.lineNumberView?.orientation = orientation
            }
    }
    
    
    override func viewDidDisappear() {
        
        super.viewDidDisappear()
        
        self.orientationObserver = nil
    }
    
    
    
    // MARK: Text View Delegate
    
    /// text will be edited
    func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
        
        // standardize line endings to LF
        // -> Line endings replacement on file read is processed in `Document.read(from:ofType:).
        if let replacementString = replacementString,  // = only attributes changed
            !replacementString.isEmpty,  // = text deleted
            textView.undoManager?.isUndoing != true,  // = undo
            let lineEnding = replacementString.detectedLineEnding,  // = no line endings
            lineEnding != .lf
        {
            return !textView.replace(with: replacementString.replacingLineEndings(with: .lf),
                                     range: affectedCharRange,
                                     selectedRange: nil)
        }
        
        return true
    }
    
    
    /// add script menu to context menu
    func textView(_ view: NSTextView, menu: NSMenu, for event: NSEvent, at charIndex: Int) -> NSMenu? {
        
        // append Script menu
        if let scriptMenu = ScriptManager.shared.contexualMenu {
            let item = NSMenuItem(title: "", action: nil, keyEquivalent: "")
            item.image = NSImage(symbolNamed: "applescript.fill", accessibilityDescription: "Scripts".localized)
            item.toolTip = "Scripts".localized
            item.submenu = scriptMenu
            menu.addItem(item)
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
        inputViewController.completionHandler = { [weak textView] (character) in
            textView?.insertText(String(character), replacementRange: .notFound)
        }
        
        let positioningRect = textView.boundingRect(for: textView.selectedRange)?.insetBy(dx: -1, dy: -1) ?? .zero
        let edge: NSRectEdge = (textView.layoutOrientation == .vertical) ? .maxX : .minY
        
        textView.scrollRangeToVisible(textView.selectedRange)
        self.present(inputViewController, asPopoverRelativeTo: positioningRect, of: textView, preferredEdge: edge, behavior: .transient)
    }
    
    
    
    // MARK: Public Methods
    
    var showsLineNumber: Bool {
        
        get { self.lineNumberView?.isHidden == false }
        set { self.lineNumberView?.isHidden = !newValue }
    }
    
    
    
    // MARK: Private Methods
    
    /// cast view to NSStackView
    private var stackView: NSStackView? {
        
        return self.view as? NSStackView
    }
    
}



extension EditorTextViewController: NSFontChanging {
    
    // MARK: Font Changing Methods
    
    /// restrict items in the font panel toolbar
    func validModesForFontPanel(_ fontPanel: NSFontPanel) -> NSFontPanel.ModeMask {
        
        return [.collection, .face, .size]
    }
    
}
