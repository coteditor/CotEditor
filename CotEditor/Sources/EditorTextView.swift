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
//  © 2014-2024 1024jp
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

private extension NSAttributedString.Key {
    
    static let autoBalancedClosingBracket = NSAttributedString.Key("autoBalancedClosingBracket")
}


// MARK: -

class EditorTextView: NSTextView, Themable, CurrentLineHighlighting, MultiCursorEditing {
    
    // MARK: Notification Names
    
    static let didBecomeFirstResponderNotification = Notification.Name("TextViewDidBecomeFirstResponder")
    static let didLiveChangeSelectionNotification = Notification.Name("TextViewDidLiveChangeSelectionNotification")
    
    
    // MARK: Enums
    
    private enum SerializationKey {
        
        static let font = "font"
        static let scale = "scale"
        static let tabWidth = "tabWidth"
        static let insertionLocations = "insertionLocations"
    }
    
    
    // MARK: Public Properties
    
    var syntaxKind: Syntax.Kind = .general {
        
        didSet {
            guard oldValue != syntaxKind else { return }
            let type: FontType = switch UserDefaults.standard[.fontPreference] {
                case .automatic: syntaxKind.fontType
                case .standard: .standard
                case .monospaced: .monospaced
            }
            self.setFont(type: type)
        }
    }
    
    var theme: Theme?  { didSet { self.applyTheme() } }
    
    var isAutomaticTabExpansionEnabled = false
    var isApprovedTextChange = false
    
    var inlineCommentDelimiter: String?
    var blockCommentDelimiters: Pair<String>?
    var syntaxCompletionWords: [String] = []
    
    var needsUpdateLineHighlight = true {
        
        didSet {
            (self.lineHighlightRects + [self.visibleRect]).forEach { self.setNeedsDisplay($0, avoidAdditionalLayout: true) }
        }
    }
    var lineHighlightRects: [NSRect] = []
    private(set) var lineHighlightColor: NSColor?
    
    var insertionLocations: [Int] = []  {
        
        didSet {
            self.needsUpdateInsertionIndicators = true
            self.updateInsertionPointTimer()
        }
    }
    var selectionOrigins: [Int] = []
    var insertionPointTimer: (any DispatchSourceTimer)?
    var insertionPointOn = false
    private(set) var isPerformingRectangularSelection = false
    
    @available(macOS 14, *)
    var insertionIndicators: [NSTextInsertionIndicator] {
        
        get { self._insertionIndicators.compactMap { $0 as? NSTextInsertionIndicator } }
        set { self._insertionIndicators = newValue }
    }
    private var _insertionIndicators: [NSView] = []
    
    // for Scaling extension
    var initialMagnificationScale: CGFloat = 0
    var deferredMagnification: CGFloat = 0
    
    var customSurroundPair: Pair<String>?
    
    
    // MARK: Private Properties
    
    private let textFinder = TextFinder()
    
    private static let textContainerInset = NSSize(width: 4, height: 6)
    
    private let matchingBracketPairs: [BracePair] = BracePair.braces + [.doubleQuotes]
    private lazy var braceHighlightDebouncer = Debouncer { [weak self] in self?.highlightMatchingBrace() }
    private var isTypingPairedQuotes = false
    
    private var balancesBrackets = false
    private var isAutomaticIndentEnabled = false
    
    private var mouseDownPoint: NSPoint = .zero
    private var needsUpdateInsertionIndicators = false
    
    private lazy var overscrollResizingDebouncer = Debouncer { [weak self] in self?.invalidateOverscrollRate() }
    
    private let instanceHighlightColor: NSColor = .accent.withAlphaComponent(0.3)
    private var instanceHighlightTask: Task<Void, any Error>?
    
    private var needsRecompletion = false
    private var isShowingCompletion = false
    private var partialCompletionWord: String?
    private lazy var completionDebouncer = Debouncer { [weak self] in self?.performCompletion() }
    
    private lazy var trimTrailingWhitespaceTask = Debouncer { [weak self] in self?.trimTrailingWhitespace(ignoresEmptyLines: !UserDefaults.standard[.trimsWhitespaceOnlyLines], keepingEditingPoint: true) }
    
    private var defaultsObservers: Set<AnyCancellable> = []
    private var fontObservers: Set<AnyCancellable> = []
    private var windowOpacityObserver: AnyCancellable?
    private var applicationObserver: AnyCancellable?
    
    
    
    // MARK: Lifecycle
    
    convenience init() {
        
        self.init(frame: .zero, textContainer: nil)
    }
    
    
    required override init(frame: NSRect, textContainer: NSTextContainer?) {
        
        assert(textContainer == nil)
        
        let defaults = UserDefaults.standard
        
        self.balancesBrackets = defaults[.balancesBrackets]
        self.isAutomaticTabExpansionEnabled = defaults[.autoExpandTab]
        self.isAutomaticIndentEnabled = defaults[.autoIndent]
        
        // set paragraph style values
        self.lineHeight = defaults[.lineHeight]
        self.tabWidth = defaults[.tabWidth]
        
        // setup textContainer and layoutManager
        let textContainer = TextContainer()
        textContainer.widthTracksTextView = true
        textContainer.isHangingIndentEnabled = defaults[.enablesHangingIndent]
        textContainer.hangingIndentWidth = defaults[.hangingIndentWidth]
        
        let layoutManager = LayoutManager()
        layoutManager.tabWidth = self.tabWidth
        layoutManager.addTextContainer(textContainer)
        
        super.init(frame: frame, textContainer: textContainer)
        
        self.identifier = NSUserInterfaceItemIdentifier("EditorTextView")
        
        self.textFinder.client = self
        
        // set layout values (wraps lines)
        self.minSize = self.frame.size
        self.maxSize = .infinite
        self.isHorizontallyResizable = false
        self.isVerticallyResizable = true
        self.autoresizingMask = .width
        self.textContainerInset = Self.textContainerInset
        
        // set NSTextView behaviors
        self.baseWritingDirection = .leftToRight  // default is fixed in LTR
        self.allowsDocumentBackgroundColorChange = false
        self.allowsUndo = true
        self.isRichText = false
        self.usesFindPanel = true
        self.acceptsGlyphInfo = true
        self.linkTextAttributes = [.cursor: NSCursor.pointingHand,
                                   .underlineStyle: NSUnderlineStyle.single.rawValue]
        
        // setup behaviors
        self.smartInsertDeleteEnabled = defaults[.smartInsertAndDelete]
        self.isAutomaticQuoteSubstitutionEnabled = defaults[.enableSmartQuotes]
        self.isAutomaticDashSubstitutionEnabled = defaults[.enableSmartDashes]
        self.isContinuousSpellCheckingEnabled = defaults[.checkSpellingAsType]
        
        // set font
        let fontType: FontType = (defaults[.fontPreference] == .monospaced) ? .monospaced : .standard
        let font = defaults.font(for: fontType)
        super.font = font
        layoutManager.textFont = font
        layoutManager.usesAntialias = defaults[.antialias(for: fontType)]
        layoutManager.showsIndentGuides = defaults[.showIndentGuides]
        
        self.ligature = defaults[.ligature(for: fontType)] ? .standard : .none
        self.typingAttributes[.kern] = (fontType == .monospaced) ? 0 : nil
        self.invalidateDefaultParagraphStyle(initial: true)
        
        // observe font changes in defaults
        self.observeFontDefaults(for: fontType)
        
        // observe changes in defaults
        self.defaultsObservers = [
            defaults.publisher(for: .fontPreference)
                .map { [unowned self] _ in self.preferredFontType }
                .sink { [unowned self] in self.setFont(type: $0) },
            
            defaults.publisher(for: .balancesBrackets)
                .sink { [unowned self] in self.balancesBrackets = $0 },
            defaults.publisher(for: .autoExpandTab)
                .sink { [unowned self] in self.isAutomaticTabExpansionEnabled = $0 },
            defaults.publisher(for: .autoIndent)
                .sink { [unowned self] in self.isAutomaticIndentEnabled = $0 },
            
            defaults.publisher(for: .lineHeight)
                .sink { [unowned self] in self.lineHeight = $0 },
            defaults.publisher(for: .tabWidth)
                .sink { [unowned self] in self.tabWidth = $0 },
            
            defaults.publisher(for: .smartInsertAndDelete)
                .sink { [unowned self] in self.smartInsertDeleteEnabled = $0 },
            defaults.publisher(for: .enableSmartQuotes)
                .sink { [unowned self] in self.isAutomaticQuoteSubstitutionEnabled = $0 },
            defaults.publisher(for: .enableSmartDashes)
                .sink { [unowned self] in self.isAutomaticDashSubstitutionEnabled = $0 },
            defaults.publisher(for: .checkSpellingAsType)
                .sink { [unowned self] in self.isContinuousSpellCheckingEnabled = $0 },
            
            defaults.publisher(for: .showIndentGuides)
                .sink { [unowned self] in self.showsIndentGuides = $0 },
            defaults.publisher(for: .enablesHangingIndent)
                .sink { [unowned self] in
                    (self.textContainer as? TextContainer)?.isHangingIndentEnabled = $0
                    self.setNeedsDisplay(self.visibleRect, avoidAdditionalLayout: true)
                },
            defaults.publisher(for: .hangingIndentWidth)
                .sink { [unowned self] in
                    (self.textContainer as? TextContainer)?.hangingIndentWidth = $0
                    self.setNeedsDisplay(self.visibleRect, avoidAdditionalLayout: true)
                },
            
            defaults.publisher(for: .pageGuideColumn)
                .sink { [unowned self] _ in self.setNeedsDisplay(self.frame, avoidAdditionalLayout: true) },
            defaults.publisher(for: .overscrollRate)
                .sink { [unowned self] _ in self.invalidateOverscrollRate() },
            defaults.publisher(for: .highlightCurrentLine)
                .sink { [unowned self] _ in self.setNeedsDisplay(self.frame, avoidAdditionalLayout: true) },
            defaults.publisher(for: .highlightSelectionInstance)
                .filter { !$0 }
                .sink { [unowned self] _ in self.layoutManager?.removeTemporaryAttribute(.roundedBackgroundColor, forCharacterRange: self.string.nsRange) },
        ]
        
        // workaround the issue that indicators display even the application is inactive
        // (2023-08 macOS 14 beta 5, FB12968177)
        if #available(macOS 14, *) {
            self.applicationObserver = Publishers.Merge(
                NotificationCenter.default.publisher(for: NSApplication.didResignActiveNotification, object: NSApp),
                NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification, object: NSApp))
            .filter { [weak self] _ in self?.window?.firstResponder == self }
            .sink { [unowned self] _ in
                for indicator in self.insertionIndicators {
                    indicator.displayMode = NSApp.isActive ? .automatic : .hidden
                }
            }
        }
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    deinit {
        self.insertionPointTimer?.cancel()
        self.instanceHighlightTask?.cancel()
    }
    
    
    override func encodeRestorableState(with coder: NSCoder, backgroundQueue queue: OperationQueue) {
        
        super.encodeRestorableState(with: coder, backgroundQueue: queue)
        
        coder.encode(self.font, forKey: SerializationKey.font)
        coder.encode(Double(self.scale), forKey: SerializationKey.scale)
        coder.encode(self.tabWidth, forKey: SerializationKey.tabWidth)
        coder.encode(self.insertionLocations, forKey: SerializationKey.insertionLocations)
    }
    
    
    override func restoreState(with coder: NSCoder) {
        
        super.restoreState(with: coder)
        
        if let font = coder.decodeObject(of: NSFont.self, forKey: SerializationKey.font),
           font != self.font
        {
            self.font = font
        }
        
        let scale = coder.decodeDouble(forKey: SerializationKey.scale)
        if scale != 1, scale > 0 {
            self.scale = scale
        }
        
        let tabWidth = coder.decodeInteger(forKey: SerializationKey.tabWidth)
        if tabWidth > 0 {
            self.tabWidth = tabWidth
        }
        
        if let insertionLocations = (coder.decodeArrayOfObjects(ofClass: NSNumber.self, forKey: SerializationKey.insertionLocations) as? [Int])?
            .filter({ $0 <= self.string.length }),
           !insertionLocations.isEmpty
        {
            self.insertionLocations = insertionLocations
        }
    }
    
    
    
    // MARK: Text View Methods
    
    override var textContainerOrigin: NSPoint {
        
        // append inset only to the bottom for overscroll
        NSPoint(x: super.textContainerOrigin.x, y: Self.textContainerInset.height)
            .offsetBy(dy: (self.layoutOrientation == .vertical) ? self.bounds.minY.rounded() : 0)
    }
    
    
    override var rangesForUserTextChange: [NSValue]? {
        
        // use sub-insertion points also for multi-text editing
        self.insertionRanges as [NSValue]
    }
    
    
    override func becomeFirstResponder() -> Bool {
        
        guard super.becomeFirstResponder() else { return false }
        
        // post notification about becoming the first responder
        NotificationCenter.default.post(name: EditorTextView.didBecomeFirstResponderNotification, object: self)
        
        if #available(macOS 14, *) {
            for indicator in self.insertionIndicators {
                indicator.displayMode = .automatic
            }
        }
        
        return true
    }
    
    
    override func resignFirstResponder() -> Bool {
        
        guard super.resignFirstResponder() else { return false }
        
        if #available(macOS 14, *) {
            for indicator in self.insertionIndicators {
                indicator.displayMode = .hidden
            }
        }
        
        return true
    }
    
    
    override func viewDidMoveToWindow() {
        
        super.viewDidMoveToWindow()
        
        // apply theme to window when attached
        if let window = self.window as? DocumentWindow, let theme = self.theme {
            window.contentBackgroundColor = theme.background.color
        }
        
        // apply window opacity
        self.windowOpacityObserver = self.window?.publisher(for: \.isOpaque, options: .initial)
            .sink { [weak self] in
                self?.drawsBackground = $0
                self?.enclosingScrollView?.drawsBackground = $0
                self?.lineHighlightColor = self?.theme?.lineHighlightColor(forOpaqueBackground: $0)
            }
    }
    
    
    override func setFrameSize(_ newSize: NSSize) {
        
        let didChange = newSize != self.frame.size
        
        super.setFrameSize(newSize)
        
        guard didChange else { return }
        
        if !self.inLiveResize {
            self.overscrollResizingDebouncer.schedule()
        }
        
        self.needsUpdateInsertionIndicators = true
        self.needsUpdateLineHighlight = true
    }
    
    
    override func viewDidEndLiveResize() {
        
        super.viewDidEndLiveResize()
        
        self.overscrollResizingDebouncer.schedule()
    }
    
    
    override func updateTextTouchBarItems() {
        
        // silly workaround for the issue #971, where `updateTextTouchBarItems()` is invoked repeatedly when resizing frame
        // -> This workaround must be applicable to EditorTextView because this method
        //    seems updating only RichText-related Touch Bar items. (2019-06 macOS 10.14, FB7399413)
//        super.updateTextTouchBarItems()
    }
    
    
    override func mouseDown(with event: NSEvent) {
        
        self.mouseDownPoint = self.convert(event.locationInWindow, from: nil)
        self.isPerformingRectangularSelection = event.modifierFlags.contains(.option)
        self.needsUpdateInsertionIndicators = true  // to draw dummy indicator for proper one while selecting
        self.updateInsertionPointTimer()
        
        let selectedRange = self.selectedRange.isEmpty ? self.selectedRange : nil
        
        super.mouseDown(with: event)
        
        // -> After `super.mouseDown(with:)` is actually the timing of `mouseUp(with:)`,
        //    which doesn't work in NSTextView subclasses. (2019-01 macOS 10.14)
        
        guard let window = self.window else { return assertionFailure() }
        
        let pointInWindow = window.convertPoint(fromScreen: NSEvent.mouseLocation)
        let point = self.convert(pointInWindow, from: nil)
        let isDragged = (point != self.mouseDownPoint)
        
        // restore the first empty insertion if it seems to disappear
        if event.modifierFlags.contains(.command),
           !self.selectedRange.isEmpty,
           let selectedRange,
           selectedRange.isEmpty,
           !self.selectedRange.contains(selectedRange.location),
           self.selectedRange.upperBound != selectedRange.location
        {
            self.insertionLocations = (self.insertionLocations + [selectedRange.location]).sorted()
        }
        
        // add/remove insertion point at clicked point
        if event.modifierFlags.contains(.command), event.clickCount == 1, !isDragged {
            self.modifyInsertionPoint(at: point)
        }
        
        self.isPerformingRectangularSelection = false
        self.updateInsertionPointTimer()
    }
    
    
    override func keyDown(with event: NSEvent) {
        
        // perform snippet insertion if not in the middle of Japanese input
        if !self.hasMarkedText(),
           let shortcut = Shortcut(keyDownEvent: event),
           let document = self.document,
           let snippet = SnippetManager.shared.snippet(for: shortcut, scope: document.syntaxParser.syntax.name)
        {
            return self.insert(snippet: snippet)
        }
        
        super.keyDown(with: event)
    }
    
    
    /// The Esc key is pressed.
    override func cancelOperation(_ sender: Any?) {
        
        // exit multi-cursor mode
        if self.hasMultipleInsertions {
            self.selectedRange = self.insertionRanges.first!
            self.scrollRangeToVisible(self.selectedRange)
            return
        }
        
        // -> NSTextView doesn't implement `cancelOperation(_:)`. (macOS 10.14)
    }
    
    
    override func didChangeText() {
        
        super.didChangeText()
        
        self.invalidateNonContiguousLayout()
        
        self.needsUpdateLineHighlight = true
        
        self.instanceHighlightTask?.cancel()
        
        // trim trailing whitespace if needed
        if UserDefaults.standard[.autoTrimsTrailingWhitespace],
           self.document?.isLocked != true
        {
            self.trimTrailingWhitespaceTask.schedule(delay: .seconds(3))
        }
        
        // retry completion if needed
        // -> Flag is set in `insertCompletion(_:forPartialWordRange:movement:isFinal:)`.
        if self.needsRecompletion {
            self.completionDebouncer.schedule(delay: .milliseconds(50))
        }
    }
    
    
    override func insertText(_ string: Any, replacementRange: NSRange) {
        
        // do not use this method for programmatic insertion.
        
        let plainString = String(anyString: string)
        
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
                if !CharacterSet.alphanumerics.contains(self.character(after: self.rangeForUserTextChange) ?? Unicode.Scalar(0)),
                   !(pair.begin == pair.end && CharacterSet.alphanumerics.contains(self.character(before: self.rangeForUserTextChange) ?? Unicode.Scalar(0)))  // for "
                {
                    // raise frag to manipulate the cursor later in `handleTextCheckingResults(_:forRange:types:options:orthography:wordCount:)`
                    if self.isAutomaticQuoteSubstitutionEnabled, pair.begin == "\"" {
                        self.isTypingPairedQuotes = true
                    }
                    
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
        if self.isAutomaticIndentEnabled, replacementRange.isEmpty,
           plainString == "}"
        {
            let insertionIndex = String.Index(utf16Offset: self.rangeForUserTextChange.upperBound, in: self.string)
            let lineRange = self.string.lineRange(at: insertionIndex)
            
            // decrease indent level if the line is consists of only whitespaces
            if self.string[lineRange].starts(with: /[ \t]+\R?$/),
               let precedingIndex = self.string.indexOfBracePair(endIndex: insertionIndex, pair: BracePair("{", "}"))
            {
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
            if self.rangeForUserCompletion.length >= UserDefaults.standard[.minimumAutomaticCompletionLength] {
                let delay: TimeInterval = UserDefaults.standard[.autoCompletionDelay]
                self.completionDebouncer.schedule(delay: .seconds(delay))
            } else {
                self.completionDebouncer.cancel()
            }
        }
    }
    
    
    override func insertTab(_ sender: Any?) {
        
        // indent with tab key
        if UserDefaults.standard[.indentWithTabKey], !self.rangeForUserTextChange.isEmpty {
            self.indent()
            return
        }
        
        // insert soft tab
        if self.isAutomaticTabExpansionEnabled {
            let insertionRanges = self.rangesForUserTextChange?.map(\.rangeValue) ?? [self.rangeForUserTextChange]
            let softTabs = insertionRanges
                .map { self.string.softTab(at: $0.location, tabWidth: self.tabWidth) }
            
            self.replace(with: softTabs, ranges: insertionRanges, selectedRanges: nil)
            return
        }
        
        super.insertTab(sender)
    }
    
    
    /// The Shift + Tab keys are pressed
    override func insertBacktab(_ sender: Any?) {
        
        // outdent with tab key
        if UserDefaults.standard[.indentWithTabKey] {
            self.outdent()
            return
        }
        
        super.insertBacktab(sender)
    }
    
    
    override func insertNewline(_ sender: Any?) {
        
        guard
            self.isEditable,
            self.isAutomaticIndentEnabled
        else { return self.insertText(self.lineEnding.string, replacementRange: self.rangeForUserTextChange) }
        
        let tab = self.isAutomaticTabExpansionEnabled ? String(repeating: " ", count: self.tabWidth) : "\t"
        let ranges = self.rangesForUserTextChange?.map(\.rangeValue) ?? [self.rangeForUserTextChange]
        
        let indents: [(range: NSRange, indent: String, insertion: Int)] = ranges
            .map { range in
                guard
                    let indentRange = self.string.rangeOfIndent(at: range.location),
                    !indentRange.isEmpty,
                    let autoIndentRange = indentRange.intersection(NSRange(location: 0, length: range.location))
                else { return (range, "", 0) }
                
                var indent = (self.string as NSString).substring(with: autoIndentRange)
                var insertion = indent.count
                
                // smart indent
                let lastCharacter = self.character(before: range)
                let nextCharacter = self.character(after: range)
                let indentBase = indent
                
                // increase indent level
                if lastCharacter == ":" || lastCharacter == "{" {
                    indent += tab
                    insertion += tab.count
                }
                
                // expand block
                if lastCharacter == "{", nextCharacter == "}" {
                    indent += self.lineEnding.string + indentBase
                }
                
                return (range, indent, insertion)
            }
        
        // insert newline
        self.insertText(self.lineEnding.string, replacementRange: self.rangeForUserTextChange)
        
        // auto indent
        var locations: [Int] = []
        var offset = 0
        for (range, indent, insertion) in indents {
            let location = range.lowerBound + self.lineEnding.length + offset
            
            super.insertText(indent, replacementRange: NSRange(location: location, length: 0))
            
            offset += -range.length + self.lineEnding.length + indent.count
            locations.append(location + insertion)
        }
        self.setSelectedRangesWithUndo(locations.map { NSRange(location: $0, length: 0) })
    }
    
    
    override func deleteBackward(_ sender: Any?) {
        
        guard self.isEditable else { return super.deleteBackward(sender) }
        
        if self.multipleDelete() { return }
        
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
    
    
    override func cut(_ sender: Any?) {
        
        let insertionRanges = self.insertionRanges
        self.setSelectedRangesWithUndo(insertionRanges)
        
        super.cut(sender)
        
        guard insertionRanges.count > 1 else { return }
        
        // keep insertion points after cut
        let ranges = insertionRanges.enumerated()
            .map { insertionRanges[..<$0.offset].reduce(into: $0.element.location) { $0 -= $1.length } }
            .map { NSRange(location: $0, length: 0) }
        
        guard let set = self.prepareForSelectionUpdate(ranges) else { return }
        
        self.selectedRanges = set.selectedRanges
        self.insertionLocations = set.insertionLocations
    }
    
    
    override func handleTextCheckingResults(_ results: [NSTextCheckingResult], forRange range: NSRange, types checkingTypes: NSTextCheckingTypes, options: [NSSpellChecker.OptionKey: Any] = [:], orthography: NSOrthography, wordCount: Int) {
        
        super.handleTextCheckingResults(results, forRange: range, types: checkingTypes, options: options, orthography: orthography, wordCount: wordCount)
        
        // move the cursor back into the middle of quotes if the paired close quote was automatically inserted
        // because the cursor is automatically moved after the close quote by this method (#1384)
        if self.isTypingPairedQuotes,
           self.isAutomaticQuoteSubstitutionEnabled,
           self.selectedRange.isEmpty,
           results.map(\.resultType).contains(where: { $0.contains(.quote) })
        {
            self.selectedRange.location -= 1
        }
        self.isTypingPairedQuotes = false
    }
    
    
    override var selectedRanges: [NSValue] {
        
        willSet {
            // keep only empty ranges that super may discard for following multi-cursor editing
            // -> The ranges that `setSelectedRanges(_:affinity:stillSelecting:)` receives are sanitized already in NSTextView manner.
            self.insertionLocations = newValue
                .map(\.rangeValue)
                .filter(\.isEmpty)
                .map(\.location)
        }
    }
    
    
    /// Changes selections.
    ///
    /// - Note: Update `insertionLocations` manually when you use this method.
    override func setSelectedRanges(_ ranges: [NSValue], affinity: NSSelectionAffinity, stillSelecting stillSelectingFlag: Bool) {
        
        var ranges = ranges
        
        // interrupt rectangular selection
        if self.isPerformingRectangularSelection {
            if let locations = self.insertionLocations(from: self.mouseDownPoint, candidates: ranges) {
                ranges = [NSRange(location: locations[0], length: 0)] as [NSValue]
                self.insertionLocations = Array(locations[1...])
            } else {
                self.insertionLocations = []
            }
        }
        
        let currentRanges = self.rangesForUserTextChange ?? self.selectedRanges
        
        super.setSelectedRanges(ranges, affinity: affinity, stillSelecting: stillSelectingFlag)
        
        // remove official selectedRanges from the sub insertion points
        let selectedRanges = self.selectedRanges.map(\.rangeValue)
        self.insertionLocations.removeAll { location in selectedRanges.contains { $0.touches(location) } }
        
        if !stillSelectingFlag, !self.hasMultipleInsertions {
            self.selectionOrigins = [self.selectedRange.location]
        }
        
        self.updateInsertionPointTimer()
        
        self.needsUpdateLineHighlight = true
        
        if !stillSelectingFlag, !self.isShowingCompletion {
            // highlight matching brace
            if UserDefaults.standard[.highlightBraces] {
                self.braceHighlightDebouncer.schedule()
            }
            
            // invalidate current instances highlight
            if UserDefaults.standard[.highlightSelectionInstance] {
                self.instanceHighlightTask?.cancel()
                if let layoutManager = self.layoutManager, layoutManager.hasTemporaryAttribute(.roundedBackgroundColor) {
                    layoutManager.removeTemporaryAttribute(.roundedBackgroundColor, forCharacterRange: self.string.nsRange)
                }
                self.highlightInstances(after: .seconds(UserDefaults.standard[.selectionInstanceHighlightDelay]))
            }
        }
        
        // Sent notification on the next run loop
        // -> `self.selectedRange` may not be updated yet at this timing.
        DispatchQueue.main.async { [weak self] in
            guard self?.rangesForUserTextChange ?? self?.selectedRanges != currentRanges else { return }
            NotificationCenter.default.post(name: EditorTextView.didLiveChangeSelectionNotification, object: self)
        }
    }
    
    
    /// Sets a single selection.
    override func setSelectedRange(_ charRange: NSRange, affinity: NSSelectionAffinity, stillSelecting stillSelectingFlag: Bool) {
        
        self.insertionLocations.removeAll()
        
        super.setSelectedRange(charRange, affinity: affinity, stillSelecting: stillSelectingFlag)
    }
    
    
    override func menu(for event: NSEvent) -> NSMenu? {
        
        guard let menu = super.menu(for: event) else { return nil }
        
        // remove unwanted menu items
        menu.items.removeAll { item in
            item.submenu?.items.contains {
                $0.action == #selector(changeLayoutOrientation) ||  // Layout Orientation submenu
                $0.action == #selector(NSFontManager.orderFrontFontPanel)  // Font submenu
            } ?? false
        }
        
        // add "Copy as Rich Text" menu item
        let copyIndex = menu.indexOfItem(withTarget: nil, andAction: #selector(copy(_:)))
        if copyIndex >= 0 {  // -1 == not found
            menu.insertItem(withTitle: String(localized: "Copy as Rich Text"),
                            action: #selector(copyWithStyle),
                            keyEquivalent: "",
                            at: copyIndex + 1)
        }
        
        // add "Select All" menu item
        let pasteIndex = menu.indexOfItem(withTarget: nil, andAction: #selector(paste))
        if pasteIndex >= 0 {  // -1 == not found
            menu.insertItem(withTitle: String(localized: "Select All"),
                            action: #selector(selectAll),
                            keyEquivalent: "",
                            at: pasteIndex + 1)
        }
        
        // add "Straighten Quotes" menu item in Substitutions submenu
        for item in menu.items {
            guard let submenu = item.submenu else { continue }
            
            let index = submenu.indexOfItem(withTarget: nil, andAction: Selector(("replaceQuotesInSelection:")))
            
            guard index >= 0 else { continue }  // -1 == not found
            
            submenu.insertItem(withTitle: String(localized: "Straighten Quotes"),
                               action: #selector(straightenQuotesInSelection),
                               keyEquivalent: "",
                               at: index + 1)
        }
        
        return menu
    }
    
    
    override var font: NSFont? {
        
        get {
            // make sure to return the font defined by user
            (self.layoutManager as? LayoutManager)?.textFont ?? super.font
        }
        
        set {
            guard let font = newValue else { return }
            
            self.willChangeValue(for: \.font)
            defer {
                self.didChangeValue(for: \.font)
            }
            
            // let LayoutManager keep the set font to avoid an inconsistent line height
            // -> Because NSTextView's .font returns the font used for the first character of .string when it exists,
            //    not the font defined by user but a fallback font is returned through this property
            //    when the set font doesn't have a glyph for the first character.
            (self.layoutManager as? LayoutManager)?.textFont = font
            
            self.invalidateDefaultParagraphStyle()
            self.needsUpdateLineHighlight = true
            self.needsUpdateInsertionIndicators = true
            
            // set to the super after updating textStorage attributes in `.invalidateDefaultParagraphStyle()`
            // to avoid the strange issue that letters change into undefined
            // after specific characters.
            // Change the font in characters.md to reproduce this issue (macOS 12 2022-05-30)
            super.font = font
        }
    }
    
    
    override func changeFont(_ sender: Any?) {
        
        guard
            let fontManager = sender as? NSFontManager,
            let currentFont = self.font,
            let textStorage = self.textStorage
        else { return assertionFailure() }
        
        let font = fontManager.convert(currentFont)
        
        // apply to all text views sharing textStorage
        for textView in textStorage.layoutManagers.compactMap(\.firstTextView) {
            textView.font = font
        }
    }
    
    
    override func setNeedsDisplay(_ invalidRect: NSRect) {
        
        // expand rect as a workaround for multiple cursors (2018-11 macOS 10.14)
        if self.hasMultipleInsertions {
            super.setNeedsDisplay(self.visibleRect, avoidAdditionalLayout: true)
        }
        
        super.setNeedsDisplay(invalidRect)
    }
    
    
    override func viewWillDraw() {
        
        super.viewWillDraw()
        
        if #available(macOS 14, *), self.needsUpdateInsertionIndicators {
            self.updateInsertionIndicators()
            self.needsUpdateInsertionIndicators = false
        }
    }
    
    
    override func drawBackground(in rect: NSRect) {
        
        super.drawBackground(in: rect)
        
        // draw current line highlight
        if UserDefaults.standard[.highlightCurrentLine] {
            self.drawCurrentLine(in: rect)
        }
        
        self.drawRoundedBackground(in: rect)
    }
    
    
    override func draw(_ dirtyRect: NSRect) {
        
        super.draw(dirtyRect)
        
        // draw page guide
        if self.showsPageGuide,
           let spaceWidth = (self.layoutManager as? LayoutManager)?.spaceWidth
        {
            let column = CGFloat(UserDefaults.standard[.pageGuideColumn])
            let inset = self.textContainerInset.width
            let linePadding = self.textContainer?.lineFragmentPadding ?? 0
            let x = spaceWidth * column + inset + linePadding + 2  // +2 px for an esthetic adjustment
            let isRTL = (self.baseWritingDirection == .rightToLeft)
            
            let guideRect = NSRect(x: isRTL ? self.bounds.width - x : x,
                                   y: dirtyRect.minY,
                                   width: 1.0,
                                   height: dirtyRect.height)
            
            if guideRect.intersects(dirtyRect), let textColor = self.textColor {
                let isHighContrast = NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
                let guideColor = textColor.withAlphaComponent(isHighContrast ? 0.5 : 0.2)
                
                NSGraphicsContext.saveGraphicsState()
                guideColor.setFill()
                self.centerScanRect(guideRect).intersection(dirtyRect).fill()
                NSGraphicsContext.restoreGraphicsState()
            }
        }
        
        // draw zero-width insertion points while rectangular selection
        // -> Because the insertion point blink timer stops while dragging. (macOS 10.14)
        if self.needsDrawInsertionPoints, ProcessInfo.processInfo.operatingSystemVersion.majorVersion < 14 {
            self.insertionRanges
                .filter(\.isEmpty)
                .flatMap { self.insertionPointRects(at: $0.location) }
                .filter { $0.intersects(dirtyRect) }
                .forEach { super.drawInsertionPoint(in: $0, color: self.insertionPointColor, turnedOn: self.insertionPointOn) }
        }
    }
    
    
    override func scrollRangeToVisible(_ range: NSRange) {
        
        // scroll line by line if an arrow key is pressed
        // -> Perform only when the scroll target is nearby the visible area.
        //    Otherwise, the scroll doesn't reach the bottom with command+down arrow
        //    in the noncontiguous layout mode. (2018-12 macOS 10.14)
        guard NSEvent.modifierFlags.contains(.numericPad),
              range.upperBound < (self.layoutManager?.firstUnlaidCharacterIndex() ?? 0),
              let rect = self.boundingRect(for: range)
        else { return super.scrollRangeToVisible(range) }
        
        super.scrollToVisible(rect)  // move minimum distance
    }
    
    
    override func setLayoutOrientation(_ orientation: NSLayoutManager.TextLayoutOrientation) {
        
        let didChange = orientation != self.layoutOrientation
        
        // -> Need to send KVO notification manually on Swift. (2016-09-12 on macOS 10.12 SDK)
        self.willChangeValue(for: \.layoutOrientation)
        super.setLayoutOrientation(orientation)
        self.didChangeValue(for: \.layoutOrientation)
        
        guard didChange else { return }
        
        self.invalidateNonContiguousLayout()
        
        // reset writing direction
        if orientation == .vertical {
            self.baseWritingDirection = .leftToRight
        }
        
        // reset text wrapping width
        if self.wrapsLines {
            let keyPath = (orientation == .vertical) ? \NSSize.height : \NSSize.width
            self.frame.size[keyPath: keyPath] = self.visibleRect.width * self.scale
        }
    }
    
    
    /// Reads the pasted/dropped item from NSPasteboard (invoked in `performDragOperation(_:)`).
    override func readSelection(from pboard: NSPasteboard, type: NSPasteboard.PasteboardType) -> Bool {
        
        // on file drop
        if pboard.name == .drag,
           let urls = pboard.readObjects(forClasses: [NSURL.self]) as? [URL],
           self.insertDroppedFiles(urls)
        {
            return true
        }
        
        // paste a single string to all insertion points
        if pboard.name == .general,
           pboard.types?.contains(.multipleTextSelection) == false,
           let string = pboard.string(forType: .string),
           let ranges = self.rangesForUserTextChange?.map(\.rangeValue),
           ranges.count > 1,
           string.rangeOfCharacter(from: .newlines) == nil
        {
            return self.insertText(string, replacementRanges: ranges)
        }
        
        // keep multiple cursors after pasting multiple text
        if pboard.name == .general,
           let groupCounts = pboard.propertyList(forType: .multipleTextSelection) as? [Int],
           let string = pboard.string(forType: .string),
           let ranges = self.rangesForUserTextChange?.map(\.rangeValue),
           ranges.count > 1
        {
            let lines = string.components(separatedBy: .newlines)
            let multipleTexts: [String] = groupCounts
                .reduce(into: [Range<Int>]()) { (groupRanges, groupCount) in
                    if groupRanges.count >= ranges.count, let last = groupRanges.last {
                        groupRanges[groupRanges.endIndex - 1] = last.lowerBound..<(last.upperBound + groupCount)
                    } else {
                        groupRanges.append(groupRanges.count..<(groupRanges.count + groupCount))
                    }
                }
                .map { lines[$0].joined(separator: self.lineEnding.string) }
            let blanks = [String](repeating: "", count: ranges.count - multipleTexts.count)
            let strings = multipleTexts + blanks
            
            return self.replace(with: strings, ranges: ranges, selectedRanges: nil)
        }
        
        return super.readSelection(from: pboard, type: type)
    }
    
    
    override var baseWritingDirection: NSWritingDirection {
        
        willSet {
            self.willChangeValue(for: \.baseWritingDirection)
        }
        
        didSet {
            // update textContainer size (see comment in NSTextView.infiniteSize)
            if !self.wrapsLines {
                self.textContainer?.size = self.infiniteSize
            }
            
            self.didChangeValue(for: \.baseWritingDirection)
            
            self.needsUpdateInsertionIndicators = true
        }
    }
    
    
    override func updateFontPanel() {
        
        // update by own to avoid sending textColor to NSColorPanel
        // -> This method is even invoked when the receiver becomes the first responder or updated just textColor/typingAttributes.
        
        guard let font = self.font else { return }
        
        NSFontManager.shared.setSelectedFont(font, isMultiple: false)
    }
    
    
    
    // MARK: Protocol
    
    override func validateUserInterfaceItem(_ item: any NSValidatedUserInterfaceItem) -> Bool {
        
        switch item.action {
            case #selector(performTextFinderAction):
                guard let action = TextFinder.Action(rawValue: item.tag) else { return false }
                return self.textFinder.validateAction(action)
                
            case #selector(copyWithStyle):
                return !self.selectedRange.isEmpty
                
            case #selector(straightenQuotesInSelection):
                // -> Although `straightenQuotesInSelection(:_)` actually works also when selections are empty,
                //    disable it to make the state same as `replaceQuotesInSelection(_:)`.
                return !self.selectedRange.isEmpty
                
            case #selector(toggleComment):
                (item as? NSMenuItem)?.title = self.canUncomment(partly: false)
                    ? String(localized: "Uncomment")
                    : String(localized: "Comment Out")
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
    
    var lineEnding: LineEnding {
        
        self.document?.lineEnding ?? .lf
    }
    
    
    /// Tab width in number of spaces.
    var tabWidth: Int {
        
        didSet {
            tabWidth = max(tabWidth, 0)
            (self.layoutManager as? LayoutManager)?.tabWidth = tabWidth
            
            guard tabWidth != oldValue else { return }
            
            self.invalidateRestorableState()
            self.invalidateDefaultParagraphStyle()
            self.needsUpdateLineHighlight = true
            self.needsUpdateInsertionIndicators = true
        }
    }
    
    
    /// The line height multiple.
    var lineHeight: CGFloat {
        
        didSet {
            lineHeight = max(lineHeight, 0)
            
            guard lineHeight != oldValue else { return }
            
            self.invalidateDefaultParagraphStyle()
            self.needsUpdateLineHighlight = true
            self.needsUpdateInsertionIndicators = true
        }
    }
    
    
    /// Whether draws the page guide.
    var showsPageGuide = false {
        
        didSet {
            self.setNeedsDisplay(self.frame, avoidAdditionalLayout: true)
        }
    }
    
    
    /// Whether draws indent guides.
    var showsIndentGuides: Bool {
        
        get {
            (self.layoutManager as? LayoutManager)?.showsIndentGuides ?? true
        }
        
        set {
            (self.layoutManager as? LayoutManager)?.showsIndentGuides = newValue
            self.setNeedsDisplay(self.frame, avoidAdditionalLayout: true)
        }
    }
    
    
    /// Whether text is antialiased.
    var usesAntialias: Bool {
        
        get {
            (self.layoutManager as? LayoutManager)?.usesAntialias ?? true
        }
        
        set {
            guard newValue != usesAntialias else { return }
            (self.layoutManager as? LayoutManager)?.usesAntialias = newValue
            self.setNeedsDisplay(self.visibleRect, avoidAdditionalLayout: true)
        }
    }
    
    
    /// Whether invisible characters are shown.
    var showsInvisibles: Bool {
        
        get {
            (self.layoutManager as? LayoutManager)?.showsInvisibles ?? false
        }
        
        set {
            (self.layoutManager as? LayoutManager)?.showsInvisibles = newValue
            self.needsUpdateInsertionIndicators = true
        }
    }
    
    
    /// The font type the user prefers.
    var preferredFontType: FontType {
        
        switch UserDefaults.standard[.fontPreference] {
            case .automatic: self.syntaxKind.fontType
            case .standard: .standard
            case .monospaced: .monospaced
        }
    }
    
    
    /// Sets the font (font, antialias, and ligature) to the given font type.
    ///
    /// - Parameter type: The font type to change.
    func setFont(type: FontType) {
        
        let defaults = UserDefaults.standard
        self.font = defaults.font(for: type)
        self.ligature = defaults[.ligature(for: type)] ? .standard : .none
        self.usesAntialias = defaults[.antialias(for: type)]
        self.typingAttributes[.kern] = (type == .monospaced) ? 0 : nil
        
        self.observeFontDefaults(for: type)
    }
    
    
    
    // MARK: Action Messages
    
    /// Copies the selections with syntax highlight and font style.
    @IBAction func copyWithStyle(_ sender: Any?) {
        
        guard !self.selectedRange.isEmpty else { return NSSound.beep() }
        
        // substring all selected attributed strings
        let selections: [NSAttributedString] = self.selectedRanges
            .map(\.rangeValue)
            .map { selectedRange in
                let plainText = (self.string as NSString).substring(with: selectedRange)
                let styledText = NSMutableAttributedString(string: plainText, attributes: self.typingAttributes)
                
                // apply syntax highlight that is set as temporary attributes in layout manager to attributed string
                self.layoutManager?.enumerateTemporaryAttribute(.foregroundColor, type: NSColor.self, in: selectedRange) { (color, range, _) in
                    let localRange = range.shifted(by: -selectedRange.location)
                    
                    styledText.addAttribute(.foregroundColor, value: color, range: localRange)
                }
                
                return styledText
            }
        
        // prepare objects for rectangular selection
        let pasteboardString = selections.joined(separator: self.lineEnding.string)
        let propertyList = selections.map { $0.string.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline).count }
        
        // set to paste board
        let pboard = NSPasteboard.general
        pboard.clearContents()
        pboard.declareTypes([.rtf] + self.writablePasteboardTypes, owner: nil)
        if pboard.canReadItem(withDataConformingToTypes: [NSPasteboard.PasteboardType.multipleTextSelection.rawValue]) {
            pboard.setPropertyList(propertyList, forType: .multipleTextSelection)
        }
        pboard.writeObjects([pasteboardString])
    }
    
    
    /// Pastes clipboard text without any modification.
    @IBAction func pasteAsIs(_ sender: Any?) {
        
        self.isApprovedTextChange = true
        
        super.pasteAsPlainText(sender)
        
        self.isApprovedTextChange = false
    }
    
    
    
    // MARK: Private Methods
    
    /// The document object representing the text view contents.
    private var document: Document? {
        
        self.window?.windowController?.document as? Document
    }
    
    
    /// Updates coloring settings with the current theme.
    private func applyTheme() {
        
        assert(Thread.isMainThread)
        assert(self.layoutManager != nil)
        assert(self.enclosingScrollView != nil)
        
        guard let theme = self.theme else { return assertionFailure() }
        
        self.textColor = theme.text.color
        self.backgroundColor = theme.background.color
        self.lineHighlightColor = theme.lineHighlightColor(forOpaqueBackground: self.isOpaque)
        self.insertionPointColor = theme.effectiveInsertionPointColor
        if #available(macOS 14, *) {
            for indicator in self.insertionIndicators {
                indicator.color = self.insertionPointColor
            }
        }
        self.selectedTextAttributes[.backgroundColor] = theme.effectiveSelectionColor
        (self.layoutManager as? LayoutManager)?.invisiblesColor = theme.invisibles.color
        
        (self.window as? DocumentWindow)?.contentBackgroundColor = theme.background.color
        self.enclosingScrollView?.backgroundColor = theme.background.color
        self.enclosingScrollView?.scrollerKnobStyle = theme.isDarkTheme ? .light : .default
        
        self.setNeedsDisplay(self.visibleRect, avoidAdditionalLayout: true)
    }
    
    
    /// Starts observing the update of the user font settings of the given type.
    ///
    /// - Parameter type: The type of the font to observe.
    private func observeFontDefaults(for type: FontType) {
        
        let defaults = UserDefaults.standard
        
        self.fontObservers = [
            defaults.publisher(for: .fontKey(for: type))
                .sink { [unowned self] _ in self.font = UserDefaults.standard.font(for: type) },
            defaults.publisher(for: .antialias(for: type))
                .sink { [unowned self] in self.usesAntialias = $0 },
            defaults.publisher(for: .ligature(for: type))
                .sink { [unowned self] in self.ligature = $0 ? .standard : .none },
        ]
    }
    
    
    /// Updates `defaultParagraphStyle` based on the font, tab width, and line height.
    ///
    /// - Parameter initial: If true, apply the paragraphStyle even if the values are the same as the current `.defaultParagraphStyle.
    private func invalidateDefaultParagraphStyle(initial: Bool = false) {
        
        assert(Thread.isMainThread)
        
        guard let paragraphStyle = self.defaultParagraphStyle?.mutable else { return assertionFailure() }
        
        // set line height
        // -> The actual line height will be calculated in LayoutManager based on this line height multiple.
        //    Because the default implementation calculates the line height differently
        //     if the first character is drawn with another font (typically by a composite font).
        paragraphStyle.lineHeightMultiple = self.lineHeight
        
        // calculate tab interval
        if let font = self.font {
            paragraphStyle.tabStops = []
            paragraphStyle.defaultTabInterval = CGFloat(self.tabWidth) * font.width(of: " ")
        }
        
        guard initial ||
                (paragraphStyle.lineHeightMultiple != self.defaultParagraphStyle?.lineHeightMultiple ||
                 paragraphStyle.defaultTabInterval != self.defaultParagraphStyle?.defaultTabInterval)
        else { return }
        
        self.defaultParagraphStyle = paragraphStyle
        self.typingAttributes[.paragraphStyle] = paragraphStyle
        self.textStorage?.addAttribute(.paragraphStyle, value: paragraphStyle, range: self.string.nsRange)
        
        // tell line height also to scroll view so that scroll view can scroll line by line
        if let lineHeight = (self.layoutManager as? LayoutManager)?.lineHeight {
            self.enclosingScrollView?.lineScroll = lineHeight
        }
        
        self.needsUpdateInsertionIndicators = true
    }
    
    
    /// Calculates overscrolling amount and apply it.
    private func invalidateOverscrollRate() {
        
        guard let layoutManager = self.layoutManager as? LayoutManager else { return }
        
        let visibleRect = self.visibleRect
        let rate = UserDefaults.standard[.overscrollRate].clamped(to: 0...1.0)
        let inset = rate * (visibleRect.height - layoutManager.lineHeight)
        
        // halve inset since the input value will be added to both top and bottom
        let height = max((inset / 2).rounded(.down), Self.textContainerInset.height)
        let diff = height - self.textContainerInset.height
        
        guard diff != 0 else { return }
        
        let heightPath = (self.layoutOrientation == .vertical) ? \NSSize.width : \NSSize.height
        self.textContainerInset.height = height
        self.frame.size[keyPath: heightPath] += 2 * diff
        
        // invoke `setToFit()` but only when needed to avoid heavy calculation by large document
        // -> `setToFit()` is required to remove the extra height of the frame that contains a blank margin already
        //    due to the smaller text content than the visible rect (macOS 10.15).
        guard let textContainer = self.textContainer else { return assertionFailure() }
        let maxVisibleYGlyphIndex = layoutManager.glyphIndex(for: NSPoint(x: 0, y: visibleRect.height), in: textContainer)
        let maxVisibleY = layoutManager.isValidGlyphIndex(maxVisibleYGlyphIndex)
            ? layoutManager.lineFragmentRect(forGlyphAt: maxVisibleYGlyphIndex, effectiveRange: nil, withoutAdditionalLayout: true).maxY
            : 0
        if maxVisibleY < visibleRect.height {
            self.sizeToFit()
        }
        
        self.scrollToVisible(visibleRect)
    }
    
    
    /// Validates whether turns the non-contiguous layout on.
    private func invalidateNonContiguousLayout() {
        
        self.layoutManager?.allowsNonContiguousLayout = if self.layoutOrientation == .vertical {
            // disable non-contiguous layout on vertical layout (2016-06 on OS X 10.11 - macOS 13)
            //  -> Otherwise by vertical layout, the view scrolls occasionally a bit on typing.
            false
        } else {
            self.string.length > UserDefaults.standard[.minimumLengthForNonContiguousLayout]
        }
    }
    
    
    /// Inserts string representation of dropped files applying the user's file drop settings.
    ///
    /// - Parameter urls: The file URLs of dropped files.
    /// - Returns: Whether the file drop was performed.
    private func insertDroppedFiles(_ urls: [URL]) -> Bool {
        
        guard !urls.isEmpty else { return false }
        
        let fileDropItems = UserDefaults.standard[.fileDropArray].map(FileDropItem.init(dictionary:))
        let documentURL = self.document?.fileURL
        let syntax = self.document?.syntaxParser.syntax.name
        
        let replacementString = urls.reduce(into: "") { (string, url) in
            if url.pathExtension == "textClipping", let textClipping = try? TextClipping(contentsOf: url) {
                string += textClipping.string
                return
            }
            
            if let fileDropItem = fileDropItems.first(where: { $0.supports(extension: url.pathExtension, scope: syntax) }) {
                string += fileDropItem.dropText(forFileURL: url, documentURL: documentURL)
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
    
    
    /// Highlights the brace matching to the brace next to the cursor.
    private func highlightMatchingBrace() {
        
        let bracePairs = BracePair.braces + (UserDefaults.standard[.highlightLtGt] ? [.ltgt] : [])
        
        self.highlightMatchingBrace(candidates: bracePairs)
    }
    
    
    /// Highlights all instances of the selection.
    ///
    /// - Parameter delay: The delay time to start highlighting instance.
    private func highlightInstances(after delay: Duration) {
        
        self.instanceHighlightTask?.cancel()
        self.instanceHighlightTask = Task.detached { [weak self] in
            try await Task.sleep(for: delay, tolerance: delay * 0.2)  // debounce
            
            guard let self else { return }
            
            let (string, selectedRange): (String, NSRange) = try await MainActor.run {
                guard
                    !self.string.isEmpty,  // important to avoid crash after closing editor
                    !self.selectedRange.isEmpty,
                    !self.hasMarkedText(),
                    self.insertionLocations.isEmpty,
                    self.selectedRanges.count == 1
                else { throw CancellationError() }
                
                return (self.string.immutable, self.selectedRange)
            }
            
            guard (try! NSRegularExpression(pattern: "\\A\\b\\w.*\\w\\b\\z"))
                .firstMatch(in: string, options: [.withTransparentBounds], range: selectedRange) != nil
            else { return }
            
            let substring = (string as NSString).substring(with: selectedRange)
            let pattern = "\\b" + NSRegularExpression.escapedPattern(for: substring) + "\\b"
            let regex = try! NSRegularExpression(pattern: pattern)
            let ranges = try regex.cancellableMatches(in: string, range: string.nsRange).map(\.range)
            
            guard
                let lower = ranges.first?.lowerBound,
                let upper = ranges.last?.upperBound
            else { return }
            
            await MainActor.run {
                guard let layoutManager = self.layoutManager else { return }
                
                let color = self.instanceHighlightColor
                layoutManager.groupTemporaryAttributesUpdate(in: NSRange(lower..<upper)) {
                    for range in ranges {
                        layoutManager.addTemporaryAttribute(.roundedBackgroundColor, value: color, forCharacterRange: range)
                    }
                }
            }
        }
    }
}



// MARK: - Text Find

extension EditorTextView: TextFinderClient {
    
    /// Delivers the Cocoa standard text find action messages to the TextFinder instance.
    override func performTextFinderAction(_ sender: Any?) {
        
        self.performEditorTextFinderAction(sender)
    }
    
    
    /// Delivers text find actions for EditorTextView to the TextFinder instance.
    @IBAction func performEditorTextFinderAction(_ sender: Any?) {
        
        guard
            let tag = (sender as? any NSValidatedUserInterfaceItem)?.tag ?? (sender as? NSControl)?.tag,
            let action = TextFinder.Action(rawValue: tag)
        else { return }
        
        self.textFinder.performAction(action)
    }
    
    
    /// Performs find next.
    @IBAction func matchNext(_ sender: Any?) {
        
        self.textFinder.performAction(.nextMatch)
    }
    
    
    /// Performs find previous.
    @IBAction func matchPrevious(_ sender: Any?) {
        
        self.textFinder.performAction(.previousMatch)
    }
    
    
    /// Performs incremental search.
    @IBAction func incrementalSearch(_ sender: Any?) {
        
        self.textFinder.incrementalSearch()
    }
}



// MARK: - Word Completion

extension EditorTextView {
    
    // MARK: Text View Methods
    
    override var rangeForUserCompletion: NSRange {
        
        let range = super.rangeForUserCompletion
        
        guard !self.string.isEmpty else { return range }
        
        let firstSyntaxLetters = self.syntaxCompletionWords.compactMap(\.unicodeScalars.first)
        let firstLetterSet = CharacterSet(firstSyntaxLetters).union(.letters).union(.init(["_"]))
        
        // expand range until hitting a character that isn't in the word completion candidates
        let searchRange = NSRange(location: 0, length: range.upperBound)
        let invalidRange = (self.string as NSString).rangeOfCharacter(from: firstLetterSet.inverted, options: .backwards, range: searchRange)
        
        guard !invalidRange.isNotFound else { return range }
        
        return NSRange(invalidRange.upperBound..<range.upperBound)
    }
    
    
    override func completions(forPartialWordRange charRange: NSRange, indexOfSelectedItem index: UnsafeMutablePointer<Int>) -> [String]? {
        
        // do nothing if completion is not suggested from the typed characters
        guard !charRange.isEmpty else { return nil }
        
        var candidateWords = OrderedSet<String>()
        let partialWord = (self.string as NSString).substring(with: charRange)
        
        // add words in document
        if UserDefaults.standard[.completesDocumentWords] {
            let documentWords: [String] = {
                // do nothing if the particle word is a symbol
                guard charRange.length > 1 || CharacterSet.alphanumerics.contains(partialWord.unicodeScalars.first!) else { return [] }
                
                let pattern = "(?:^|\\b|(?<=\\W))" + NSRegularExpression.escapedPattern(for: partialWord) + "\\w+?(?:$|\\b)"
                let regex = try! NSRegularExpression(pattern: pattern)
                
                return regex.matches(in: self.string, range: self.string.nsRange).map { (self.string as NSString).substring(with: $0.range) }
            }()
            candidateWords.append(contentsOf: documentWords)
        }
        
        // add words defined in syntax
        if UserDefaults.standard[.completesSyntaxWords] {
            let syntaxWords = self.syntaxCompletionWords.filter { $0.range(of: partialWord, options: [.caseInsensitive, .anchored]) != nil }
            candidateWords.append(contentsOf: syntaxWords)
        }
        
        // add the standard words from default completion words
        if UserDefaults.standard[.completesStandardWords] {
            let words = super.completions(forPartialWordRange: charRange, indexOfSelectedItem: index) ?? []
            candidateWords.append(contentsOf: words)
        }
        
        // provide nothing if there is only a candidate which is same as input word
        if let word = candidateWords.first,
           candidateWords.count == 1,
           word.caseInsensitiveCompare(partialWord) == .orderedSame
        {
            return []
        }
        
        return candidateWords.array
    }
    
    
    override func insertCompletion(_ word: String, forPartialWordRange charRange: NSRange, movement: Int, isFinal flag: Bool) {
        
        self.completionDebouncer.cancel()
        self.needsRecompletion = false
        
        self.isShowingCompletion = !flag
        
        // store original string
        if self.partialCompletionWord == nil {
            self.partialCompletionWord = (self.string as NSString).substring(with: charRange)
        }
        
        // raise flag to proceed word completion again, if a normal key input is performed during displaying the completion list
        // -> The flag will be used in `didChangeText()`.
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
               character < 0xF700, character != Int16(NSDeleteCharacter)
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
                    // -> In case if the letter case is changed from the original.
                    if let originalWord = self.partialCompletionWord {
                        word = originalWord
                    }
                default:
                    didComplete = true
            }
            
            // discard stored original word
            self.partialCompletionWord = nil
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
    
    /// Displays the word completion candidates list.
    private func performCompletion() {
        
        // abord if:
        guard
            !self.hasMarkedText(),  // input is not specified (for Japanese input)
            self.selectedRange.isEmpty,  // selected
            let lastCharacter = self.character(before: self.selectedRange), !CharacterSet.whitespacesAndNewlines.contains(lastCharacter)  // previous character is blank
        else { return }
        
        if let nextCharacter = self.character(after: self.selectedRange), CharacterSet.alphanumerics.contains(nextCharacter) { return }  // cursor is (probably) at the middle of a word
        
        self.complete(self)
    }
}



// MARK: - Word Selection

extension EditorTextView {
    
    // MARK: Text View Methods
    
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
            range.length == 1  // clicked character can be a brace
        else { return range }
        
        let characterIndex = String.Index(utf16Offset: range.lowerBound, in: self.string)
        let clickedCharacter = self.string[characterIndex]
        
        // select (syntax-highlighted) quoted text
        if ["\"", "'", "`"].contains(clickedCharacter),
           let highlightRange = self.layoutManager?.effectiveRange(of: .syntaxType, at: range.location)
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
                    return NSRange(characterIndex...characterIndex, in: self.string)  // By double-clicking an odd brace, only the clicked brace should be selected.
            }
        }
        
        return range
    }
    
    
    
    // MARK: Public Methods
    
    /// Returns the word range that includes the given location.
    ///
    /// - Parameter location: The character index to find the word range.
    /// - Returns: The range of a word.
    func wordRange(at location: Int) -> NSRange {
        
        let proposedWordRange = super.selectionRange(forProposedRange: NSRange(location: location, length: 0), granularity: .selectByWord)
        
        guard proposedWordRange.contains(location) else { return proposedWordRange }
        
        // treat `.` and `:` as word delimiter
        return (self.string as NSString).rangeOfCharacter(until: CharacterSet(charactersIn: ".:"), at: location, range: proposedWordRange)
    }
}
