/*
 
 EditorTextView.swift
 
 CotEditor
 https://coteditor.com
 
 Created by nakamuxu on 2005-03-30.
 
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014-2018 1024jp
 
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

private extension NSAttributedStringKey {
    
    static let autoBalancedClosingBracket = NSAttributedStringKey("autoBalancedClosingBracket")
}


private let kTextContainerInset = NSSize(width: 0.0, height: 4.0)



// MARK: -

final class EditorTextView: NSTextView, Themable {
    
    // MARK: Notification Names
    
    static let didBecomeFirstResponderNotification = Notification.Name("TextViewDidBecomeFirstResponder")
    
    
    // MARK: Public Properties
    
    var isAutomaticTabExpansionEnabled = false
    
    var lineHighlightRect: NSRect?
    
    var inlineCommentDelimiter: String?
    var blockCommentDelimiters: BlockDelimiters?
    
    var firstSyntaxCompletionCharacterSet: CharacterSet?  // set of the first characters of the completion words
    var needsRecompletion = false
    
    // for Scaling extension
    var initialMagnificationScale: CGFloat = 0
    var deferredMagnification: CGFloat = 0
    
    private(set) lazy var completionTask: Debouncer = Debouncer { [weak container = self.textContainer] in  // NSTextView cannot be weak
        (container?.textView as? EditorTextView)?.performCompletion()
    }
    
    
    // MARK: Private Properties
    
    private let matchingBracketPairs: [BracePair] = BracePair.braces + [.doubleQuotes]
    
    private var balancesBrackets = false
    private var isAutomaticIndentEnabled = false
    private var isSmartIndentEnabled = false
    
    private var lineHighLightColor: NSColor?
    
    private var particalCompletionWord: String?
    
    private let observedDefaultKeys: [DefaultKeys] = [
        .autoExpandTab,
        .autoIndent,
        .enableSmartIndent,
        .smartInsertAndDelete,
        .balancesBrackets,
        .checkSpellingAsType,
        .pageGuideColumn,
        .enableSmartQuotes,
        .enableSmartDashes,
        .tabWidth,
        .hangingIndentWidth,
        .enablesHangingIndent,
        .autoLinkDetection,
        .fontName,
        .fontSize,
        .shouldAntialias,
        .lineHeight,
        ]
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    required init?(coder: NSCoder) {
        
        let defaults = UserDefaults.standard
        
        self.isAutomaticTabExpansionEnabled = defaults[.autoExpandTab]
        self.isAutomaticIndentEnabled = defaults[.autoIndent]
        self.isSmartIndentEnabled = defaults[.enableSmartIndent]
        self.balancesBrackets = defaults[.balancesBrackets]
        
        // set paragraph style values
        self.lineHeight = defaults[.lineHeight]
        self.tabWidth = defaults[.tabWidth]
        
        self.theme = ThemeManager.shared.theme(name: defaults[.theme]!)
        // -> will be applied first in `viewDidMoveToWindow()`
        
        super.init(coder: coder)
        
        // workaround for: the text selection highlight can remain between lines (2017-09 macOS 10.13).
        self.scaleUnitSquare(to: NSSize(width: 0.5, height: 0.5))
        self.scaleUnitSquare(to: self.convert(.unit, from: nil))  // reset scale
        
        // setup layoutManager and textContainer
        let layoutManager = LayoutManager()
        layoutManager.allowsNonContiguousLayout = true
        self.textContainer!.replaceLayoutManager(layoutManager)
        
        // set layout values
        self.minSize = self.frame.size
        self.maxSize = NSSize.infinite
        self.isHorizontallyResizable = true
        self.isVerticallyResizable = true
        self.textContainerInset = kTextContainerInset
        
        // set NSTextView behaviors
        self.baseWritingDirection = .leftToRight  // default is fixed in LTR
        self.allowsDocumentBackgroundColorChange = false
        self.allowsUndo = true
        self.isRichText = false
        self.importsGraphics = false
        self.usesFindPanel = true
        self.acceptsGlyphInfo = true
        self.linkTextAttributes = [.cursor: NSCursor.pointingHand,
                                   .underlineStyle: NSUnderlineStyle.styleSingle.rawValue]
        
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
        
        // observe change of defaults
        for key in self.observedDefaultKeys {
            UserDefaults.standard.addObserver(self, forKeyPath: key.rawValue, options: .new, context: nil)
        }
    }
    
    
    deinit {
        for key in self.observedDefaultKeys {
            UserDefaults.standard.removeObserver(self, forKeyPath: key.rawValue)
        }
    }
    
    
    
    // MARK: Text View Methods
    
    /// keys to be restored from the last session
    override class var restorableStateKeyPaths: [String] {
        
        return [#keyPath(layoutOrientation),
                #keyPath(font),
                #keyPath(tabWidth)]
    }
    
    
    /// post notification about becoming the first responder
    override func becomeFirstResponder() -> Bool {
        
        NotificationCenter.default.post(name: EditorTextView.didBecomeFirstResponderNotification, object: self)
        
        return super.becomeFirstResponder()
    }
    
    
    
    /// textView was attached to a window
    override func viewDidMoveToWindow() {
        
        super.viewDidMoveToWindow()
        
        guard let window = self.window else {
            // textView was removed from the window
            NotificationCenter.default.removeObserver(self, name: AlphaWindow.didChangeOpacityNotification, object: nil)
            NotificationCenter.default.removeObserver(self, name: NSView.boundsDidChangeNotification, object: nil)
            return
        }
        
        // apply theme to window
        self.applyTheme()
        
        // apply window opacity
        self.didWindowOpacityChange(nil)
        
        // observe window opacity flag
        NotificationCenter.default.addObserver(self, selector: #selector(didWindowOpacityChange),
                                               name: AlphaWindow.didChangeOpacityNotification,
                                               object: window)
        
        // observe scorolling and resizing to fix drawing area on non-opaque view
        if let scrollView = self.enclosingScrollView {
            NotificationCenter.default.addObserver(self, selector: #selector(didChangeVisibleRect(_:)), name: NSView.boundsDidChangeNotification, object: scrollView.contentView)
        } else {
            assertionFailure("failed starting observing the visible rect change")
        }
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
    
    
    /// on inputting text (NSTextInputClient Protocol)
    override func insertText(_ string: Any, replacementRange: NSRange) {
        
        // do not use this method for programmatical insertion.
        
        // cast NSAttributedString to String in order to make sure input string is plain-text
        guard let plainString: String = {
            switch string {
            case let attrString as NSAttributedString:
                return attrString.string
            case let string as String:
                return string
            default: return nil
            }
            }() else { return super.insertText(string, replacementRange: replacementRange) }
        
        // swap '¥' with '\' if needed
        if UserDefaults.standard[.swapYenAndBackSlash], plainString.count == 1 {
            switch plainString {
            case "\\":
                return super.insertText("¥", replacementRange: replacementRange)
            case "¥":
                return super.insertText("\\", replacementRange: replacementRange)
            default: break
            }
        }
        
        // balance brackets and quotes
        if self.balancesBrackets && replacementRange.length == 0,
            plainString.unicodeScalars.count == 1,
            let firstChar = plainString.first,
            let pair = self.matchingBracketPairs.first(where: { $0.begin == firstChar })
        {
            // wrap selection with brackets if some text is selected
            if self.selectedRange.length > 0 {
                self.surroundSelections(begin: String(pair.begin), end: String(pair.end))
                return
                
            // check if insertion point is in a word
            } else if
                !CharacterSet.alphanumerics.contains(self.characterAfterInsertion ?? UnicodeScalar(0)),
                !(pair.begin == pair.end && CharacterSet.alphanumerics.contains(self.characterBeforeInsertion ?? UnicodeScalar(0)))  // for "
            {
                let pairedBrackets = String(pair.begin) + String(pair.end)
            
                super.insertText(pairedBrackets, replacementRange: replacementRange)
                self.selectedRange = NSRange(location: self.selectedRange.location - 1, length: 0)
                
                // set flag
                self.textStorage?.addAttribute(.autoBalancedClosingBracket, value: true,
                                               range: NSRange(location: self.selectedRange.location, length: 1))
                
                return
            }
        }
        
        // just move cursor if closed bracket is already typed
        if self.balancesBrackets && replacementRange.length == 0,
            let nextCharacter = self.characterAfterInsertion,
            let firstCharacter = plainString.first, firstCharacter == Character(nextCharacter),
            BracePair.braces.contains(where: { $0.end == firstCharacter }),  // ignore "
            self.textStorage?.attribute(.autoBalancedClosingBracket, at: self.selectedRange.location, effectiveRange: nil) as? Bool ?? false
        {
            self.selectedRange.location += 1
            return
        }
        
        // smart outdent with '}' charcter
        if self.isAutomaticIndentEnabled, self.isSmartIndentEnabled,
            replacementRange.length == 0, plainString == "}",
            let insertionIndex = Range(self.selectedRange, in: self.string)?.upperBound
        {
            let wholeString = self.string
            let lineRange = wholeString.lineRange(at: insertionIndex)
            
            // decrease indent level if the line is consists of only whitespaces
            if wholeString.range(of: "^[ \\t]+\\n?$", options: .regularExpression, range: lineRange) != nil,
                let precedingIndex = wholeString.indexOfBracePair(endIndex: insertionIndex, pair: BracePair("{", "}")) {
                let desiredLevel = wholeString.indentLevel(at: precedingIndex, tabWidth: self.tabWidth)
                let currentLevel = wholeString.indentLevel(at: insertionIndex, tabWidth: self.tabWidth)
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
            self.completionTask.schedule(delay: delay)
        }
    }
    
    
    /// insert tab & expand tab
    override func insertTab(_ sender: Any?) {
        
        // indent with tab key
        if UserDefaults.standard[.indentWithTabKey], self.selectedRange.length > 0 {
            self.indent()
            return
        }
        
        if self.isAutomaticTabExpansionEnabled {
            let tabWidth = self.tabWidth
            let column = self.string.column(of: self.rangeForUserTextChange.location, tabWidth: tabWidth)
            let length = tabWidth - (column % tabWidth)
            let spaces = String(repeating: " ", count: length)
            
            return super.insertText(spaces, replacementRange: self.rangeForUserTextChange)
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
        
        guard self.isAutomaticIndentEnabled else {
            return super.insertNewline(sender)
        }
        
        let string = self.string
        let indentRange = string.rangeOfIndent(at: self.selectedRange.location)
        
        // don't auto-indent if indent is selected (2008-12-13)
        guard indentRange.length == 0 || indentRange != self.selectedRange else {
            return super.insertNewline(sender)
        }
        
        let indent: String = {
            guard let baseIndentRange = indentRange.intersection(NSRange(location: 0, length: self.selectedRange.location)) else {
                return ""
            }
            return (string as NSString).substring(with: baseIndentRange)
        }()
        
        // calculation for smart indent
        var shouldIncreaseIndentLevel = false
        var shouldExpandBlock = false
        if self.isSmartIndentEnabled {
            let lastCharacter = self.characterBeforeInsertion
            let nextCharacter = self.characterAfterInsertion
            
            // expand idnent block if returned inside `{}`
            shouldExpandBlock = (lastCharacter == "{" && nextCharacter == "}")
            
            // increace font indent level if the character just before the return is `:` or `{`
            shouldIncreaseIndentLevel = (lastCharacter == ":" || lastCharacter == "{")
        }
        
        super.insertNewline(sender)
        
        // auto indent
        if !indent.isEmpty {
            super.insertText(indent, replacementRange: self.rangeForUserTextChange)
        }
        
        // smart indent
        if shouldExpandBlock {
            self.insertTab(sender)
            let selection = self.selectedRange
            super.insertNewline(sender)
            super.insertText(indent, replacementRange: self.rangeForUserTextChange)
            self.selectedRange = selection
            
        } else if shouldIncreaseIndentLevel {
            self.insertTab(sender)
        }
    }
    
    
    /// delete & adjust indent
    override func deleteBackward(_ sender: Any?) {
        
        defer {
            super.deleteBackward(sender)
        }
        
        guard self.selectedRange.length == 0 else { return }
        
        let string = self.string
        let location = self.selectedRange.location
        
        // delete tab
        if self.isAutomaticTabExpansionEnabled,
            string.rangeOfIndent(at: location).upperBound >= location
        {
            let tabWidth = self.tabWidth
            let column = string.column(of: location, tabWidth: tabWidth)
            let targetLength = tabWidth - (column % tabWidth)
            let targetRange = NSRange(location: location - targetLength, length: targetLength)
            
            if location >= targetLength,
                (string as NSString).substring(with: targetRange) == String(repeating: " ", count: targetLength) {
                self.selectedRange = targetRange
            }
        }
        
        // balance brackets
        if self.balancesBrackets,
            let lastCharacter = self.characterBeforeInsertion,
            let nextCharacter = self.characterAfterInsertion,
            self.matchingBracketPairs.contains(where: { $0.begin == Character(lastCharacter) && $0.end == Character(nextCharacter) })
        {
            self.selectedRange = NSRange(location: location - 1, length: 2)
        }
    }
    
    
    /// move cursor to the beginning of the current visual line (⌘←)
    override func moveToBeginningOfLine(_ sender: Any?) {
        
        let range = NSRange(location: self.locationOfBeginningOfLine(), length: 0)
        
        self.setSelectedRange(range, affinity: .downstream, stillSelecting: false)
        self.scrollRangeToVisible(range)
    }
    
    
    /// expand selection to the beginning of the current visual line (⇧⌘←)
    override func moveToBeginningOfLineAndModifySelection(_ sender: Any?) {
        
        let range = NSRange(location: self.locationOfBeginningOfLine(), length: 0)
            .union(self.selectedRange)
        
        self.setSelectedRange(range, affinity: .downstream, stillSelecting: false)
        self.scrollRangeToVisible(range)
    }
    
    
    /// customize context menu
    override func menu(for event: NSEvent) -> NSMenu? {
        
        guard let menu = super.menu(for: event) else { return nil }
        
        // remove unwanted "Font" menu and its submenus
        if let fontMenuItem = menu.item(withTitle: NSLocalizedString("Font", comment: "menu item title in the context menu")) {
            menu.removeItem(fontMenuItem)
        }
        
        // add "Inspect Character" menu item if single character is selected
        if (self.string as NSString).substring(with: self.selectedRange).numberOfComposedCharacters == 1 {
            menu.insertItem(withTitle: NSLocalizedString("Inspect Character", comment: ""),
                            action: #selector(showSelectionInfo(_:)),
                            keyEquivalent: "",
                            at: 1)
        }
        
        // add "Copy as Rich Text" menu item
        let copyIndex = menu.indexOfItem(withTarget: nil, andAction: #selector(copy(_:)))
        if copyIndex >= 0 {  // -1 == not found
            menu.insertItem(withTitle: NSLocalizedString("Copy as Rich Text", comment: ""),
                            action: #selector(copyWithStyle(_:)),
                            keyEquivalent: "",
                            at: copyIndex + 1)
        }
        
        // add "Select All" menu item
        let pasteIndex = menu.indexOfItem(withTarget: nil, andAction: #selector(paste(_:)))
        if pasteIndex >= 0 {  // -1 == not found
            menu.insertItem(withTitle: NSLocalizedString("Select All", comment: ""),
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
            let manager = sender as? NSFontManager,
            let currentFont = self.font,
            let textStorage = self.textStorage
            else { return }
        
        let font = manager.convert(currentFont)
        
        // apply to all text views sharing textStorage
        for layoutManager in textStorage.layoutManagers {
            layoutManager.firstTextView?.font = font
        }
    }
    
    
    /// draw background
    override func drawBackground(in rect: NSRect) {
        
        super.drawBackground(in: rect)
        
        // draw current line highlight
        if let highlightColor = self.lineHighLightColor,
            let highlightRect = self.lineHighlightRect,
            rect.intersects(highlightRect)
        {
            NSGraphicsContext.saveGraphicsState()
            
            highlightColor.setFill()
            NSBezierPath.fill(highlightRect)
            
            NSGraphicsContext.restoreGraphicsState()
        }
    }
    
    
    /// draw view
    override func draw(_ dirtyRect: NSRect) {
        
        // minimize drawing area on non-opaque background
        // -> Otherwise, all textView (from the top to the bottom) is everytime drawn
        //    and it affects to the drawing performance on a large document critically.
        var dirtyRect = dirtyRect
        if !self.drawsBackground {
            dirtyRect = self.visibleRect
        }
        
        super.draw(dirtyRect)
        
        // draw page guide
        if self.showsPageGuide,
            let textColor = self.textColor,
            let spaceWidth = (self.layoutManager as? LayoutManager)?.spaceWidth
        {
            let column = UserDefaults.standard[.pageGuideColumn]
            let inset = self.textContainerOrigin.x
            let linePadding = self.textContainer?.lineFragmentPadding ?? 0
            var x = floor(spaceWidth * CGFloat(column) + inset + linePadding) + 2.5  // +2px for an esthetic adjustment
            if self.baseWritingDirection == .rightToLeft {
                x = self.bounds.width - x
            }
            
            NSGraphicsContext.saveGraphicsState()
            
            textColor.withAlphaComponent(0.2).setStroke()
            NSBezierPath.strokeLine(from: NSPoint(x: x, y: dirtyRect.minY),
                                    to: NSPoint(x: x, y: dirtyRect.maxY))
            
            NSGraphicsContext.restoreGraphicsState()
        }
    }
    
    
    /// scroll to display specific range
    override func scrollRangeToVisible(_ range: NSRange) {
        
        // scroll line by line if an arrow key is pressed
        if NSEvent.modifierFlags.contains(.numericPad),
            let layoutManager = self.layoutManager,
            let textContainer = self.textContainer
        {
            layoutManager.ensureLayout(forCharacterRange: NSRange(location: 0, length: range.upperBound))
            let glyphRange = layoutManager.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
            let glyphRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
                .offset(by: self.textContainerOrigin)
            
            super.scrollToVisible(glyphRect)  // move minimum distance
            return
        }
        
        super.scrollRangeToVisible(range)
    }
    
    
    /// change text layout orientation
    override func setLayoutOrientation(_ orientation: NSLayoutManager.TextLayoutOrientation) {
        
        guard self.layoutOrientation != orientation else { return }
        
        self.minSize = self.minSize.rotated
        
        // -> needs send kvo notification manually on Swift? (2016-09-12 on macOS 10.12 SDK)
        self.willChangeValue(forKey: #keyPath(layoutOrientation))
        
        super.setLayoutOrientation(orientation)
        
        self.didChangeValue(forKey: #keyPath(layoutOrientation))
        
        // enable non-contiguous layout only on normal horizontal layout (2016-06 on OS X 10.11 El Capitan)
        //  -> Otherwise by vertical layout, the view scrolls occasionally to a strange position on typing.
        self.layoutManager?.allowsNonContiguousLayout = (orientation == .horizontal)
        
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
        
        return super.readSelection(from: pboard, type: type)
    }
    
    
    /// convert line endings in pasteboard to document's line ending
    override func writeSelection(to pboard: NSPasteboard, types: [NSPasteboard.PasteboardType]) -> Bool {
        
        let success = super.writeSelection(to: pboard, types: types)
        
        guard let lineEnding = self.documentLineEnding, lineEnding == .LF else { return success }
        
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
    
    
    /// update font panel to set current font
    override func updateFontPanel() {
        
        // フォントのみをフォントパネルに渡す
        // -> super にやらせると、テキストカラーもフォントパネルに送り、フォントパネルがさらにカラーパネル（= カラーコードパネル）にそのテキストカラーを渡すので、
        // それを断つために自分で渡す
        guard let font = self.font else { return }
        
        NSFontManager.shared.setSelectedFont(font, isMultiple: false)
    }
    
    
    /// let line number view update
    override func updateRuler() {
        
        (self.enclosingScrollView as? EditorScrollView)?.invalidateLineNumber()
    }
    
    
    
    // MARK: KVO
    
    /// apply change of user setting
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        
        guard let keyPath = keyPath, let newValue = change?[.newKey] else { return }
        
        switch keyPath {
        case DefaultKeys.autoExpandTab.rawValue:
            self.isAutomaticTabExpansionEnabled = newValue as! Bool
            
        case DefaultKeys.autoIndent.rawValue:
            self.isAutomaticIndentEnabled = newValue as! Bool
            
        case DefaultKeys.enableSmartIndent.rawValue:
            self.isSmartIndentEnabled = newValue as! Bool
            
        case DefaultKeys.balancesBrackets.rawValue:
            self.balancesBrackets = newValue as! Bool
            
        case DefaultKeys.shouldAntialias.rawValue:
            self.usesAntialias = newValue as! Bool
            
        case DefaultKeys.smartInsertAndDelete.rawValue:
            self.smartInsertDeleteEnabled = newValue as! Bool
            
        case DefaultKeys.enableSmartQuotes.rawValue:
            self.isAutomaticQuoteSubstitutionEnabled = newValue as! Bool
            
        case DefaultKeys.enableSmartDashes.rawValue:
            self.isAutomaticDashSubstitutionEnabled = newValue as! Bool
            
        case DefaultKeys.checkSpellingAsType.rawValue:
            self.isContinuousSpellCheckingEnabled = newValue as! Bool
            
        case DefaultKeys.autoLinkDetection.rawValue:
            self.isAutomaticLinkDetectionEnabled = newValue as! Bool
            if self.isAutomaticLinkDetectionEnabled {
                self.detectLinkIfNeeded()
            } else {
                if let textStorage = self.textStorage {
                    textStorage.removeAttribute(.link, range: textStorage.mutableString.range)
                }
            }
            
        case DefaultKeys.pageGuideColumn.rawValue:
            self.setNeedsDisplay(self.visibleRect, avoidAdditionalLayout: true)
            
        case DefaultKeys.tabWidth.rawValue:
            self.tabWidth = newValue as! Int
            
        case DefaultKeys.fontName.rawValue, DefaultKeys.fontSize.rawValue:
            self.resetFont(nil)
            
        case DefaultKeys.lineHeight.rawValue:
            self.lineHeight = newValue as! CGFloat
            
            // reset visible area
            self.centerSelectionInVisibleArea(self)
            
        case DefaultKeys.enablesHangingIndent.rawValue, DefaultKeys.hangingIndentWidth.rawValue:
            let wholeRange = self.string.nsRange
            if keyPath == DefaultKeys.enablesHangingIndent.rawValue, !(newValue as! Bool) {
                if let paragraphStyle = self.defaultParagraphStyle {
                    self.textStorage?.addAttribute(.paragraphStyle, value: paragraphStyle, range: wholeRange)
                } else {
                    self.textStorage?.removeAttribute(.paragraphStyle, range: wholeRange)
                }
            } else {
                (self.layoutManager as? LayoutManager)?.invalidateIndent(in: wholeRange)
            }
            
        default: break
        }
    }
    
    
    
    // MARK: Protocol
    
    /// apply current state to related menu items and toolbar items
    override func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        
        guard let action = item.action else { return false }
        
        switch action {
        case #selector(copyWithStyle):
            return self.selectedRange.length > 0
            
        case #selector(showSelectionInfo):
            let selection = (self.string as NSString).substring(with: self.selectedRange)
            return selection.numberOfComposedCharacters == 1
            
        case #selector(toggleComment):
            if let menuItem = item as? NSMenuItem {
                let canComment = self.canUncomment(range: self.selectedRange, partly: false)
                let title = canComment ? "Uncomment" : "Comment Out"
                menuItem.title = NSLocalizedString(title, comment: "")
            }
            return (self.inlineCommentDelimiter != nil) || (self.blockCommentDelimiters != nil)
            
        case #selector(inlineCommentOut):
            return (self.inlineCommentDelimiter != nil)
            
        case #selector(blockCommentOut):
            return (self.blockCommentDelimiters != nil)
            
        case #selector(uncomment(_:)):
            return self.canUncomment(range: self.selectedRange, partly: true)
            
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
            if tabWidth == 0 {
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
            if lineHeight == 0 {
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
        
        guard let textStorage = self.textStorage else { return }
        
        let range = textStorage.mutableString.range
        
        guard range.length > 0 else { return }
        
        textStorage.addAttributes(self.typingAttributes, range: range)
        (self.layoutManager as? LayoutManager)?.invalidateIndent(in: range)
        self.detectLinkIfNeeded()
    }
    
    
    
    // MARK: Action Messages
    
    /// copy selection with syntax highlight and font style
    @IBAction func copyWithStyle(_ sender: Any?) {
        
        guard self.selectedRange.length > 0 else {
            NSSound.beep()
            return
        }
        
        let string = self.string
        var selections = [NSAttributedString]()
        var propertyList = [Int]()
        let lineEnding = String((self.documentLineEnding ?? .LF).rawValue)
        
        // substring all selected attributed strings
        let selectedRanges = self.selectedRanges as! [NSRange]
        for selectedRange in selectedRanges {
            let plainText = (string as NSString).substring(with: selectedRange)
            let styledText = NSMutableAttributedString(string: plainText, attributes: self.typingAttributes)
            
            // apply syntax highlight that is set as temporary attributes in layout manager to attributed string
            if let layoutManager = self.layoutManager {
                var characterIndex = selectedRange.location
                while characterIndex < selectedRange.upperBound {
                    var effectiveRange = NSRange.notFound
                    guard let color = layoutManager.temporaryAttribute(.foregroundColor,
                                                                       atCharacterIndex: characterIndex,
                                                                       longestEffectiveRange: &effectiveRange,
                                                                       in: selectedRange)
                        else {
                            characterIndex += 1
                            continue
                    }
                    
                    let localRange = NSRange(location: effectiveRange.location - selectedRange.location, length: effectiveRange.length)
                    styledText.addAttribute(.foregroundColor, value: color, range: localRange)
                    
                    characterIndex = effectiveRange.upperBound
                }
            }
            
            // apply document's line ending
            if self.documentLineEnding != .LF {
                for (index, character) in zip(plainText.indices, plainText).reversed() where character == "\n" {  // process backwards
                    let characterRange = NSRange(index...index, in: plainText)
                    
                    styledText.replaceCharacters(in: characterRange, with: lineEnding)
                }
            }
            
            selections.append(styledText)
            propertyList.append(plainText.components(separatedBy: .newlines).count)
        }
        
        var pasteboardString = NSAttributedString()
        
        // join attributed strings
        let attrLineEnding = NSAttributedString(string: lineEnding)
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
        pboard.declareTypes(self.writablePasteboardTypes, owner: nil)
        if pboard.canReadItem(withDataConformingToTypes: [NSPasteboard.PasteboardType.multipleTextSelection.rawValue]) {
            pboard.setPropertyList(propertyList, forType: .multipleTextSelection)
        }
        pboard.writeObjects([pasteboardString])
    }
    
    
    /// input an Yen sign (¥)
    @IBAction func inputYenMark(_ sender: Any?) {
        
        super.insertText("¥", replacementRange: self.rangeForUserTextChange)
    }
    
    
    ///input a backslash (\\)
    @IBAction func inputBackSlash(_ sender: Any?) {
        
        super.insertText("\\", replacementRange: self.rangeForUserTextChange)
    }
    
    
    /// display character information by popover
    @IBAction func showSelectionInfo(_ sender: Any?) {
        
        var selectedString = (self.string as NSString).substring(with: self.selectedRange)
        
        // apply document's line ending
        if let documentLineEnding = self.documentLineEnding,
            documentLineEnding != .LF, selectedString.detectedLineEnding == .LF
        {
            selectedString = selectedString.replacingLineEndings(with: documentLineEnding)
        }
        
        guard
            let popoverController = CharacterPopoverController(character: selectedString),
            let selectedRect = self.boundingRect(for: self.selectedRange)
            else { return }
        
        let positioningRect = self.convertToLayer(selectedRect).offsetBy(dx: 0, dy: -4)
        
        popoverController.showPopover(relativeTo: positioningRect, of: self)
        self.showFindIndicator(for: self.selectedRange)
    }
    
    
    
    // MARK: Notification
    
    /// window's opacity did change
    @objc private func didWindowOpacityChange(_ notification: Notification?) {
        
        let isOpaque = self.window?.isOpaque ?? true
        
        // let text view have own background if possible
        self.drawsBackground = isOpaque
        
        // make the current line highlight a bit transparent
        let highlightAlpha: CGFloat = isOpaque ? 1.0 : 0.7
        self.lineHighLightColor = self.lineHighLightColor?.withAlphaComponent(highlightAlpha)
        
        // redraw visible area
        self.setNeedsDisplay(self.visibleRect, avoidAdditionalLayout: true)
    }
    
    
    /// visible rect did change
    @objc private func didChangeVisibleRect(_ notification: Notification) {
        
        if !self.drawsBackground {
            // -> Needs display visible rect since drawing area is modified in draw(_ dirtyFrame:)
            self.setNeedsDisplay(self.visibleRect, avoidAdditionalLayout: true)
        }
    }
    
    
    
    // MARK: Private Methods
    
    /// document object representing the text view contents
    private var document: Document? {
        
        return self.window?.windowController?.document as? Document
    }
    
    
    /// true new line type of document
    private var documentLineEnding: LineEnding? {
        
        return self.document?.lineEnding
    }
    
    
    /// update coloring settings
    private func applyTheme() {
        
        assert(Thread.isMainThread)
        
        guard let theme = self.theme else { return }
        
        self.window?.backgroundColor = theme.backgroundColor
        
        self.backgroundColor = theme.backgroundColor
        self.textColor = theme.textColor
        self.lineHighLightColor = theme.lineHighLightColor
        self.insertionPointColor = theme.insertionPointColor
        self.selectedTextAttributes = [.backgroundColor: theme.selectionColor]
        
        (self.layoutManager as? LayoutManager)?.invisiblesColor = theme.invisiblesColor
        
        // set scroller color considering background color
        self.enclosingScrollView?.scrollerKnobStyle = theme.isDarkTheme ? .light : .default
        
        self.setNeedsDisplay(self.visibleRect, avoidAdditionalLayout: true)
    }
    
    
    /// set defaultParagraphStyle based on font, tab width, and line height
    private func invalidateDefaultParagraphStyle() {
        
        assert(Thread.isMainThread)
        
        let paragraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        
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
    
    
    /// make link-like text clickable
    private func detectLinkIfNeeded() {
        
        assert(Thread.isMainThread)
        
        guard self.isAutomaticLinkDetectionEnabled else { return }
        
        self.undoManager?.disableUndoRegistration()
        
        let currentCheckingType = self.enabledTextCheckingTypes
        self.enabledTextCheckingTypes = NSTextCheckingResult.CheckingType.link.rawValue
        self.checkTextInDocument(nil)
        self.enabledTextCheckingTypes = currentCheckingType
        
        self.undoManager?.enableUndoRegistration()
    }
    
    
    /// insert string representation of dropped files applying user setting
    private func insertDroppedFiles(_ urls: [URL]) -> Bool {
        
        guard !urls.isEmpty else { return false }
        
        let composer = FileDropComposer(definitions: UserDefaults.standard[.fileDropArray])
        let documentURL = self.document?.fileURL
        let syntaxStyle: String? = {
            guard let style = self.document?.syntaxStyle, !style.isNone else { return nil }
            return style.styleName
        }()
        
        let replacementString = urls.reduce(into: "") { (string, url) in
            if let dropText = composer.dropText(forFileURL: url, documentURL: documentURL, syntaxStyle: syntaxStyle) {
                string += dropText
                return
            }
            
            // jsut insert the absolute path if no specific setting for the file type was found
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
    
}




// MARK: - Word Completion

extension EditorTextView {
    
    // MARK: Text View Methods
    
    /// return range for word completion
    override var rangeForUserCompletion: NSRange {
        
        let range = super.rangeForUserCompletion
        
        // expand range until hitting to a character that isn't in the word completion candidates
        guard
            !self.string.isEmpty,
            let characterSet = self.firstSyntaxCompletionCharacterSet,
            let beginIndex = String.UTF16Index(encodedOffset: range.location).samePosition(in: self.string),
            let index = self.string.rangeOfCharacter(from: characterSet.inverted, options: .backwards, range: self.string.startIndex..<beginIndex)?.upperBound
            else { return range }
        
        let location = index.samePosition(in: self.string.utf16)!.encodedOffset
        
        return NSRange(location: location, length: range.upperBound - location)
    }
    
    
    /// display completion candidate and list
    override func insertCompletion(_ word: String, forPartialWordRange charRange: NSRange, movement: Int, isFinal flag: Bool) {
        
        self.completionTask.cancel()
        
        let event = self.window?.currentEvent
        var didComplete = false
        
        var newMovement = movement
        var newFlag = flag
        var newWord = word
        
        // store original string
        if self.particalCompletionWord == nil {
            self.particalCompletionWord = (self.string as NSString).substring(with: charRange)
        }
        
        // raise frag to proceed word completion again, if a normal key input is performed during displaying the completion list
        //   -> The flag will be used in EditorTextViewController > `textDidChange`
        if flag, let event = event, event.type == .keyDown, !event.modifierFlags.contains(.command) {
            let inputChar = event.charactersIgnoringModifiers
            
            if inputChar == event.characters {  // exclude key-bindings
                // fix that underscore is treated as the right arrow key
                if inputChar == "_", movement == NSRightTextMovement {
                    newMovement = NSIllegalTextMovement
                    newFlag = false
                }
                if let character = inputChar?.utf16.first,
                    (movement == NSIllegalTextMovement && character < 0xF700 && character != UInt16(NSDeleteCharacter)) {  // standard key-input
                    self.needsRecompletion = true
                }
            }
        }
        
        if newFlag {
            if newMovement == NSIllegalTextMovement || newMovement == NSRightTextMovement {  // treat as cancelled
                // restore original input
                //   -> In case if the letter case is changed from the original.
                if let originalWord = self.particalCompletionWord {
                    newWord = originalWord
                }
            } else {
                didComplete = true
            }
            
            // discard stored orignal word
            self.particalCompletionWord = nil
        }
        
        super.insertCompletion(newWord, forPartialWordRange: charRange, movement: newMovement, isFinal: newFlag)
        
        guard didComplete else { return }
        
        // slect inside of "()" if completion word has ()
        var rangeToSelect = (newWord as NSString).range(of: "(?<=\\().*(?=\\))", options: .regularExpression)
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
            self.selectedRange.length == 0,  // selected
            let lastCharacter = self.characterBeforeInsertion, !CharacterSet.whitespacesAndNewlines.contains(lastCharacter)  // previous character is blank
            else { return }
        
        if let nextCharacter = self.characterAfterInsertion, CharacterSet.alphanumerics.contains(nextCharacter) { return }  // caret is (probably) at the middle of a word
        
        self.complete(self)
    }
    
}



// MARK: - Word Selection

extension EditorTextView {
    
    // MARK: Text View Methods
    
    /// adjust word selection range
    override func selectionRange(forProposedRange proposedCharRange: NSRange, granularity: NSSelectionGranularity) -> NSRange {
        
        let range = super.selectionRange(forProposedRange: proposedCharRange, granularity: granularity)
        
        guard
            granularity == .selectByWord,
            self.string.utf16.count != proposedCharRange.location
            else { return range }
        
        var wordRange = range
        
        // treat additional specific characters as separator (see `wordRange(at:)` for details)
        if wordRange.length > 0 {
            wordRange = self.wordRange(at: proposedCharRange.location)
            if proposedCharRange.length > 1 {
                wordRange.formUnion(self.wordRange(at: proposedCharRange.upperBound - 1))
            }
        }
        
        // settle result on expanding selection or if there is no possibility for clicking brackets
        guard proposedCharRange.length == 0, wordRange.length == 1 else { return wordRange }
        
        let characterIndex = String.UTF16Index(encodedOffset: wordRange.location).samePosition(in: self.string)!
        let clickedCharacter = self.string[characterIndex]
        
        // select (syntax-highlighted) quoted text by double-clicking
        if clickedCharacter == "\"" || clickedCharacter == "'" || clickedCharacter == "`" {
            var highlightRange = NSRange.notFound
            _ = self.layoutManager?.temporaryAttribute(.foregroundColor, atCharacterIndex: wordRange.location, longestEffectiveRange: &highlightRange, in: self.string.nsRange)
            
            let highlightCharacterRange = Range(highlightRange, in: self.string)!
            let firstHighlightIndex = highlightCharacterRange.lowerBound
            let lastHighlightIndex = self.string.index(before: highlightCharacterRange.upperBound)
            
            if (firstHighlightIndex == characterIndex && self.string[firstHighlightIndex] == clickedCharacter) ||  // smart quote
                (lastHighlightIndex == characterIndex && self.string[lastHighlightIndex] == clickedCharacter)  // end quote
            {
                return highlightRange
            }
        }
        
        // select inside of brackets by double-clicking
        if let pairIndex = self.string.indexOfBracePair(at: characterIndex, candidates: BracePair.braces + [.ltgt]) {
            switch pairIndex {
            case .begin(let beginIndex):
                return NSRange(beginIndex...characterIndex, in: self.string)
            case .end(let endIndex):
                return NSRange(characterIndex...endIndex, in: self.string)
            case .odd:
                // If it has a found a "begin" brace but not found a match, a double-click should only select the "begin" brace and not what it usually would select at a double-click
                NSSound.beep()
                return NSRange(location: proposedCharRange.location, length: 1)
            }
        }
        
        return wordRange
    }
    
    
    
    // MARK: Private Methods
    
    /// word range includes location
    private func wordRange(at location: Int) -> NSRange {
        
        let proposedWordRange = super.selectionRange(forProposedRange: NSRange(location: location, length: 0), granularity: .selectByWord)
        
        guard proposedWordRange.length > 1,
            let proposedRange = Range(proposedWordRange, in: self.string),
            let locationIndex = String.UTF16Index(encodedOffset: location).samePosition(in: self.string) else { return proposedWordRange }
        
        let wordRange = self.string.rangeOfCharacters(from: CharacterSet(charactersIn: ".:").inverted, at: locationIndex, range: proposedRange) ?? proposedRange
        
        return NSRange(wordRange, in: self.string)
    }
    
}
