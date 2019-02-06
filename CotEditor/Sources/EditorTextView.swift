//
//  EditorTextView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by nakamuxu on 2005-03-30.
//
//  ---------------------------------------------------------------------------
//
//  © 2004-2007 nakamuxu
//  © 2014-2019 1024jp
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

private extension NSAttributedString.Key {
    
    static let autoBalancedClosingBracket = NSAttributedString.Key("autoBalancedClosingBracket")
}


private let kTextContainerInset = NSSize(width: 0.0, height: 4.0)



// MARK: -

final class EditorTextView: NSTextView, Themable, CurrentLineHighlighting, MultiCursorEditing {
    
    // MARK: Notification Names
    
    static let didBecomeFirstResponderNotification = Notification.Name("TextViewDidBecomeFirstResponder")
    static let didLiveChangeSelectionNotification = Notification.Name("TextViewDidLiveChangeSelectionNotification")
    
    
    // MARK: Public Properties
    
    var isAutomaticTabExpansionEnabled = false
    
    var inlineCommentDelimiter: String?
    var blockCommentDelimiters: Pair<String>?
    var syntaxCompletionWords: [String] = []
    
    var needsUpdateLineHighlight = true
    var lineHighLightRect: NSRect?
    private(set) var lineHighLightColor: NSColor?
    
    var insertionLocations: [Int] = [] { didSet { self.updateInsertionPointTimer() } }
    var selectionOrigins: [Int] = []
    var insertionPointTimer: DispatchSourceTimer?
    var insertionPointOn = false
    private(set) var isPerformingRectangularSelection = false
    
    // for Scaling extension
    var initialMagnificationScale: CGFloat = 0
    var deferredMagnification: CGFloat = 0
    
    private(set) lazy var customSurroundStringViewController = CustomSurroundStringViewController.instantiate(storyboard: "CustomSurroundStringView")
    
    
    // MARK: Private Properties
    
    private let matchingBracketPairs: [BracePair] = BracePair.braces + [.doubleQuotes]
    
    private var cursorType: CursorType = .bar
    private var balancesBrackets = false
    private var isAutomaticIndentEnabled = false
    private var isSmartIndentEnabled = false
    
    private var mouseDownPoint: NSPoint = .zero
    
    private let instanceHighlightColor = NSColor.textHighlighterColor.withAlphaComponent(0.3)
    private lazy var instanceHighlightTask = Debouncer(delay: .seconds(0)) { [unowned self] in self.highlightInstance() }  // NSTextView cannot be weak
    
    private var needsRecompletion = false
    private var isShowingCompletion = false
    private var particalCompletionWord: String?
    private lazy var completionTask = Debouncer(delay: .seconds(0)) { [unowned self] in self.performCompletion() }  // NSTextView cannot be weak
    
    private var defaultsObservers: [UserDefaultsObservation] = []
    private var windowOpacityObserver: NSObjectProtocol?
    private var scrollObserver: NSObjectProtocol?
    private var resizeObserver: NSObjectProtocol?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    required init?(coder: NSCoder) {
        
        let defaults = UserDefaults.standard
        
        self.cursorType = defaults[.cursorType]
        self.balancesBrackets = defaults[.balancesBrackets]
        self.isAutomaticTabExpansionEnabled = defaults[.autoExpandTab]
        self.isAutomaticIndentEnabled = defaults[.autoIndent]
        self.isSmartIndentEnabled = defaults[.enableSmartIndent]
        
        // set paragraph style values
        self.lineHeight = defaults[.lineHeight]
        self.tabWidth = defaults[.tabWidth]
        
        super.init(coder: coder)
        
        // workaround for: the text selection highlight can remain between lines (2017-09 macOS 10.13).
        self.scaleUnitSquare(to: NSSize(width: 0.5, height: 0.5))
        self.scaleUnitSquare(to: self.convert(.unit, from: nil))  // reset scale
        
        // setup layoutManager and textContainer
        let layoutManager = LayoutManager()
        self.textContainer!.replaceLayoutManager(layoutManager)
        self.layoutManager?.allowsNonContiguousLayout = true
        
        // set layout values (wraps lines)
        self.minSize = self.frame.size
        self.maxSize = .infinite
        self.isHorizontallyResizable = false
        self.isVerticallyResizable = true
        self.autoresizingMask = .width
        self.textContainerInset = kTextContainerInset
        // workaround to avoid wrapping lines wrongly when scrollers are set to be always visible (macOS 10.14 2019-02)
        self.textContainer!.size.width = self.frame.size.width
        
        // set NSTextView behaviors
        self.baseWritingDirection = .leftToRight  // default is fixed in LTR
        self.allowsDocumentBackgroundColorChange = false
        self.allowsUndo = true
        self.isRichText = false
        self.importsGraphics = false
        self.usesFindPanel = true
        self.acceptsGlyphInfo = true
        self.linkTextAttributes = [.cursor: NSCursor.pointingHand,
                                   .underlineStyle: NSUnderlineStyle.single.rawValue]
        
        // setup behaviors
        self.smartInsertDeleteEnabled = defaults[.smartInsertAndDelete]
        self.isAutomaticQuoteSubstitutionEnabled = defaults[.enableSmartQuotes]
        self.isAutomaticDashSubstitutionEnabled = defaults[.enableSmartDashes]
        self.isAutomaticLinkDetectionEnabled = defaults[.autoLinkDetection]
        self.isContinuousSpellCheckingEnabled = defaults[.checkSpellingAsType]
        
        // set font
        let font: NSFont? = {
            let fontName = defaults[.fontName]!
            let fontSize = defaults[.fontSize]
            return NSFont(name: fontName, size: fontSize) ?? NSFont.userFont(ofSize: fontSize)
        }()
        super.font = font
        layoutManager.textFont = font
        layoutManager.usesAntialias = defaults[.shouldAntialias]
        
        self.invalidateDefaultParagraphStyle()
        
        // observe change in defaults
        self.defaultsObservers = self.observeDefaults()
    }
    
    
    deinit {
        self.insertionPointTimer?.cancel()
        self.defaultsObservers.forEach { $0.invalidate() }
        self.removeNotificationObservers()
    }
    
    
    
    // MARK: Text View Methods
    
    /// keys to be restored from the last session
    override class var restorableStateKeyPaths: [String] {
        
        return super.restorableStateKeyPaths + [
            #keyPath(font),
            #keyPath(scale),
            #keyPath(tabWidth),
        ]
    }
    
    
    /// append inset only to the bottom for overscroll
    override var textContainerOrigin: NSPoint {
        
        return NSPoint(x: super.textContainerOrigin.x, y: kTextContainerInset.height)
    }
    
    
    /// use sub-insertion points also for multi-text editing
    override var rangesForUserTextChange: [NSValue]? {
        
        return self.insertionRanges as [NSValue]
    }
    
    
    /// post notification about becoming the first responder
    override func becomeFirstResponder() -> Bool {
        
        NotificationCenter.default.post(name: EditorTextView.didBecomeFirstResponderNotification, object: self)
        
        return super.becomeFirstResponder()
    }
    
    
    /// textView was attached to a window
    override func viewDidMoveToWindow() {
        
        super.viewDidMoveToWindow()
        
        // textView will be removed from the window
        guard let window = self.window else {
            self.removeNotificationObservers()
            return
        }
        
        // apply theme to window
        self.applyTheme()
        
        // apply window opacity
        self.didChangeWindowOpacity(to: window.isOpaque)
        
        // observe window opacity flag
        self.windowOpacityObserver = NotificationCenter.default.addObserver(forName: DocumentWindow.didChangeOpacityNotification, object: window, queue: .main) { [unowned self] (notification) in
            guard let window = notification.object as? NSWindow else { return assertionFailure() }
            
            self.didChangeWindowOpacity(to: window.isOpaque)
        }
        
        if let scrollView = self.enclosingScrollView {
            // observe scorolling to fix drawing area on non-opaque view
            self.scrollObserver = NotificationCenter.default.addObserver(forName: NSView.boundsDidChangeNotification, object: scrollView.contentView, queue: .main) { [unowned self] _ in
                if !self.drawsBackground {
                    // -> Needs display visible rect since drawing area is modified in draw(_ dirtyFrame:)
                    self.setNeedsDisplay(self.visibleRect, avoidAdditionalLayout: true)
                }
            }
            
            // observe resizing for overscroll amount update
            self.resizeObserver = NotificationCenter.default.addObserver(forName: NSView.frameDidChangeNotification, object: scrollView.contentView, queue: .main) { [unowned self] _ in
                self.invalidateOverscrollRate()
            }
        } else {
            assertionFailure("failed starting observing the visible rect change")
        }
    }
    
    
    /// view did change frame
    override func setFrameSize(_ newSize: NSSize) {
        
        super.setFrameSize(newSize)
        
        self.needsUpdateLineHighlight = true
    }
    
    
    /// update cursor (invoked when cursor needs to update without moving mouse)
    override func cursorUpdate(with event: NSEvent) {
        
        super.cursorUpdate(with: event)
        
        self.invalidateCursor()
    }
    
    
    /// mouse is moved (the cursor updates also here)
    override func mouseMoved(with event: NSEvent) {
        
        super.mouseMoved(with: event)
        
        self.invalidateCursor()
    }
    
    
    /// the left mouse button is pressed
    override func mouseDown(with event: NSEvent) {
        
        self.mouseDownPoint = self.convert(event.locationInWindow, from: nil)
        self.isPerformingRectangularSelection = event.modifierFlags.contains(.option)
        self.updateInsertionPointTimer()
        
        let selectedRange = self.selectedRange.isEmpty ? self.selectedRange : nil
        
        super.mouseDown(with: event)
        
        // -> After `super.mouseDown(with:)` is actually the timing of `mouseUp(with:)`,
        //    which doesn't work in NSTextView subclasses. (2019-01 macOS 10.14)
        
        guard let window = self.window else { return }
        
        let pointInWindow = window.convertPoint(fromScreen: NSEvent.mouseLocation)
        let point = self.convert(pointInWindow, from: nil)
        let isDragged = (point != self.mouseDownPoint)
        
        // restore the first empty insertion if it seems to disappear
        if event.modifierFlags.contains(.command),
            !self.selectedRange.isEmpty,
            let selectedRange = selectedRange,
            selectedRange.isEmpty,
            !self.selectedRange.contains(selectedRange.location),
            self.selectedRange.upperBound != selectedRange.location
        {
            self.insertionLocations = (self.insertionLocations + [selectedRange.location]).sorted()
        }
        
        // add/remove insrtion point at clicked point
        if event.modifierFlags.contains(.command), event.clickCount == 1, !isDragged {
            self.modifyInsertionPoint(at: point)
        }
        
        self.isPerformingRectangularSelection = false
        self.updateInsertionPointTimer()
    }
    
    
    /// key is pressed
    override func keyDown(with event: NSEvent) {
        
        // perform snippet insertion if not in the middle of Japanese input
        if !self.hasMarkedText(),
            let snippet = SnippetKeyBindingManager.shared.snippet(keyEquivalent: event.charactersIgnoringModifiers,
                                                                  modifierMask: event.modifierFlags)
        {
            self.insert(snippet: snippet)
            self.centerSelectionInVisibleArea(self)
            return
        }
        
        super.keyDown(with: event)
    }
    
    
    /// Esc key is pressed
    override func cancelOperation(_ sender: Any?) {
        
        // exit multi-cursor mode
        if self.hasMultipleInsertions {
            self.selectedRange = self.insertionRanges.first!
            return
        }
        
        // -> NSTextView doesn't impelment cancelOperation (macOS 10.14)
    }
    
    
    /// text did change
    override func didChangeText() {
        
        super.didChangeText()
        
        self.invalidateNonContiguousLayout()
        
        self.needsUpdateLineHighlight = true
        
        // retry completion if needed
        //   -> Flag is set in `insertCompletion(_:forPartialWordRange:movement:isFinal:)`
        if self.needsRecompletion {
            self.needsRecompletion = false
            self.completionTask.schedule(delay: .milliseconds(50))
        }
    }
    
    
    /// on inputting text (NSTextInputClient Protocol)
    override func insertText(_ string: Any, replacementRange: NSRange) {
        
        // do not use this method for programmatic insertion.
        
        // sanitize input to plain string
        let plainString: String = {
            // cast input to String
            let input = String(anyString: string)
            
            // swap '¥' with '\' if needed
            if UserDefaults.standard[.swapYenAndBackSlash] {
                switch input {
                case "\\": return "¥"
                case "¥": return "\\"
                default: break
                }
            }
            
            return input
        }()
        
        // enter multi-cursor editing
        let insertionRanges = self.insertionRanges
        if insertionRanges.count > 1 {
            self.insertText(plainString, replacementRanges: insertionRanges)
            return
        }
        
        // balance brackets and quotes
        if self.balancesBrackets, replacementRange.isEmpty {
            // with opening symbol input
            if let pair = self.matchingBracketPairs.first(where: { String($0.begin) == plainString }) {
                // wrap selection with brackets if some text is selected
                if !self.rangeForUserTextChange.isEmpty {
                    self.surroundSelections(begin: String(pair.begin), end: String(pair.end))
                    return
                }
                
                // insert bracket pair if insertion point is not in a word
                if !CharacterSet.alphanumerics.contains(self.character(after: self.rangeForUserTextChange) ?? UnicodeScalar(0)),
                    !(pair.begin == pair.end && CharacterSet.alphanumerics.contains(self.character(before: self.rangeForUserTextChange) ?? UnicodeScalar(0)))  // for "
                {
                    super.insertText(String(pair.begin) + String(pair.end), replacementRange: replacementRange)
                    self.setSelectedRangesWithUndo([NSRange(location: self.selectedRange.location - 1, length: 0)])
                    self.textStorage?.addAttribute(.autoBalancedClosingBracket, value: true,
                                                   range: NSRange(location: self.selectedRange.location, length: 1))
                    return
                }
            }
            
            // just move cursor if closing bracket is already typed
            if BracePair.braces.contains(where: { String($0.end) == plainString }),  // ignore "
                plainString.unicodeScalars.first == self.character(after: self.rangeForUserTextChange),
                self.textStorage?.attribute(.autoBalancedClosingBracket, at: self.selectedRange.location, effectiveRange: nil) as? Bool ?? false
            {
                self.selectedRange.location += 1
                return
            }
        }
        
        // smart outdent with '}'
        if self.isAutomaticIndentEnabled, self.isSmartIndentEnabled, replacementRange.isEmpty,
            plainString == "}",
            let insertionIndex = Range(self.rangeForUserTextChange, in: self.string)?.upperBound
        {
            let lineRange = self.string.lineRange(at: insertionIndex)
            
            // decrease indent level if the line is consists of only whitespaces
            if self.string.range(of: "^[ \\t]+\\n?$", options: .regularExpression, range: lineRange) != nil,
                let precedingIndex = self.string.indexOfBracePair(endIndex: insertionIndex, pair: BracePair("{", "}")) {
                let desiredLevel = self.string.indentLevel(at: precedingIndex, tabWidth: self.tabWidth)
                let currentLevel = self.string.indentLevel(at: insertionIndex, tabWidth: self.tabWidth)
                let levelToReduce = currentLevel - desiredLevel
                
                if levelToReduce > 0 {
                    for _ in 0..<levelToReduce {
                        self.deleteBackward(nil)
                    }
                }
            }
        }
        
        super.insertText(plainString, replacementRange: replacementRange)
        
        // auto completion
        if UserDefaults.standard[.autoComplete] {
            let delay: TimeInterval = UserDefaults.standard[.autoCompletionDelay]
            self.completionTask.schedule(delay: .seconds(delay))
        }
    }
    
    
    /// insert tab & expand tab
    override func insertTab(_ sender: Any?) {
        
        // indent with tab key
        if UserDefaults.standard[.indentWithTabKey], !self.rangeForUserTextChange.isEmpty {
            self.indent()
            return
        }
        
        if self.isAutomaticTabExpansionEnabled {
            let softTab = self.string.softTab(at: self.rangeForUserTextChange.location, tabWidth: self.tabWidth)
            
            return super.insertText(softTab, replacementRange: self.rangeForUserTextChange)
        }
        
        super.insertTab(sender)
    }
    
    
    /// Shift + Tab is pressed
    override func insertBacktab(_ sender: Any?) {
        
        // outdent with tab key
        if UserDefaults.standard[.indentWithTabKey] {
            self.outdent()
            return
        }
        
        return super.insertBacktab(sender)
    }
    
    
    /// insert new line & perform auto-indent
    override func insertNewline(_ sender: Any?) {
        
        guard
            self.isEditable,
            self.isAutomaticIndentEnabled
            else { return super.insertNewline(sender) }
        
        let tab = self.isAutomaticTabExpansionEnabled ? String(repeating: " ", count: self.tabWidth) : "\t"
        
        let ranges = self.rangesForUserTextChange as? [NSRange] ?? [self.rangeForUserTextChange]
        self.setSelectedRangesWithUndo(ranges)
        
        let indents: [(range: NSRange, indent: String, insertion: Int)] = ranges
            .map { range in
                let indentRange = range.isEmpty ? self.string.rangeOfIndent(at: range.location) : range
                
                guard
                    !indentRange.isEmpty,
                    let autoIndentRange = indentRange.intersection(NSRange(0..<range.location))
                    else { return (range, "", 0) }
                
                var indent = (self.string as NSString).substring(with: autoIndentRange)
                var insertion = indent.count
                
                // smart indent
                if self.isSmartIndentEnabled {
                    let lastCharacter = self.character(before: range)
                    let nextCharacter = self.character(after: self.rangeForUserTextChange)
                    let indentBase = indent
                    
                    // increase indent level
                    if lastCharacter == ":" || lastCharacter == "{" {
                        indent += tab
                        insertion += tab.count
                    }
                    
                    // expand block
                    if lastCharacter == "{", nextCharacter == "}" {
                        indent += "\n" + indentBase
                    }
                }
                
                return (range, indent, insertion)
            }
        
        super.insertNewline(sender)
        
        // auto indent
        var locations: [Int] = []
        var offset = 0
        for (range, indent, insertion) in indents {
            let location = range.lowerBound + 1 + offset  // +1 for new line character
            
            super.insertText(indent, replacementRange: NSRange(location..<location))
            
            offset += -range.length + 1 + indent.count
            locations.append(location + insertion)
        }
        self.setSelectedRangesWithUndo(locations.map { NSRange($0..<$0) })
    }
    
    
    /// delete & adjust indent
    override func deleteBackward(_ sender: Any?) {
        
        guard self.isEditable else { return super.deleteBackward(sender) }
        
        if self.multipleDeleteBackward() { return }
        
        // delete tab
        if self.isAutomaticTabExpansionEnabled,
            let deletionRange = self.string.rangeForSoftTabDeletion(in: self.rangeForUserTextChange, tabWidth: self.tabWidth)
        {
            self.setSelectedRangesWithUndo(self.selectedRanges)
            self.selectedRange = deletionRange
        }
        
        // balance brackets
        if self.balancesBrackets,
            self.rangeForUserTextChange.isEmpty,
            let lastCharacter = self.character(before: self.rangeForUserTextChange),
            let nextCharacter = self.character(after: self.rangeForUserTextChange),
            self.matchingBracketPairs.contains(where: { $0.begin == Character(lastCharacter) && $0.end == Character(nextCharacter) })
        {
            self.setSelectedRangesWithUndo(self.selectedRanges)
            self.selectedRange = NSRange(location: self.rangeForUserTextChange.location - 1, length: 2)
        }
        
        super.deleteBackward(sender)
    }
    
    
    /// delete the selected text and place it onto the general pasteboard
    override func cut(_ sender: Any?) {
        
        let insertionRanges = self.insertionRanges
        self.setSelectedRangesWithUndo(insertionRanges)
        
        super.cut(sender)
        
        guard insertionRanges.count > 1 else { return }
        
        // keep insertion points after cut
        let ranges = insertionRanges.enumerated()
            .map { insertionRanges[..<$0.offset].reduce(into: $0.element.location) { $0 -= $1.length } }
            .map { NSRange($0..<$0) }
        
        guard let set = self.prepareForSelectionUpdate(ranges) else { return }
        
        self.selectedRanges = set.selectedRanges
        self.insertionLocations = set.insertionLocations
    }
    
    
    /// change multiple selection ranges
    override var selectedRanges: [NSValue] {
        
        willSet {
            // keep only empty ranges that super may discard for following multi-cursor editing
            // -> The ranges that `setSelectedRanges(_:affinity:stillSelecting:)` receives are sanitized already in NSTextView manner.
            self.insertionLocations = newValue
                .map { $0.rangeValue }
                .filter { $0.isEmpty }
                .map { $0.location }
        }
    }
    
    
    /// Change selection.
    ///
    /// - Note: Update `insertionLocations` manually when you use this method.
    override func setSelectedRanges(_ ranges: [NSValue], affinity: NSSelectionAffinity, stillSelecting stillSelectingFlag: Bool) {
        
        var ranges = ranges
        
        // interrupt rectangular selection
        if self.isPerformingRectangularSelection {
            if stillSelectingFlag {
                if let locations = self.insertionLocations(from: self.mouseDownPoint, candidates: ranges) {
                    ranges = [NSRange(location: locations[0], length: 0)] as [NSValue]
                    self.insertionLocations = Array(locations[1...])
                } else {
                    self.insertionLocations = []
                }
            } else {
                ranges = ranges.isEmpty ? self.selectedRanges : ranges
            }
        }
        
        super.setSelectedRanges(ranges, affinity: affinity, stillSelecting: stillSelectingFlag)
        
        // remove official selectedRanges from the sub insertion points
        let selectedRanges = self.selectedRanges.map { $0.rangeValue }
        self.insertionLocations.removeAll { (location) in selectedRanges.contains { $0.touches(location) } }
        
        if !stillSelectingFlag, !self.hasMultipleInsertions {
            self.selectionOrigins = [self.selectedRange.location]
        }
        
        self.updateInsertionPointTimer()
        
        self.needsUpdateLineHighlight = true
        
        if !stillSelectingFlag, !self.isShowingCompletion {
            // highlight matching brace
            if UserDefaults.standard[.highlightBraces] {
                let bracePairs = BracePair.braces + (UserDefaults.standard[.highlightLtGt] ? [.ltgt] : [])
                self.highligtMatchingBrace(candidates: bracePairs)
            }
            
            // invalidate current instances highlight
            if UserDefaults.standard[.highlightSelectionInstance] {
                let delay: TimeInterval = UserDefaults.standard[.selectionInstanceHighlightDelay]
                self.layoutManager?.removeTemporaryAttribute(.roundedBackgroundColor, forCharacterRange: self.string.nsRange)
                self.instanceHighlightTask.schedule(delay: .seconds(delay))
            }
        }
        
        NotificationCenter.default.post(name: EditorTextView.didLiveChangeSelectionNotification, object: self)
    }
    
    
    /// set a single selection
    override func setSelectedRange(_ charRange: NSRange, affinity: NSSelectionAffinity, stillSelecting stillSelectingFlag: Bool) {
        
        self.insertionLocations.removeAll()
        
        super.setSelectedRange(charRange, affinity: affinity, stillSelecting: stillSelectingFlag)
    }
    
    
    /// customize context menu
    override func menu(for event: NSEvent) -> NSMenu? {
        
        guard let menu = super.menu(for: event) else { return nil }
        
        // remove unwanted "Font" menu and its submenus
        if let fontMenuItem = menu.item(withTitle: "Font".localized(comment: "menu item title in the context menu")) {
            menu.removeItem(fontMenuItem)
        }
        
        // add "Inspect Character" menu item if single character is selected
        if (self.string as NSString).substring(with: self.selectedRange).count == 1 {
            menu.insertItem(withTitle: "Inspect Character".localized,
                            action: #selector(showSelectionInfo(_:)),
                            keyEquivalent: "",
                            at: 1)
        }
        
        // add "Copy as Rich Text" menu item
        let copyIndex = menu.indexOfItem(withTarget: nil, andAction: #selector(copy(_:)))
        if copyIndex >= 0 {  // -1 == not found
            menu.insertItem(withTitle: "Copy as Rich Text".localized,
                            action: #selector(copyWithStyle(_:)),
                            keyEquivalent: "",
                            at: copyIndex + 1)
        }
        
        // add "Select All" menu item
        let pasteIndex = menu.indexOfItem(withTarget: nil, andAction: #selector(paste(_:)))
        if pasteIndex >= 0 {  // -1 == not found
            menu.insertItem(withTitle: "Select All".localized,
                            action: #selector(selectAll(_:)),
                            keyEquivalent: "",
                            at: pasteIndex + 1)
        }
        
        return menu
    }
    
    
    /// text font
    override var font: NSFont? {
        
        get {
            // make sure to return by user defined font
            return (self.layoutManager as? LayoutManager)?.textFont ?? super.font
        }
        
        set {
            guard let font = newValue else { return }
            
            // let LayoutManager have the font too to avoid the issue where the line height can be inconsistance by a composite font
            // -> Because `textView.font` can return a Japanese font
            //    when the font is for one-bites and the first character of the content is Japanese one,
            //    LayoutManager should not use `textView.font`.
            (self.layoutManager as? LayoutManager)?.textFont = font
            
            super.font = font
            
            self.invalidateDefaultParagraphStyle()
        }
    }
    
    
    /// change font via font panel
    override func changeFont(_ sender: Any?) {
        
        guard
            let fontManager = sender as? NSFontManager,
            let currentFont = self.font,
            let textStorage = self.textStorage
            else { return assertionFailure() }
        
        let font = fontManager.convert(currentFont)
        
        // apply to all text views sharing textStorage
        for layoutManager in textStorage.layoutManagers {
            layoutManager.firstTextView?.font = font
        }
    }
    
    
    ///
    override func setNeedsDisplay(_ invalidRect: NSRect) {
        
        // expand rect as a workaroud for thick or multiple cursors (2018-11 macOS 10.14)
        super.setNeedsDisplay(self.visibleRect, avoidAdditionalLayout: true)
        
        super.setNeedsDisplay(invalidRect)
    }
    
    
    /// draw background
    override func drawBackground(in rect: NSRect) {
        
        super.drawBackground(in: rect)
        
        // draw current line highlight
        if UserDefaults.standard[.highlightCurrentLine] {
            self.drawCurrentLine(in: rect)
        }
        
        self.drawRoundedBackground(in: rect)
    }
    
    
    /// draw insersion point
    override func drawInsertionPoint(in rect: NSRect, color: NSColor, turnedOn flag: Bool) {
        
        var rect = rect
        switch self.cursorType {
        case .bar:
            break
        case .thickBar:
            rect.size.width *= 2
        case .block:
            let index = self.characterIndexForInsertion(at: rect.mid)
            rect.size.width = self.insertionBlockWidth(at: index)
        }
        
        super.drawInsertionPoint(in: rect, color: color, turnedOn: flag)
        
        // draw sub insertion rects
        self.insertionLocations
            .map { self.insertionPointRect(at: $0) }
            .forEach { super.drawInsertionPoint(in: $0, color: color, turnedOn: flag) }
    }
    
    
    /// calculate rect for insartion point at index
    override func insertionPointRect(at index: Int) -> NSRect {
        
        var rect = super.insertionPointRect(at: index)
        
        switch self.cursorType {
        case .bar:
            break
        case .thickBar:
            rect.size.width *= 2
        case .block:
            rect.size.width = self.insertionBlockWidth(at: index)
        }
        
        return rect
    }
    
    
    /// draw view
    override func draw(_ dirtyRect: NSRect) {
        
        // minimize drawing area on non-opaque background
        // -> Otherwise, all textView (from the top to the bottom) is everytime drawn
        //    and it affects to the drawing performance on a large document critically. (2017-03 macOS 10.12)
        let dirtyRect = self.drawsBackground ? dirtyRect : self.visibleRect
        
        super.draw(dirtyRect)
        
        // draw page guide
        if self.showsPageGuide,
            let textColor = self.textColor,
            let spaceWidth = (self.layoutManager as? LayoutManager)?.spaceWidth
        {
            let isHighContrast = NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
            let guideColor = textColor.withAlphaComponent(isHighContrast ? 0.5 : 0.2)
            
            let column = CGFloat(UserDefaults.standard[.pageGuideColumn])
            let inset = self.textContainerOrigin.x
            let linePadding = self.textContainer?.lineFragmentPadding ?? 0
            let x = spaceWidth * column + inset + linePadding + 2  // +2 px for an esthetic adjustment
            let isRTL = (self.baseWritingDirection == .rightToLeft)
            
            let guideRect = NSRect(x: isRTL ? self.bounds.width - x : x,
                                   y: dirtyRect.minY,
                                   width: 1.0,
                                   height: dirtyRect.height)
            
            NSGraphicsContext.saveGraphicsState()
            
            guideColor.setFill()
            self.centerScanRect(guideRect).fill()
            
            NSGraphicsContext.restoreGraphicsState()
        }
        
        // draw zero-width insertion points while rectangular selection
        // -> Because the insertion point blink timer stops while dragging. (macOS 10.14)
        if self.needsDrawInsertionPoints {
            self.insertionRanges
                .filter { $0.isEmpty }
                .map { self.insertionPointRect(at: $0.location) }
                .forEach { super.drawInsertionPoint(in: $0, color: self.insertionPointColor, turnedOn: self.insertionPointOn) }
        }
    }
    
    
    /// scroll to display specific range
    override func scrollRangeToVisible(_ range: NSRange) {
        
        // scroll line by line if an arrow key is pressed
        // -> Perform only when the scroll target is near by the visible area.
        //    Otherwise with the noncontiguous layout:
        //    - Scroll jumps when the cursor is initially in the end part of document.
        //    - Scroll doesn't reach to the bottom with command+down arrow.
        //    (2018-12 macOS 10.14)
        if NSEvent.modifierFlags.contains(.numericPad),
            let rect = self.boundingRect(for: range),
            let lineHeight = self.enclosingScrollView?.lineScroll,
            self.visibleRect.insetBy(dx: -lineHeight, dy: -lineHeight).intersects(rect)
        {
            super.scrollToVisible(rect)  // move minimum distance
            return
        }
        
        super.scrollRangeToVisible(range)
    }
    
    
    /// change text layout orientation
    override func setLayoutOrientation(_ orientation: NSLayoutManager.TextLayoutOrientation) {
        
        if self.layoutOrientation != orientation {
            self.minSize = self.minSize.rotated
        }
        
        // -> need to send KVO notification manually on Swift (2016-09-12 on macOS 10.12 SDK)
        self.willChangeValue(forKey: #keyPath(layoutOrientation))
        super.setLayoutOrientation(orientation)
        self.didChangeValue(forKey: #keyPath(layoutOrientation))
        
        self.invalidateNonContiguousLayout()
        
        // reset writing direction
        if orientation == .vertical {
            self.baseWritingDirection = .leftToRight
        }
    }
    
    
    /// read pasted/dropped item from NSPaseboard (involed in `performDragOperation(_:)`)
    override func readSelection(from pboard: NSPasteboard, type: NSPasteboard.PasteboardType) -> Bool {
        
        // apply link to pasted string
        defer {
            self.detectLinkIfNeeded()
        }
        
        // on file drop
        if pboard.name == .dragPboard,
            let urls = pboard.readObjects(forClasses: [NSURL.self]) as? [URL],
            self.insertDroppedFiles(urls)
        {
            return true
        }
        
        // paste a single string to all insertion points
        if pboard.name == .generalPboard,
            pboard.types?.contains(.multipleTextSelection) == false,
            let string = pboard.string(forType: .string),
            let ranges = self.rangesForUserTextChange as? [NSRange],
            ranges.count > 1,
            string.rangeOfCharacter(from: .newlines) == nil
        {
            return self.insertText(string, replacementRanges: ranges)
        }
        
        return super.readSelection(from: pboard, type: type)
    }
    
    
    /// convert line endings in pasteboard to document's line ending
    override func writeSelection(to pboard: NSPasteboard, types: [NSPasteboard.PasteboardType]) -> Bool {
        
        let success = super.writeSelection(to: pboard, types: types)
        
        guard let lineEnding = self.document?.lineEnding, lineEnding == .lf else { return success }
        
        for type in types {
            guard let string = pboard.string(forType: type) else { continue }
            
            pboard.setString(string.replacingLineEndings(with: lineEnding), forType: type)
        }
        
        return success
    }
    
    
    override var baseWritingDirection: NSWritingDirection {
        
        didSet {
            // update textContainer size (see comment in NSTextView.infiniteSize)
            if !self.wrapsLines {
                self.textContainer?.size = self.infiniteSize
            }
            
            // redraw page guide after changing writing direction
            if self.showsPageGuide {
                self.setNeedsDisplay(self.visibleRect, avoidAdditionalLayout: true)
            }
        }
    }
    
    
    
    // MARK: Protocol
    
    /// apply current state to related menu items and toolbar items
    override func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        
        guard let action = item.action else { return false }
        
        switch action {
        case #selector(copyWithStyle):
            return !self.selectedRange.isEmpty
            
        case #selector(showSelectionInfo):
            return (self.string as NSString).substring(with: self.selectedRange).count == 1
            
        case #selector(toggleComment):
            if let menuItem = item as? NSMenuItem {
                let canComment = self.canUncomment(partly: false)
                let title = canComment ? "Uncomment" : "Comment Out"
                menuItem.title = title.localized
            }
            return (self.inlineCommentDelimiter != nil) || (self.blockCommentDelimiters != nil)
            
        case #selector(inlineCommentOut):
            return (self.inlineCommentDelimiter != nil)
            
        case #selector(blockCommentOut):
            return (self.blockCommentDelimiters != nil)
            
        case #selector(uncomment(_:)):
            return self.canUncomment(partly: true)
            
        default: break
        }
        
        return super.validateUserInterfaceItem(item)
    }
    
    
    
    // MARK: Public Accessors
    
    /// coloring settings
    var theme: Theme? {
        
        didSet {
            self.applyTheme()
        }
    }
    
    
    /// tab width in number of spaces
    @objc var tabWidth: Int {
        
        didSet {
            if tabWidth <= 0 {
                tabWidth = oldValue
            }
            guard tabWidth != oldValue else { return }
            
            // apply to view
            self.invalidateDefaultParagraphStyle()
        }
    }
    
    
    /// line height multiple
    var lineHeight: CGFloat {
        
        didSet {
            if lineHeight <= 0 {
                lineHeight = oldValue
            }
            guard lineHeight != oldValue else { return }
            
            // apply to view
            self.invalidateDefaultParagraphStyle()
        }
    }
    
    
    /// whether draws page guide
    var showsPageGuide = false {
        
        didSet {
            self.setNeedsDisplay(self.bounds, avoidAdditionalLayout: true)
        }
    }
    
    
    /// whether text is antialiased
    var usesAntialias: Bool {
        
        get {
            return (self.layoutManager as? LayoutManager)?.usesAntialias ?? true
        }
        
        set {
            (self.layoutManager as? LayoutManager)?.usesAntialias = newValue
            self.setNeedsDisplay(self.visibleRect, avoidAdditionalLayout: true)
        }
    }
    
    
    /// whether invisible characters are shown
    var showsInvisibles: Bool {
        
        get {
            return (self.layoutManager as? LayoutManager)?.showsInvisibles ?? false
        }
        
        set {
            (self.layoutManager as? LayoutManager)?.showsInvisibles = newValue
        }
    }
    
    
    
    // MARK: Public Methods
    
    /// invalidate string attributes
    func invalidateStyle() {
        
        assert(Thread.isMainThread)
        
        guard let textStorage = self.textStorage else { return assertionFailure() }
        
        let range = textStorage.mutableString.range
        
        guard !range.isEmpty else { return }
        
        textStorage.addAttributes(self.typingAttributes, range: range)
        (self.layoutManager as? LayoutManager)?.invalidateIndent(in: range)
        self.detectLinkIfNeeded()
    }
    
    
    
    // MARK: Action Messages
    
    /// copy selection with syntax highlight and font style
    @IBAction func copyWithStyle(_ sender: Any?) {
        
        guard !self.selectedRange.isEmpty else {
            NSSound.beep()
            return
        }
        
        let string = self.string
        var selections = [NSAttributedString]()
        var propertyList = [Int]()
        let lineEnding = self.document?.lineEnding ?? .lf
        
        // substring all selected attributed strings
        let selectedRanges = self.selectedRanges as! [NSRange]
        for selectedRange in selectedRanges {
            let plainText = (string as NSString).substring(with: selectedRange)
            let styledText = NSMutableAttributedString(string: plainText, attributes: self.typingAttributes)
            
            // apply syntax highlight that is set as temporary attributes in layout manager to attributed string
            self.layoutManager?.enumerateTemporaryAttribute(.foregroundColor, in: selectedRange) { (value, range, _) in
                guard let color = value as? NSColor else { return }
                
                let localRange = NSRange(location: range.location - selectedRange.location, length: range.length)
                
                styledText.addAttribute(.foregroundColor, value: color, range: localRange)
            }
            
            // apply document's line ending
            if lineEnding != .lf {
                for (index, character) in zip(plainText.indices, plainText).reversed() where character == "\n" {  // process backwards
                    let characterRange = NSRange(index...index, in: plainText)
                    
                    styledText.replaceCharacters(in: characterRange, with: lineEnding.string)
                }
            }
            
            selections.append(styledText)
            propertyList.append(plainText.components(separatedBy: .newlines).count)
        }
        
        var pasteboardString = NSAttributedString()
        
        // join attributed strings
        let attrLineEnding = NSAttributedString(string: lineEnding.string)
        for selection in selections {
            // join with newline string
            if !pasteboardString.string.isEmpty {
                pasteboardString += attrLineEnding
            }
            pasteboardString += selection
        }
        
        // set to paste board
        let pboard = NSPasteboard.general
        pboard.clearContents()
        pboard.declareTypes([.rtf] + self.writablePasteboardTypes, owner: nil)
        if pboard.canReadItem(withDataConformingToTypes: [NSPasteboard.PasteboardType.multipleTextSelection.rawValue]) {
            pboard.setPropertyList(propertyList, forType: .multipleTextSelection)
        }
        pboard.writeObjects([pasteboardString])
    }
    
    
    /// input an Yen sign (¥)
    @IBAction func inputYenMark(_ sender: Any?) {
        
        super.insertText("¥", replacementRange: .notFound)
    }
    
    
    ///input a backslash (\\)
    @IBAction func inputBackSlash(_ sender: Any?) {
        
        super.insertText("\\", replacementRange: .notFound)
    }
    
    
    /// display character information by popover
    @IBAction func showSelectionInfo(_ sender: Any?) {
        
        var selectedString = (self.string as NSString).substring(with: self.selectedRange)
        
        // apply document's line ending
        if let documentLineEnding = self.document?.lineEnding,
            documentLineEnding != .lf, selectedString.detectedLineEnding == .lf
        {
            selectedString = selectedString.replacingLineEndings(with: documentLineEnding)
        }
        
        let popoverController = CharacterPopoverController.instantiate(storyboard: "CharacterPopover")
        do {
            try popoverController.setup(character: selectedString)
        } catch {
            return print(error)
        }
        
        guard let selectedRect = self.boundingRect(for: self.selectedRange) else { return }
        
        let positioningRect = self.convertToLayer(selectedRect).offsetBy(dx: 0, dy: -4)
        
        popoverController.showPopover(relativeTo: positioningRect, of: self)
        self.showFindIndicator(for: self.selectedRange)
    }
    
    
    
    // MARK: Private Methods
    
    /// document object representing the text view contents
    private var document: Document? {
        
        return self.window?.windowController?.document as? Document
    }
    
    
    /// remove notification observers
    private func removeNotificationObservers() {
        
        if let observer = self.windowOpacityObserver {
            NotificationCenter.default.removeObserver(observer)
            self.windowOpacityObserver = nil
        }
        if let observer = self.scrollObserver {
            NotificationCenter.default.removeObserver(observer)
            self.scrollObserver = nil
        }
        if let observer = self.resizeObserver {
            NotificationCenter.default.removeObserver(observer)
            self.resizeObserver = nil
        }
    }
    
    
    /// window's opacity did change
    private func didChangeWindowOpacity(to isOpaque: Bool) {
        
        // let text view have own background if possible
        self.drawsBackground = isOpaque
        
        // make the current line highlight a bit transparent
        self.lineHighLightColor = self.lineHighLightColor?.withAlphaComponent(isOpaque ? 1.0 : 0.7)
        
        // redraw visible area
        self.setNeedsDisplay(self.visibleRect, avoidAdditionalLayout: true)
    }
    
    
    /// update coloring settings
    private func applyTheme() {
        
        assert(Thread.isMainThread)
        
        guard let theme = self.theme else { return }
        
        (self.window as? DocumentWindow)?.contentBackgroundColor = theme.background.color
        
        self.backgroundColor = theme.background.color
        self.textColor = theme.text.color
        self.lineHighLightColor = theme.lineHighlight.color
        self.insertionPointColor = theme.insertionPoint.color.withAlphaComponent(self.cursorType == .block ? 0.5 : 1)
        self.selectedTextAttributes = [.backgroundColor: theme.selection.usesSystemSetting ? .selectedTextBackgroundColor : theme.selection.color]
        
        (self.layoutManager as? LayoutManager)?.invisiblesColor = theme.invisibles.color
        
        if !self.isOpaque {
            self.lineHighLightColor = self.lineHighLightColor?.withAlphaComponent(0.7)
        }
        
        // set scroller color considering background color
        if #available(macOS 10.14, *) {
            self.enclosingScrollView?.appearance = NSAppearance(named: theme.isDarkTheme ? .darkAqua : .aqua)
        } else {
            self.enclosingScrollView?.scrollerKnobStyle = theme.isDarkTheme ? .light : .default
        }
        
        self.setNeedsDisplay(self.visibleRect, avoidAdditionalLayout: true)
    }
    
    
    /// set defaultParagraphStyle based on font, tab width, and line height
    private func invalidateDefaultParagraphStyle() {
        
        assert(Thread.isMainThread)
        
        let paragraphStyle = NSParagraphStyle.default.mutable
        
        // set line height
        //   -> The actual line height will be calculated in LayoutManager and ATSTypesetter based on this line height multiple.
        //      Because the default Cocoa Text System calculate line height differently
        //      if the first character of the document is drawn with another font (typically by a composite font).
        //   -> Round line height for workaround to avoid expanding current line highlight when line height is 1.0. (2016-09 on macOS Sierra 10.12)
        //      e.g. Times
        paragraphStyle.lineHeightMultiple = self.lineHeight.rounded(to: 5)
        
        // calculate tab interval
        if let font = self.font {
            paragraphStyle.tabStops = []
            paragraphStyle.defaultTabInterval = CGFloat(self.tabWidth) * font.spaceWidth
        }
        
        paragraphStyle.baseWritingDirection = self.baseWritingDirection
        
        self.defaultParagraphStyle = paragraphStyle
        
        // add paragraph style also to the typing attributes
        //   -> textColor and font are added automatically.
        self.typingAttributes[.paragraphStyle] = paragraphStyle
        
        // tell line height also to scroll view so that scroll view can scroll line by line
        if let lineHeight = (self.layoutManager as? LayoutManager)?.lineHeight {
            self.enclosingScrollView?.lineScroll = lineHeight
        }
        
        // apply new style to current text
        self.invalidateStyle()
    }
    
    
    /// validate whether turns the noncontiguous layout on
    private func invalidateNonContiguousLayout() {
        
        guard let storage = self.textStorage else { return }
        
        // -> Obtaining textStorage's length is much faster than string.count. (2018-12 on macOS 10.14)
        let isLargeText = storage.length > UserDefaults.standard[.minimumLengthForNonContiguousLayout]
        
        // enable noncontiguous layout only on normal horizontal layout (2016-06 on OS X 10.11 El Capitan)
        //  -> Otherwise by vertical layout, the view scrolls occasionally to a strange position on typing.
        let isHorizontal = (self.layoutOrientation == .horizontal)
        
        self.layoutManager?.allowsNonContiguousLayout = isLargeText && isHorizontal
    }
    
    
    /// use legible white-based custom i-beam cursor for dark theme
    private func invalidateCursor() {
        
        guard
            NSAppKitVersion.current <= .macOS10_13,  // i-beam is enough findable with dark background since Mojave
            self.theme?.isDarkTheme == true,
            NSCursor.current == .iBeam
            else { return }
        
        NSCursor.lightIBeam.set()
    }
    
    
    /// calculate overscrolling amount
    private func invalidateOverscrollRate() {
        
        guard
            let scrollView = self.enclosingScrollView,
            let layoutManager = self.layoutManager as? LayoutManager
            else { return assertionFailure() }
        
        let rate = UserDefaults.standard[.overscrollRate].clamped(to: 0...1.0)
        let inset = rate * (scrollView.documentVisibleRect.height - layoutManager.lineHeight)
        
        // halve inset since the input value will be added to both top and bottom
        let height = max(floor(inset / 2), kTextContainerInset.height)
        
        // avoid high-loaded `sizeToFit()` if not required
        guard height != self.textContainerInset.height else { return }
        
        self.textContainerInset.height = height
        self.sizeToFit()
    }
    
    
    /// make URL-like text clickable
    private func detectLinkIfNeeded() {
        
        assert(Thread.isMainThread)
        
        guard
            self.isAutomaticLinkDetectionEnabled,
            let textStorage = self.textStorage
            else { return }
        
        // -> use own dataDetector instead of `checkTextInDocument(_:)` due to performance issue (2018-07)
        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let range = NSRange(..<textStorage.length)
        
        textStorage.removeAttribute(.link, range: range)
        
        detector.enumerateMatches(in: self.string, range: range) { (result, _, _) in
            guard let result = result, let url = result.url else { return }
            
            textStorage.addAttribute(.link, value: url, range: result.range)
        }
        
        // ensure layout to avoid unwanted scroll with cursor move after pasting something
        // at the latter part of the document. (2018-10 macOS 10.14)
        self.layoutManager?.ensureLayout(forCharacterRange: range)
    }
    
    
    /// insert string representation of dropped files applying user setting
    private func insertDroppedFiles(_ urls: [URL]) -> Bool {
        
        guard !urls.isEmpty else { return false }
        
        let composer = FileDropComposer(definitions: UserDefaults.standard[.fileDropArray])
        let documentURL = self.document?.fileURL
        let syntaxStyle: String? = {
            guard let style = self.document?.syntaxParser.style, !style.isNone else { return nil }
            return style.name
        }()
        
        let replacementString = urls.reduce(into: "") { (string, url) in
            if let dropText = composer.dropText(forFileURL: url, documentURL: documentURL, syntaxStyle: syntaxStyle) {
                string += dropText
                return
            }
            
            // just insert the absolute path if no specific setting for the file type was found
            // -> This is the default behavior of NSTextView by file dropping.
            if !string.isEmpty {
                string += "\n"
            }
            
            string += url.isFileURL ? url.path : url.absoluteString
        }
        
        // insert drop text to view
        guard self.shouldChangeText(in: self.rangeForUserTextChange, replacementString: replacementString) else { return false }
        
        self.replaceCharacters(in: self.rangeForUserTextChange, with: replacementString)
        self.didChangeText()
        
        return true
    }
    
    
    /// Return the width of the insertion point to be drawn at the `index`.
    ///
    /// - Parameter index: The character index of the insertion point.
    /// - Returns: The width of insertion point rect.
    private func insertionBlockWidth(at index: Int) -> CGFloat {
        
        guard
            let layoutManager = self.layoutManager as? LayoutManager,
            let textContainer = self.textContainer
            else { assertionFailure(); return 1 }
        
        let glyphIndex = layoutManager.glyphIndexForCharacter(at: index)
        
        guard
            layoutManager.isValidGlyphIndex(glyphIndex),
            layoutManager.propertyForGlyph(at: glyphIndex) != .controlCharacter
            else { return layoutManager.spaceWidth }
        
        return layoutManager.boundingRect(forGlyphRange: NSRange(glyphIndex...glyphIndex), in: textContainer).width
    }
    
    
    /// highlight all instances of the selection
    private func highlightInstance() {
        
        guard
            !self.string.isEmpty,  // important to avoid crash after closing editor
            !self.hasMarkedText(),
            self.insertionLocations.isEmpty,
            self.selectedRanges.count == 1,
            !self.selectedRange.isEmpty,
            (try! NSRegularExpression(pattern: "^\\b\\w.*\\w\\b$"))
                .firstMatch(in: self.string, options: [.withTransparentBounds], range: self.selectedRange) != nil,
            let range = Range(self.selectedRange, in: self.string)
            else { return }
        
        let substring = String(self.string[range])
        let pattern = "\\b" + NSRegularExpression.escapedPattern(for: substring) + "\\b"
        let regex = try! NSRegularExpression(pattern: pattern)
        let matches = regex.matches(in: self.string, range: self.string.nsRange)
            
        guard matches.count < UserDefaults.standard[.maximumSelectionInstanceHighlightCount] else { return }
        
        matches
            .map { $0.range }
            .forEach { self.layoutManager?.addTemporaryAttribute(.roundedBackgroundColor, value: self.instanceHighlightColor, forCharacterRange: $0) }
    }
    
    
    /// observe defaults to apply the change immediately
    private func observeDefaults() -> [UserDefaultsObservation] {
        
        let keys: [DefaultKeys] = [
            .cursorType,
            .autoExpandTab,
            .autoIndent,
            .enableSmartIndent,
            .balancesBrackets,
            .shouldAntialias,
            .smartInsertAndDelete,
            .enableSmartQuotes,
            .enableSmartDashes,
            .checkSpellingAsType,
            .autoLinkDetection,
            .pageGuideColumn,
            .overscrollRate,
            .tabWidth,
            .fontName,
            .fontSize,
            .lineHeight,
            .highlightCurrentLine,
            .highlightSelectionInstance,
            .enablesHangingIndent,
            .hangingIndentWidth,
            ]
        
        return UserDefaults.standard.observe(keys: keys, options: [.new]) { [unowned self] (key, change) in
            
            let new = change.new
            switch key {
            case .cursorType:
                self.cursorType = UserDefaults.standard[.cursorType]
                self.insertionPointColor = self.insertionPointColor.withAlphaComponent(self.cursorType == .block ? 0.5 : 1)
                
            case .autoExpandTab:
                self.isAutomaticTabExpansionEnabled = new as! Bool
                
            case .autoIndent:
                self.isAutomaticIndentEnabled = new as! Bool
                
            case .enableSmartIndent:
                self.isSmartIndentEnabled = new as! Bool
                
            case .balancesBrackets:
                self.balancesBrackets = new as! Bool
                
            case .shouldAntialias:
                self.usesAntialias = new as! Bool
                
            case .smartInsertAndDelete:
                self.smartInsertDeleteEnabled = new as! Bool
                
            case .enableSmartQuotes:
                self.isAutomaticQuoteSubstitutionEnabled = new as! Bool
                
            case .enableSmartDashes:
                self.isAutomaticDashSubstitutionEnabled = new as! Bool
                
            case .checkSpellingAsType:
                self.isContinuousSpellCheckingEnabled = new as! Bool
                
            case .autoLinkDetection:
                self.isAutomaticLinkDetectionEnabled = new as! Bool
                if self.isAutomaticLinkDetectionEnabled {
                    self.detectLinkIfNeeded()
                } else if let textStorage = self.textStorage {
                    textStorage.removeAttribute(.link, range: NSRange(0..<textStorage.length))
                }
                
            case .pageGuideColumn:
                self.setNeedsDisplay(self.visibleRect, avoidAdditionalLayout: true)
                
            case .overscrollRate:
                self.invalidateOverscrollRate()
                
            case .tabWidth:
                self.tabWidth = new as! Int
                
            case .fontName, .fontSize:
                self.resetFont(nil)
                
            case .lineHeight:
                self.lineHeight = new as! CGFloat
                self.centerSelectionInVisibleArea(self)  // reset visible area
                
            case .highlightCurrentLine:
                self.setNeedsDisplay(self.visibleRect, avoidAdditionalLayout: true)
                
            case .highlightSelectionInstance:
                if !(new as! Bool) {
                    self.layoutManager?.removeTemporaryAttribute(.roundedBackgroundColor, forCharacterRange: self.string.nsRange)
                }
                
            case .enablesHangingIndent:
                let wholeRange = self.string.nsRange
                if !(new as! Bool) {
                    if let paragraphStyle = self.defaultParagraphStyle {
                        self.textStorage?.addAttribute(.paragraphStyle, value: paragraphStyle, range: wholeRange)
                    } else {
                        self.textStorage?.removeAttribute(.paragraphStyle, range: wholeRange)
                    }
                } else {
                    (self.layoutManager as? LayoutManager)?.invalidateIndent(in: wholeRange)
                }
                
            case .hangingIndentWidth:
                (self.layoutManager as? LayoutManager)?.invalidateIndent(in: self.string.nsRange)
                
            default:
                preconditionFailure()
            }
        }
    }
    
}




// MARK: - Word Completion

extension EditorTextView {
    
    // MARK: Text View Methods
    
    /// return range for word completion
    override var rangeForUserCompletion: NSRange {
        
        let range = super.rangeForUserCompletion
        
        let firstLetters = self.syntaxCompletionWords.compactMap { $0.unicodeScalars.first }
        let firstLetterSet = CharacterSet(firstLetters)
        
        // expand range until hitting a character that isn't in the word completion candidates
        guard
            !firstLetterSet.isEmpty,
            !self.string.isEmpty,
            let characterRange = Range(range, in: self.string),
            let index = self.string[..<characterRange.upperBound].rangeOfCharacter(from: firstLetterSet.inverted, options: .backwards)?.upperBound
            else { return range }
        
        return NSRange(index..<characterRange.upperBound, in: self.string)
    }
    
    
    /// build completion list
    override func completions(forPartialWordRange charRange: NSRange, indexOfSelectedItem index: UnsafeMutablePointer<Int>) -> [String]? {
        
        // do nothing if completion is not suggested from the typed characters
        guard !charRange.isEmpty else { return nil }
        
        var candidateWords = OrderedSet<String>()
        let particalWord = (self.string as NSString).substring(with: charRange)
        
        // add words in document
        if UserDefaults.standard[.completesDocumentWords] {
            let documentWords: [String] = {
                // do nothing if the particle word is a symbol
                guard charRange.length > 1 || CharacterSet.alphanumerics.contains(particalWord.unicodeScalars.first!) else { return [] }
                
                let pattern = "(?:^|\\b|(?<=\\W))" + NSRegularExpression.escapedPattern(for: particalWord) + "\\w+?(?:$|\\b)"
                let regex = try! NSRegularExpression(pattern: pattern)
                
                return regex.matches(in: self.string, range: self.string.nsRange).map { (self.string as NSString).substring(with: $0.range) }
            }()
            candidateWords.append(contentsOf: documentWords)
        }
        
        // add words defined in syntax style
        if UserDefaults.standard[.completesSyntaxWords] {
            let syntaxWords = self.syntaxCompletionWords.filter { $0.range(of: particalWord, options: [.caseInsensitive, .anchored]) != nil }
            candidateWords.append(contentsOf: syntaxWords)
        }
        
        // add the standard words from default completion words
        if UserDefaults.standard[.completesStandartWords] {
            let words = super.completions(forPartialWordRange: charRange, indexOfSelectedItem: index) ?? []
            candidateWords.append(contentsOf: words)
        }
        
        // provide nothing if there is only a candidate which is same as input word
        if let word = candidateWords.first,
            candidateWords.count == 1,
            word.caseInsensitiveCompare(particalWord) == .orderedSame
        {
            return []
        }
        
        return candidateWords.array
    }
    
    
    /// display completion candidate and list
    override func insertCompletion(_ word: String, forPartialWordRange charRange: NSRange, movement: Int, isFinal flag: Bool) {
        
        self.completionTask.cancel()
        
        self.isShowingCompletion = !flag
        
        // store original string
        if self.particalCompletionWord == nil {
            self.particalCompletionWord = (self.string as NSString).substring(with: charRange)
        }
        
        // raise frag to proceed word completion again, if a normal key input is performed during displaying the completion list
        //   -> The flag will be used in `didChangeText()`
        var movement = movement
        if flag, let event = self.window?.currentEvent, event.type == .keyDown, !event.modifierFlags.contains(.command),
            event.charactersIgnoringModifiers == event.characters  // exclude key-bindings
        {
            // fix that underscore is treated as the right arrow key
            if event.characters == "_", movement == NSRightTextMovement {
                movement = NSIllegalTextMovement
            }
            if movement == NSIllegalTextMovement,
                let character = event.characters?.utf16.first,
                character < 0xF700, character != UInt16(NSDeleteCharacter)
            {  // standard key-input
                self.needsRecompletion = true
            }
        }
        
        var word = word
        var didComplete = false
        if flag {
            switch movement {
            case NSIllegalTextMovement, NSRightTextMovement:  // treat as cancelled
                // restore original input
                //   -> In case if the letter case is changed from the original.
                if let originalWord = self.particalCompletionWord {
                    word = originalWord
                }
            default:
                didComplete = true
            }
            
            // discard stored orignal word
            self.particalCompletionWord = nil
        }
        
        super.insertCompletion(word, forPartialWordRange: charRange, movement: movement, isFinal: flag)
        
        guard didComplete else { return }
        
        // select inside of "()" if completion word has ()
        var rangeToSelect = (word as NSString).range(of: "(?<=\\().*(?=\\))", options: .regularExpression)
        if rangeToSelect.location != NSNotFound {
            rangeToSelect.location += charRange.location
            self.selectedRange = rangeToSelect
        }
    }
    
    
    
    // MARK: Private Methods
    
    /// display word completion list
    private func performCompletion() {
        
        // abord if:
        guard !self.hasMarkedText(),  // input is not specified (for Japanese input)
            self.selectedRange.isEmpty,  // selected
            let lastCharacter = self.character(before: self.selectedRange), !CharacterSet.whitespacesAndNewlines.contains(lastCharacter)  // previous character is blank
            else { return }
        
        if let nextCharacter = self.character(after: self.selectedRange), CharacterSet.alphanumerics.contains(nextCharacter) { return }  // caret is (probably) at the middle of a word
        
        self.complete(self)
    }
    
}



// MARK: - Word Selection

extension EditorTextView {
    
    // MARK: Text View Methods
    
    /// adjust word selection range
    override func selectionRange(forProposedRange proposedCharRange: NSRange, granularity: NSSelectionGranularity) -> NSRange {
        
        var range = super.selectionRange(forProposedRange: proposedCharRange, granularity: granularity)
        
        guard granularity == .selectByWord else { return range }
        
        // treat additional specific characters as separator (see `wordRange(at:)` for details)
        if !range.isEmpty {
            range = self.wordRange(at: proposedCharRange.location)
            if proposedCharRange.length > 1 {
                range.formUnion(self.wordRange(at: proposedCharRange.upperBound - 1))
            }
        }
        
        guard
            proposedCharRange.isEmpty,  // not on expanding selection
            range.length == 1,  // clicked character can be a brace
            let characterIndex = Range(range, in: self.string)?.lowerBound  // just in case
            else { return range }
        
        let clickedCharacter = self.string[characterIndex]
        
        // select (syntax-highlighted) quoted text
        if ["\"", "'", "`"].contains(clickedCharacter),
            let highlightRange = self.layoutManager?.effectiveRange(of: .foregroundColor, at: range.location)
        {
            let highlightCharacterRange = Range(highlightRange, in: self.string)!
            let firstHighlightIndex = highlightCharacterRange.lowerBound
            let lastHighlightIndex = self.string.index(before: highlightCharacterRange.upperBound)
            
            if (firstHighlightIndex == characterIndex && self.string[firstHighlightIndex] == clickedCharacter) ||  // begin quote
                (lastHighlightIndex == characterIndex && self.string[lastHighlightIndex] == clickedCharacter)  // end quote
            {
                return highlightRange
            }
        }
        
        // select inside of brackets
        if let pairIndex = self.string.indexOfBracePair(at: characterIndex, candidates: BracePair.braces + [.ltgt]) {
            switch pairIndex {
            case .begin(let beginIndex):
                return NSRange(beginIndex...characterIndex, in: self.string)
            case .end(let endIndex):
                return NSRange(characterIndex...endIndex, in: self.string)
            case .odd:
                NSSound.beep()
                return NSRange(characterIndex...characterIndex, in: self.string)  // If a odd brace was double-clicked, only the clicked brace should be selected
            }
        }
        
        return range
    }
    
    
    
    // MARK: Public Methods
    
    /// word range that includes location
    func wordRange(at location: Int) -> NSRange {
        
        let proposedWordRange = super.selectionRange(forProposedRange: NSRange(location..<location), granularity: .selectByWord)
        
        guard proposedWordRange.contains(location) else { return proposedWordRange }
        
        // treat `.` and `:` as word delimiter
        return (self.string as NSString).rangeOfCharacter(until: CharacterSet(charactersIn: ".:"), at: location, range: proposedWordRange)
    }
    
}
