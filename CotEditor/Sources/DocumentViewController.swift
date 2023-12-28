//
//  DocumentViewController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-06-05.
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

private let maximumNumberOfSplitEditors = 4


final class DocumentViewController: NSSplitViewController, DocumentOwner, ThemeChanging, NSToolbarItemValidation {
    
    private enum SerializationKey {
        
        static let theme = "theme"
    }
    
    
    // MARK: Public Properties
    
    var document: Document  {
        
        didSet {
            self.statusBarViewController.document = document
            self.updateDocument()
        }
    }
    
    
    // MARK: Private Properties
    
    /// Keys for NSNumber values to be restored from the last session (Bool is also an NSNumber).
    private static var restorableNumberStateKeyPaths: [String] = [
        #keyPath(showsLineNumber),
        #keyPath(showsPageGuide),
        #keyPath(showsIndentGuides),
        #keyPath(showsInvisibles),
        #keyPath(wrapsLines),
        #keyPath(verticalLayoutOrientation),
        #keyPath(isAutoTabExpandEnabled),
        #keyPath(writingDirection),
    ]
    
    private lazy var splitViewController = SplitViewController()
    private lazy var statusBarViewController: StatusBarController = NSStoryboard(name: "StatusBar", bundle: nil)
        .instantiateInitialController { StatusBarController(document: self.document, coder: $0) }!
    private weak var statusBarItem: NSSplitViewItem?
    
    private var documentSyntaxObserver: AnyCancellable?
    private var outlineObserver: AnyCancellable?
    private var appearanceObserver: AnyCancellable?
    private var defaultsObservers: Set<AnyCancellable> = []
    private var themeChangeObserver: AnyCancellable?
    
    private lazy var outlineParseDebouncer = Debouncer(delay: .seconds(0.4)) { [weak self] in self?.syntaxParser.invalidateOutline() }
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    init(document: Document) {
        
        self.document = document
        
        super.init(nibName: nil, bundle: nil)
        
        self.updateDocument()
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSTextView.didChangeSelectionNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: EditorTextView.didLiveChangeSelectionNotification, object: nil)
    }
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.splitView.isVertical = false
        
        // set identifier for state restoration
        self.identifier = NSUserInterfaceItemIdentifier("DocumentViewController")
        
        self.addChild(self.splitViewController)
        
        // set status bar
        let statusBarItem = NSSplitViewItem(viewController: self.statusBarViewController)
        statusBarItem.isCollapsed = true  // avoid initial view loading
        self.addSplitViewItem(statusBarItem)
        self.statusBarItem = statusBarItem
        
        // set first editor view
        self.addEditorView()
        
        // set user defaults
        let defaults = UserDefaults.standard
        switch defaults[.writingDirection] {
            case .leftToRight:
                break
            case .rightToLeft:
                self.writingDirection = .rightToLeft
            case .vertical:
                self.verticalLayoutOrientation = true
        }
        statusBarItem.isCollapsed = !defaults[.showStatusBar]
        self.setTheme(name: ThemeManager.shared.userDefaultSettingName)
        self.defaultsObservers = [
            defaults.publisher(for: .showStatusBar, initial: false)
                .sink { [weak self] in self?.statusBarItem?.animator().isCollapsed = !$0 },
            defaults.publisher(for: .theme, initial: false)
                .sink { [weak self] in self?.setTheme(name: $0) },
            defaults.publisher(for: .showInvisibles, initial: true)
                .sink { [weak self] in self?.showsInvisibles = $0 },
            defaults.publisher(for: .showLineNumbers, initial: true)
                .sink { [weak self] in self?.showsLineNumber = $0 },
            defaults.publisher(for: .wrapLines, initial: true)
                .sink { [weak self] in self?.wrapsLines = $0 },
            defaults.publisher(for: .showPageGuide, initial: true)
                .sink { [weak self] in self?.showsPageGuide = $0 },
            defaults.publisher(for: .showIndentGuides, initial: true)
                .sink { [weak self] in self?.showsIndentGuides = $0 },
        ]
        
        // observe theme change
        self.themeChangeObserver = ThemeManager.shared.didUpdateSetting
            .filter { [weak self] in $0.old == self?.theme?.name }
            .compactMap(\.new)
            .throttle(for: 0.1, scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] in self?.setTheme(name: $0) }
        
        // observe appearance change for theme toggle
        self.appearanceObserver = self.view.publisher(for: \.effectiveAppearance)
            .sink { [weak self] appearance in
                guard
                    let self,
                    !UserDefaults.standard[.pinsThemeAppearance],
                    self.view.window != nil,
                    let currentThemeName = self.theme?.name,
                    let themeName = ThemeManager.shared.equivalentSettingName(to: currentThemeName, forDark: appearance.isDark),
                    currentThemeName != themeName
                else { return }
                
                self.setTheme(name: themeName)
            }
    }
    
    
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        // focus text view
        self.view.window?.makeFirstResponder(self.focusedTextView)
    }
    
    
    override class var restorableStateKeyPaths: [String] {
        
        super.restorableStateKeyPaths + self.restorableNumberStateKeyPaths
    }
    
    
    override class func allowedClasses(forRestorableStateKeyPath keyPath: String) -> [AnyClass] {
        
        if self.restorableNumberStateKeyPaths.contains(keyPath) {
            [NSNumber.self]
        } else {
            super.allowedClasses(forRestorableStateKeyPath: keyPath)
        }
    }
    
    
    override func encodeRestorableState(with coder: NSCoder, backgroundQueue queue: OperationQueue) {
        
        super.encodeRestorableState(with: coder, backgroundQueue: queue)
        
        if let themeName = self.theme?.name {
            coder.encode(themeName, forKey: SerializationKey.theme)
        }
    }
    
    
    override func restoreState(with coder: NSCoder) {
        
        super.restoreState(with: coder)
        
        if let storedThemeName = coder.decodeObject(of: NSString.self, forKey: SerializationKey.theme) as? String {
            let themeName = UserDefaults.standard[.pinsThemeAppearance]
                ? storedThemeName
                : ThemeManager.shared.equivalentSettingName(to: storedThemeName, forDark: self.view.effectiveAppearance.isDark) ?? storedThemeName
            
            if themeName != self.theme?.name {
                self.setTheme(name: themeName)
            }
        }
    }
    
    
    
    // MARK: Split View Controller Methods
    
    override func splitView(_ splitView: NSSplitView, effectiveRect proposedEffectiveRect: NSRect, forDrawnRect drawnRect: NSRect, ofDividerAt dividerIndex: Int) -> NSRect {
        
        // avoid showing draggable cursor for the status bar boundary
        .zero
    }
    
    
    func validateToolbarItem(_ item: NSToolbarItem) -> Bool {
        
        // manually pass toolbar items to `validateUserInterfaceItem(_:)`,
        // because they actually doesn't use it for validation (2020-08 on macOS 10.15)
        self.validateUserInterfaceItem(item)
    }
    
    
    override func validateUserInterfaceItem(_ item: any NSValidatedUserInterfaceItem) -> Bool {
        
        switch item.action {
            case #selector(changeTheme):
                if let item = item as? NSMenuItem {
                    item.state = (self.theme?.name == item.title) ? .on : .off
                }
                
            case #selector(toggleLineNumber):
                (item as? NSMenuItem)?.title = self.showsLineNumber
                    ? String(localized: "Hide Line Numbers")
                    : String(localized: "Show Line Numbers")
                
            case #selector(toggleStatusBar):
                (item as? NSMenuItem)?.title = self.statusBarItem?.isCollapsed == false
                    ? String(localized: "Hide Status Bar")
                    : String(localized: "Show Status Bar")
                
            case #selector(togglePageGuide):
                (item as? NSMenuItem)?.title = self.showsPageGuide
                    ? String(localized: "Hide Page Guide")
                    : String(localized: "Show Page Guide")
                (item as? StatableToolbarItem)?.state = self.showsPageGuide ? .on : .off
                
            case #selector(toggleIndentGuides):
                (item as? NSMenuItem)?.title = self.showsIndentGuides
                    ? String(localized: "Hide Indent Guides")
                    : String(localized: "Show Indent Guides")
                (item as? NSToolbarItem)?.toolTip = self.showsIndentGuides
                    ? String(localized: "Hide indent guide lines")
                    : String(localized: "Show indent guide lines")
                (item as? StatableToolbarItem)?.state = self.showsIndentGuides ? .on : .off
                
            case #selector(toggleLineWrap):
                (item as? NSMenuItem)?.title = self.wrapsLines
                    ? String(localized: "Unwrap Lines")
                    : String(localized: "Wrap Lines")
                (item as? NSToolbarItem)?.toolTip = self.wrapsLines
                    ? String(localized: "Unwrap lines")
                    : String(localized: "Wrap lines")
                (item as? StatableToolbarItem)?.state = self.wrapsLines ? .on : .off
                
            case #selector(toggleInvisibleChars):
                (item as? NSMenuItem)?.title = self.showsInvisibles
                    ? String(localized: "Hide Invisibles")
                    : String(localized: "Show Invisibles")
                (item as? StatableToolbarItem)?.state = self.showsInvisibles ? .on : .off
                
                // disable if item cannot be enabled
                let canActivateShowInvisibles = !UserDefaults.standard.showsInvisible.isEmpty
                item.toolTip = canActivateShowInvisibles
                    ? nil
                    : String(localized: "To show invisible characters, set them in the Window settings",
                             comment: "Tooltip for “Show Invisibles” menu item and toolbar item for when all invisible settings are disabled")
                if canActivateShowInvisibles {
                    (item as? NSToolbarItem)?.toolTip = self.showsInvisibles
                        ? String(localized: "Hide invisible characters")
                        : String(localized: "Show invisible characters")
                }
                return canActivateShowInvisibles
                
            case #selector(toggleAntialias):
                (item as? any StatableItem)?.state = (self.focusedTextView?.usesAntialias ?? false) ? .on : .off
                
            case #selector(toggleLigatures):
                (item as? any StatableItem)?.state = (self.focusedTextView?.ligature != NSTextView.LigatureMode.none) ? .on : .off
                
            case #selector(toggleAutoTabExpand):
                (item as? any StatableItem)?.state = self.isAutoTabExpandEnabled ? .on : .off
                (item as? NSToolbarItem)?.toolTip = self.isAutoTabExpandEnabled
                    ? String(localized: "Use tabs for indentation")
                    : String(localized: "Use spaces for indentation")
                
            case #selector(changeTabWidth):
                (item as? any StatableItem)?.state = (self.tabWidth == item.tag) ? .on : .off
                
            case #selector(makeFontStandard):
                let standardFont = UserDefaults.standard.font(for: .standard)
                let monospacedFont = UserDefaults.standard.font(for: .monospaced)
                (item as? NSMenuItem)?.state = (self.font == standardFont && standardFont != monospacedFont) ? .on : .off
                
            case #selector(makeFontMonospaced):
                let monospacedFont = UserDefaults.standard.font(for: .monospaced)
                (item as? NSMenuItem)?.state = (self.font == monospacedFont) ? .on : .off
                
            case #selector(makeLayoutOrientationHorizontal):
                (item as? any StatableItem)?.state = self.verticalLayoutOrientation ? .off : .on
                
            case #selector(makeLayoutOrientationVertical):
                (item as? any StatableItem)?.state = self.verticalLayoutOrientation ? .on : .off
                
            case #selector(makeWritingDirectionLeftToRight):
                (item as? any StatableItem)?.state = (self.writingDirection == .leftToRight) ? .on : .off
                
            case #selector(makeWritingDirectionRightToLeft):
                (item as? any StatableItem)?.state = (self.writingDirection == .rightToLeft) ? .on : .off
                
            case #selector(changeWritingDirection):
                (item as? NSToolbarItemGroup)?.selectedIndex = switch self.writingDirection {
                    case _ where self.verticalLayoutOrientation: -1
                    case .rightToLeft: 1
                    default: 0
                }
                
            case #selector(changeOrientation):
                (item as? NSToolbarItemGroup)?.selectedIndex = self.verticalLayoutOrientation ? 1 : 0
                
            case #selector(showOpacitySlider):
                return self.view.window?.styleMask.contains(.fullScreen) == false
                
            case #selector(closeSplitTextView):
                return self.splitViewController.splitViewItems.count > 1
                
            default: break
        }
        
        return super.validateUserInterfaceItem(item)
    }
    
    
    
    // MARK: Notifications
    
    /// Invoked when the text was edited (invoked right **before** notifying layout managers).
    override func textStorageDidProcessEditing(_ notification: Notification) {
        
        let textStorage = notification.object as! NSTextStorage
        
        guard
            textStorage.editedMask.contains(.editedCharacters),
            self.focusedTextView?.hasMarkedText() != true
        else { return }
        
        self.document.analyzer.invalidate()
        self.document.incompatibleCharacterScanner.invalidate()
        self.outlineParseDebouncer.schedule()
        
        // -> Perform in the next run loop to give layoutManagers time to update their values.
        let editedRange = textStorage.editedRange
        DispatchQueue.main.async { [weak self] in
            self?.syntaxParser.highlight(around: editedRange)
        }
    }
    
    
    /// Invoked when the selection did change.
    @objc private func textViewDidLiveChangeSelection(_ notification: Notification) {
        
        self.document.analyzer.invalidate(onlySelection: true)
    }
    
    
    /// The document updated its syntax.
    private func didChangeSyntax() {
        
        for viewController in self.editorViewControllers {
            viewController.apply(syntax: self.syntaxParser.syntax)
        }
        
        self.outlineParseDebouncer.perform()
        self.syntaxParser.highlight()
    }
    
    
    
    // MARK: Public Methods
    
    /// The text view currently focused on.
    var focusedTextView: EditorTextView? {
        
        self.splitViewController.focusedChild?.textView ?? self.editorViewControllers.first?.textView
    }
    
    
    /// The coloring theme.
    var theme: Theme? {
        
        self.focusedTextView?.theme
    }
    
    
    /// The editor's font.
    var font: NSFont? {
        
        self.focusedTextView?.font
    }
    
    
    /// The visibility of line numbers views.
    @objc dynamic var showsLineNumber = false {
        
        didSet {
            for viewController in self.editorViewControllers {
                viewController.showsLineNumber = showsLineNumber
            }
        }
    }
    
    
    /// Whether lines soft-wrap at the window edge.
    @objc dynamic var wrapsLines = false {
        
        didSet {
            for textView in self.editorViewControllers.compactMap(\.textView) {
                textView.wrapsLines = wrapsLines
            }
        }
    }
    
    
    /// The visibility of page guide lines in text views.
    @objc dynamic var showsPageGuide = false {
        
        didSet {
            for textView in self.editorViewControllers.compactMap(\.textView) {
                textView.showsPageGuide = showsPageGuide
            }
        }
    }
    
    
    /// The visibility of indent guides in the text views.
    @objc dynamic var showsIndentGuides = false {
        
        didSet {
            for textView in self.editorViewControllers.compactMap(\.textView) {
                textView.showsIndentGuides = showsIndentGuides
            }
        }
    }
    
    
    /// The visibility of invisible characters.
    @objc dynamic var showsInvisibles = false {
        
        didSet {
            for textView in self.editorViewControllers.compactMap(\.textView) {
                textView.showsInvisibles = showsInvisibles
            }
        }
    }
    
    
    /// Whether the text orientation in the text views is vertical.
    @objc dynamic var verticalLayoutOrientation: Bool = false {
        
        didSet {
            self.document.isVerticalText = verticalLayoutOrientation
            
            let orientation: NSLayoutManager.TextLayoutOrientation = verticalLayoutOrientation ? .vertical : .horizontal
            
            for textView in self.editorViewControllers.compactMap(\.textView) {
                textView.setLayoutOrientation(orientation)
            }
        }
    }
    
    
    /// The writing direction of the text views.
    @objc dynamic var writingDirection: NSWritingDirection = .leftToRight {
        
        didSet {
            for textView in self.editorViewControllers.compactMap(\.textView) where textView.baseWritingDirection != writingDirection {
                textView.baseWritingDirection = writingDirection
            }
        }
    }
    
    
    /// The tab width of the text views.
    var tabWidth: Int {
        
        get {
            self.focusedTextView?.tabWidth ?? 0
        }
        
        set {
            for textView in self.editorViewControllers.compactMap(\.textView) {
                textView.tabWidth = newValue
            }
        }
    }
    
    
    /// Whether tabs are replaced with spaces.
    @objc dynamic var isAutoTabExpandEnabled: Bool {
        
        get {
            self.focusedTextView?.isAutomaticTabExpansionEnabled ?? UserDefaults.standard[.autoExpandTab]
        }
        
        set {
            for textView in self.editorViewControllers.compactMap(\.textView) {
                textView.isAutomaticTabExpansionEnabled = newValue
            }
        }
    }
    
    
    /// Applies editor styles to the text storage and update editor views.
    func invalidateStyleInTextStorage() {
        
        assert(Thread.isMainThread)
        
        guard
            let textView = self.focusedTextView,
            let textStorage = textView.textStorage
        else { return assertionFailure() }
        
        guard textStorage.length > 0 else { return }
        
        textStorage.addAttributes(textView.typingAttributes, range: textStorage.range)
        
        self.editorViewControllers
            .compactMap(\.textView)
            .forEach { $0.setNeedsDisplay($0.visibleRect) }
    }
    
    
    
    // MARK: Action Messages
    
    /// Recolors whole document.
    @IBAction func recolorAll(_ sender: Any?) {
        
        self.syntaxParser.highlight()
    }
    
    
    /// Sets new theme from a menu item.
    @IBAction func changeTheme(_ sender: NSMenuItem) {
        
        self.setTheme(name: sender.title)
    }
    
    
    /// Toggles the visibility of the line number views.
    @IBAction func toggleLineNumber(_ sender: Any?) {
        
        self.showsLineNumber.toggle()
    }
    
    
    /// Toggles the visibility of status bar with fancy animation (sync all documents).
    @IBAction func toggleStatusBar(_ sender: Any?) {
        
        UserDefaults.standard[.showStatusBar].toggle()
    }
    
    
    /// Toggles the visibility of page guide line in the text views.
    @IBAction func togglePageGuide(_ sender: Any?) {
        
        self.showsPageGuide.toggle()
    }
    
    
    /// Toggles the visibility of indent guides in the text views.
    @IBAction func toggleIndentGuides(_ sender: Any?) {
        
        self.showsIndentGuides.toggle()
    }
    
    
    /// Toggles if lines wrap at the window edge.
    @IBAction func toggleLineWrap(_ sender: Any?) {
        
        self.wrapsLines.toggle()
    }
    
    
    /// Toggles the visibility of invisible characters in the text views.
    @IBAction func toggleInvisibleChars(_ sender: Any?) {
        
        self.showsInvisibles.toggle()
    }
    
    
    /// Toggles if antialias text in the text views.
    @IBAction func toggleAntialias(_ sender: Any?) {
        
        for textView in self.editorViewControllers.compactMap(\.textView) {
            textView.usesAntialias.toggle()
        }
    }
    
    
    /// Toggles the ligature mode in the text views.
    @IBAction func toggleLigatures(_ sender: Any?) {
        
        for textView in self.editorViewControllers.compactMap(\.textView) {
            textView.ligature = (textView.ligature == .none) ? .standard : .none
        }
    }
    
    
    /// Toggles if the text views expand tab input.
    @IBAction func toggleAutoTabExpand(_ sender: Any?) {
        
        self.isAutoTabExpandEnabled.toggle()
    }
    
    
    /// Changes the tab width from a menu item.
    @IBAction func changeTabWidth(_ sender: NSMenuItem) {
        
        self.tabWidth = sender.tag
    }
    
    
    /// Changes the tab width to desired number through a sheet.
    @IBAction func customizeTabWidth(_ sender: Any?) {
        
        let view = CustomTabWidthView(tabWidth: self.tabWidth) { [weak self] tabWidth in
            self?.tabWidth = tabWidth
        }
        let viewController = NSHostingController(rootView: view)
        viewController.rootView.parent = viewController
        
        self.presentAsSheet(viewController)
    }
    
    
    /// Changes the font to the user's standard font.
    @IBAction func makeFontStandard(_ sender: Any?) {
        
        for textView in self.editorViewControllers.compactMap(\.textView) {
            textView.setFont(type: .standard)
        }
    }
    
    
    /// Changes the font to the user's monospaced font.
    @IBAction func makeFontMonospaced(_ sender: Any?) {
        
        for textView in self.editorViewControllers.compactMap(\.textView) {
            textView.setFont(type: .monospaced)
        }
    }
    
    
    /// Makes text layout orientation horizontal.
    @IBAction func makeLayoutOrientationHorizontal(_ sender: Any?) {
        
        self.verticalLayoutOrientation = false
    }
    
    
    /// Makes the text layout orientation vertical.
    @IBAction func makeLayoutOrientationVertical(_ sender: Any?) {
        
        self.verticalLayoutOrientation = true
    }
    
    
    /// Makes the entire writing direction left-to-right.
    @IBAction func makeWritingDirectionLeftToRight(_ sender: Any?) {
        
        self.writingDirection = .leftToRight
    }
    
    
    /// Makes the entire writing direction right-to-left.
    @IBAction func makeWritingDirectionRightToLeft(_ sender: Any?) {
        
        self.verticalLayoutOrientation = false
        self.writingDirection = .rightToLeft
    }
    
    
    /// Changes writing direction by a grouped toolbar item.
    @IBAction func changeWritingDirection(_ sender: NSToolbarItemGroup) {
        
        assertionFailure("This is a dummy action designed to be used just for the segmentation selection validation.")
    }
    
    
    /// Changes layout orientation by a grouped toolbar item.
    @IBAction func changeOrientation(_ sender: NSToolbarItemGroup) {
        
        assertionFailure("This is a dummy action designed to be used just for the segmentation selection validation.")
    }
    
    
    /// Shows the editor opacity slider as popover.
    @IBAction func showOpacitySlider(_ sender: Any?) {
        
        let opacityView = OpacityView(window: self.view.window as? DocumentWindow)
        let viewController = NSHostingController(rootView: opacityView)
        
        if #available(macOS 14, *), let toolbarItem = sender as? NSToolbarItem {
            let popover = NSPopover()
            popover.behavior = .semitransient
            popover.contentViewController = viewController
            popover.show(relativeTo: toolbarItem)
            
        } else {
            viewController.sizingOptions = .preferredContentSize
            self.present(viewController, asPopoverRelativeTo: .zero, of: self.view,
                         preferredEdge: .maxY, behavior: .transient)
        }
    }
    
    
    /// Splits editor view.
    @IBAction func openSplitTextView(_ sender: Any?) {
        
        guard self.splitViewController.splitViewItems.count < maximumNumberOfSplitEditors else { return NSSound.beep() }
        
        guard
            let currentEditorViewController = self.baseEditorViewController(for: sender)
        else { return assertionFailure() }
        
        // end current editing
        NSTextInputContext.current?.discardMarkedText()
        
        let newEditorViewController = self.addEditorView(below: currentEditorViewController)
        self.replace(document: self.document, in: newEditorViewController)
        
        // copy parsed syntax highlight
        if let textView = newEditorViewController.textView,
           let highlights = currentEditorViewController.textView?.layoutManager?.syntaxHighlights(),
            !highlights.isEmpty
        {
            textView.layoutManager?.apply(highlights: highlights, range: textView.string.range)
        }
        
        // adjust visible areas
        if let selectedRange = currentEditorViewController.textView?.selectedRange {
            newEditorViewController.textView?.selectedRange = selectedRange
            currentEditorViewController.textView?.scrollRangeToVisible(selectedRange)
            newEditorViewController.textView?.scrollRangeToVisible(selectedRange)
        }
        
        // move focus to the new editor
        self.view.window?.makeFirstResponder(newEditorViewController.textView)
    }
    
    
    /// Closes one of the split editors.
    @IBAction func closeSplitTextView(_ sender: Any?) {
        
        assert(self.splitViewController.splitViewItems.count > 1)
        
        guard let currentEditorViewController = self.baseEditorViewController(for: sender) else { return }
        
        if let textView = currentEditorViewController.textView {
            NotificationCenter.default.removeObserver(self, name: NSTextView.didChangeSelectionNotification, object: textView)
        }
        
        // end current editing
        NSTextInputContext.current?.discardMarkedText()
        
        // move focus to the next text view if the view to close has a focus
        if self.splitViewController.focusedChild == currentEditorViewController {
            let children = self.editorViewControllers
            let deleteIndex = children.firstIndex(of: currentEditorViewController) ?? 0
            let newFocusEditorViewController = children[safe: deleteIndex - 1] ?? children.last!
            
            self.view.window?.makeFirstResponder(newFocusEditorViewController.textView)
        }
        
        // close
        currentEditorViewController.removeFromParent()
    }
    
    
    
    // MARK: Private Methods
    
    /// The document's syntax parser.
    private var syntaxParser: SyntaxParser {
        
        self.document.syntaxParser
    }
    
    
    /// The array of all child editor view controllers.
    private var editorViewControllers: [EditorViewController] {
        
        self.splitViewController.children.compactMap { $0 as? EditorViewController }
    }
    
    
    /// Sets the receiver and its children with the given document.
    private func updateDocument() {
        
        for editorViewController in self.editorViewControllers {
            self.replace(document: self.document, in: editorViewController)
        }
        
        // detect indent style
        if UserDefaults.standard[.detectsIndentStyle],
           let indentStyle = self.document.textStorage.string.detectedIndentStyle
        {
            self.isAutoTabExpandEnabled = switch indentStyle {
                case .tab: false
                case .space: true
            }
        }
        
        // start parsing syntax for highlighting and outlines
        self.outlineParseDebouncer.perform()
        self.document.syntaxParser.highlight()
        
        NotificationCenter.default.addObserver(self, selector: #selector(textStorageDidProcessEditing),
                                               name: NSTextStorage.didProcessEditingNotification,
                                               object: self.document.textStorage)
        
        // observe syntax change
        self.documentSyntaxObserver = self.document.didChangeSyntax
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.didChangeSyntax() }
        
        // observe syntaxParser for outline update
        self.outlineObserver = self.document.syntaxParser.$outlineItems
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] outlineItems in
                self?.editorViewControllers.forEach { $0.outlineItems = outlineItems }
            }
    }
    
    
    /// Creates a new split editor.
    ///
    /// - Parameter otherViewController: The view controller of the reference editor located above the editor to add.
    /// - Returns: The editor view controller created.
    @discardableResult
    private func addEditorView(below otherViewController: EditorViewController? = nil) -> EditorViewController {
        
        let viewController = EditorViewController()
        
        let splitViewItem = NSSplitViewItem(viewController: viewController)
        splitViewItem.minimumThickness = 100
        
        // add to the split view
        let index = otherViewController
            .flatMap { self.splitViewController.children.firstIndex(of: $0) }?
            .advanced(by: 1) ?? 0
        self.splitViewController.insertSplitViewItem(splitViewItem, at: index)
        
        // observe cursor
        NotificationCenter.default.addObserver(self, selector: #selector(textViewDidLiveChangeSelection),
                                               name: EditorTextView.didLiveChangeSelectionNotification,
                                               object: viewController.textView)
        
        // setup textView
        let textView = viewController.textView!
        textView.wrapsLines = self.wrapsLines
        textView.showsInvisibles = self.showsInvisibles
        textView.setLayoutOrientation(self.verticalLayoutOrientation ? .vertical : .horizontal)
        textView.baseWritingDirection = self.writingDirection
        textView.showsPageGuide = self.showsPageGuide
        textView.showsIndentGuides = self.showsIndentGuides
        viewController.showsLineNumber = self.showsLineNumber  // need to be set after setting text orientation
        
        // copy base textView states
        if let baseTextView = otherViewController?.textView {
            textView.font = baseTextView.font
            textView.usesAntialias = baseTextView.usesAntialias
            textView.ligature = baseTextView.ligature
            textView.theme = baseTextView.theme
            textView.tabWidth = baseTextView.tabWidth
            textView.isAutomaticTabExpansionEnabled = baseTextView.isAutomaticTabExpansionEnabled
        }
        
        return viewController
    }
    
    
    /// Replaces the document in the editorViewController with the given document.
    ///
    /// - Parameters:
    ///   - document: The new document to be replaced with.
    ///   - editorViewController: The editor view controller of which document is replaced.
    private func replace(document: Document, in editorViewController: EditorViewController) {
        
        editorViewController.setTextStorage(document.textStorage)
        editorViewController.apply(syntax: document.syntaxParser.syntax)
        editorViewController.outlineItems = document.syntaxParser.outlineItems
    }
    
    
    /// Applies the given theme to child text views.
    ///
    /// - Parameter name: The name of the theme to apply.
    private func setTheme(name: String) {
        
        assert(Thread.isMainThread)
        
        guard let theme = ThemeManager.shared.setting(name: name) else { return }
        
        for textView in self.editorViewControllers.compactMap(\.textView) {
            textView.theme = theme
            textView.layoutManager?.invalidateHighlight(theme: theme)
        }
        
        self.invalidateRestorableState()
    }
    
    
    /// Finds the base `EditorViewController` for split editor management actions.
    ///
    /// - Parameter sender: The action sender.
    /// - Returns: An editor view controller, or `nil` if not found.
    private func baseEditorViewController(for sender: Any?) -> EditorViewController? {
        
        if let view = sender as? NSView,
           let controller = self.splitViewController.children
            .first(where: { view.isDescendant(of: $0.view) }) as? EditorViewController
        {
            return controller
        }
        
        return self.splitViewController.focusedChild
    }
}
