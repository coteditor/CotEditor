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
//  © 2014-2025 1024jp
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
import ControlUI
import CharacterInfo
import Defaults
import FuzzyRange
import StringUtils
import TextClipping

final class EditorTextViewController: NSViewController, NSServicesMenuRequestor, NSTextViewDelegate {
    
    // MARK: Enums
    
    private enum SerializationKey {
        
        static let showsAdvancedCounter = "showsAdvancedCounter"
    }
    
    
    // MARK: Public Properties
    
    @ViewLoading private(set) var textView: EditorTextView
    
    
    // MARK: Private Properties
    
    private let document: Document
    
    private var stackView: NSStackView?  { self.view as? NSStackView }
    @ViewLoading private var lineNumberView: LineNumberView
    
    private weak var advancedCounterView: NSView?
    
    private var observers: Set<AnyCancellable> = []
    
    
    // MARK: Lifecycle
    
    init(document: Document) {
        
        self.document = document
        
        super.init(nibName: nil, bundle: nil)
        
        // set identifier for state restoration
        self.identifier = NSUserInterfaceItemIdentifier("EditorTextViewController")
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    deinit {
        MainActor.assumeIsolated {
            // detach layoutManager safely
            guard
                let textStorage = self.textView.textStorage,
                let layoutManager = self.textView.layoutManager
            else { return assertionFailure() }
            
            textStorage.removeLayoutManager(layoutManager)
        }
    }
    
    
    override func loadView() {
        
        let textView = EditorTextView(textStorage: self.document.textStorage,
                                      lineEndingScanner: self.document.lineEndingScanner)
        textView.delegate = self
        
        let scrollView = BidiScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.documentView = textView
        scrollView.identifier = NSUserInterfaceItemIdentifier("EditorScrollView")
        
        let lineNumberView = LineNumberView()
        lineNumberView.textView = textView
        
        let stackView = NSStackView(views: [lineNumberView, scrollView])
        stackView.spacing = 0
        stackView.distribution = .fill
        
        self.view = stackView
        self.lineNumberView = lineNumberView
        self.textView = textView
    }
    
    
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        self.observers = [
            // observe text orientation for line number view
            self.textView.publisher(for: \.layoutOrientation, options: .initial)
                .sink { [weak self] orientation in
                    self?.stackView?.orientation = switch orientation {
                        case .horizontal: .horizontal
                        case .vertical: .vertical
                        @unknown default: fatalError()
                    }
                    self?.lineNumberView.orientation = orientation
                },
            
            // let line number view position follow writing direction
            self.textView.publisher(for: \.baseWritingDirection, options: .initial)
                .removeDuplicates()
                .map { ($0 == .rightToLeft) ? NSUserInterfaceLayoutDirection.rightToLeft : .leftToRight }
                .sink { [weak self] direction in
                    self?.stackView?.userInterfaceLayoutDirection = direction
                    (self?.textView.enclosingScrollView as? BidiScrollView)?.scrollerDirection = direction
                    self?.lineNumberView.layoutDirection = direction
                },
            
            // toggle visibility of the separator of the line number view
            UserDefaults.standard.publisher(for: .showLineNumberSeparator, initial: true)
                .assign(to: \.drawsSeparator, on: self.lineNumberView),
        ]
    }
    
    
    override func viewDidDisappear() {
        
        super.viewDidDisappear()
        
        self.observers.removeAll()
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
    
    
    // MARK: View Controller
    
    override func validRequestor(forSendType sendType: NSPasteboard.PasteboardType?, returnType: NSPasteboard.PasteboardType?) -> Any? {
        
        // accept continuity camera
        //   - Take Photo: .jpeg, .tiff
        //   - Scan Documents: .pdf, .tiff
        //   - Sketch: .png
        if let returnType, NSImage.imageTypes.contains(returnType.rawValue), self.textView.isEditable {
            return (returnType != .png) ? self : nil
        }
        
        return super.validRequestor(forSendType: sendType, returnType: returnType)
    }
    
    
    // MARK: Services Menu Requestor
    
    nonisolated func readSelection(from pboard: NSPasteboard) -> Bool {
        
        // scan from continuity camera
        if pboard.canReadItem(withDataConformingToTypes: NSImage.imageTypes),
           let image = NSImage(pasteboard: pboard)
        {
            Task { @MainActor in
                self.popoverLiveText(image: image)
            }
            
            return true
        }
        
        return false
    }
    
    
    // MARK: Text View Delegate
    
    func undoManager(for view: NSTextView) -> UndoManager? {
        
        self.document.undoManager
    }
    
    
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
    
    
    @available(macOS 15, *)
    func textViewWritingToolsDidEnd(_ textView: NSTextView) {
        
        guard
            textView.writingToolsBehavior != .limited,
            let layoutManager = textView.layoutManager,
            let theme = self.textView.theme
        else { return }
        
        layoutManager.invalidateHighlight(theme: theme, in: textView.selectedRange)
    }
    
    
    func textView(_ view: NSTextView, menu: NSMenu, for event: NSEvent, at charIndex: Int) -> NSMenu? {
        
        // add "Inspect Character" menu item if single character is selected
        if self.textView.selectsSingleCharacter == true {
            menu.insertItem(withTitle: String(localized: "Inspect Character", table: "MainMenu"),
                            action: #selector(showSelectionInfo),
                            keyEquivalent: "",
                            at: 1)
        }
        
        return menu
    }
    
    
    // MARK: Action Messages
    
    /// Shows the Go To sheet.
    @IBAction func gotoLocation(_ sender: Any?) {
        
        let textView = self.textView
        let string = textView.string
        let lineNumber = string.lineNumber(at: textView.selectedRange.location)
        let lineCount = (string as NSString).substring(with: textView.selectedRange).numberOfLines
        let lineRange = FuzzyRange(location: lineNumber, length: lineCount)
        
        let view = GoToLineView(lineRange: lineRange) { lineRange in
            guard let range = textView.string.rangeForLine(in: lineRange) else { return false }
            
            textView.select(range: range)
            
            return true
        }
        let viewController = NSHostingController(rootView: view)
        viewController.rootView.parent = viewController
        
        self.presentAsSheet(viewController)
    }
    
    
    /// Shows the Unicode input view.
    @IBAction func showUnicodeInputPanel(_ sender: Any?) {
        
        let textView = self.textView
        let view = UnicodeInputView { [unowned textView] character in
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
    
    
    /// Shows the advanced counter.
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
    
    
    /// Shows the character information by popover.
    @IBAction func showSelectionInfo(_ sender: Any?) {
        
        guard
            self.textView.selectsSingleCharacter,
            let character = self.textView.selectedString.first
        else { return assertionFailure() }
        
        let characterInfo = CharacterInfo(character: character)
        let popoverController = DetachablePopoverViewController()
        popoverController.view = NSHostingView(rootView: CharacterInspectorView(info: characterInfo))
        popoverController.view.frame.size = popoverController.view.intrinsicContentSize
        
        let textView = self.textView
        let positioningRect = textView.boundingRect(for: textView.selectedRange)?.insetBy(dx: -4, dy: -4) ?? .zero
        
        textView.scrollRangeToVisible(textView.selectedRange)
        textView.showFindIndicator(for: textView.selectedRange)
        self.present(popoverController, asPopoverRelativeTo: positioningRect, of: textView, preferredEdge: .minY, behavior: .semitransient)
    }
    
    
    // MARK: Public Methods
    
    /// The visibility of the line number view.
    var showsLineNumber: Bool {
        
        get { self.lineNumberView.isHidden == false }
        set { self.lineNumberView.isHidden = !newValue }
    }
    
    
    // MARK: Private Methods
    
    /// Shows a popover indicating the given image and live text detection.
    ///
    /// - Parameter image: The image to scan text.
    private func popoverLiveText(image: NSImage) {
        
        let textView = self.textView
        let rootView = LiveTextInsertionView(image: image) { [weak textView] string in
            guard let textView else { return }
            textView.replace(with: string, range: textView.selectedRange, selectedRange: nil)
        }
        let viewController = NSHostingController(rootView: rootView)
        viewController.sizingOptions = .preferredContentSize
        viewController.rootView.parent = viewController
        
        let positioningRect = textView.boundingRect(for: textView.selectedRange)?.insetBy(dx: -1, dy: -1) ?? .zero
        
        textView.scrollRangeToVisible(textView.selectedRange)
        self.present(viewController, asPopoverRelativeTo: positioningRect, of: textView, preferredEdge: .maxY, behavior: .transient)
    }
    
    
    /// Hides the existing advanced character counter.
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
    
    
    /// Sets and shows advanced character counter.
    private func showAdvancedCharacterCounter() {
        
        let textView = self.textView
        let counter = AdvancedCharacterCounter()
        counter.observe(textView: textView)
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
            case #selector(showUnicodeInputPanel):
                return self.textView.isEditable
            case #selector(toggleAdvancedCounter):
                (item as? NSMenuItem)?.title = (self.advancedCounterView == nil)
                    ? String(localized: "Advanced Character Count…", table: "AdvancedCharacterCount", comment: "menu item")
                    : String(localized: "Stop Advanced Character Count", table: "AdvancedCharacterCount", comment: "menu item")
                return true
                
            case #selector(showSelectionInfo):
                return self.textView.selectsSingleCharacter == true
                
            case nil:
                return false
                
            default:
                return true
        }
    }
}


extension EditorTextViewController: EditorTextView.Delegate {
    
    /// Inserts string representation of dropped files applying the user's file drop snippets.
    ///
    /// - Parameter urls: The file URLs of dropped files.
    /// - Returns: Whether the file drop was performed.
    func editorTextView(_ textView: EditorTextView, readDroppedURLs urls: [URL]) -> Bool {
        
        guard !urls.isEmpty else { return false }
        
        let fileDropItems = UserDefaults.standard[.fileDropArray].map(FileDropItem.init(dictionary:))
        
        guard !fileDropItems.isEmpty else { return false }
        
        let replacementString = urls.reduce(into: "") { (string, url) in
            if url.pathExtension == TextClipping.pathExtension, let textClipping = try? TextClipping(contentsOf: url) {
                string += textClipping.string
                return
            }
            
            if let fileDropItem = fileDropItems.first(where: { $0.supports(extension: url.pathExtension, scope: textView.syntaxName) }) {
                string += fileDropItem.dropText(forFileURL: url, documentURL: self.document.fileURL)
                return
            }
            
            // just insert the absolute path if no specific setting for the file type was found
            // -> This is the default behavior of NSTextView by file dropping.
            if !string.isEmpty {
                string += textView.lineEnding.string
            }
            
            string += url.isFileURL ? url.path(percentEncoded: false) : url.absoluteString
        }
        
        guard !replacementString.isEmpty else { return true }
        
        // insert snippets to view
        guard textView.shouldChangeText(in: textView.rangeForUserTextChange, replacementString: replacementString) else { return false }
        
        textView.replaceCharacters(in: textView.rangeForUserTextChange, with: replacementString)
        textView.didChangeText()
        
        return true
    }
}


extension EditorTextViewController: NSFontChanging {
    
    // MARK: Font Changing Methods
    
    /// Restricts items in the font panel toolbar.
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
