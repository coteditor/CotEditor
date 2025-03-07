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
import Defaults
import Syntax
import ControlUI

@Observable final class SplitState {
    
    var isVertical: Bool
    var canClose: Bool
    
    
    init(isVertical: Bool = false, canClose: Bool = false) {
        
        self.isVertical = isVertical
        self.canClose = canClose
    }
}


final class DocumentViewController: NSSplitViewController, ThemeChanging, NSToolbarItemValidation {
    
    private enum SerializationKey {
        
        static let theme = "theme"
    }
    
    
    // MARK: Public Properties
    
    let document: Document
    
    
    // MARK: Private Properties
    
    private static let maximumNumberOfSplitEditors = 4
    
    private let splitState = SplitState()
    
    private weak var focusedChild: EditorViewController?
    
    private var observers: Set<AnyCancellable> = []
    private var defaultsObservers: Set<AnyCancellable> = []
    
    private lazy var outlineParseDebouncer = Debouncer(delay: .seconds(0.4)) { [weak self] in self?.document.syntaxParser.invalidateOutline() }
    
    
    // MARK: Lifecycle
    
    init(document: Document) {
        
        self.document = document
        
        super.init(nibName: nil, bundle: nil)
        
        // set identifier for state restoration
        self.identifier = NSUserInterfaceItemIdentifier("DocumentViewController")
        
        switch UserDefaults.standard[.writingDirection] {
            case .leftToRight:
                break
            case .rightToLeft:
                self.writingDirection = .rightToLeft
            case .vertical:
                self.verticalLayoutOrientation = true
        }
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSTextStorage.didProcessEditingNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: EditorTextView.didLiveChangeSelectionNotification, object: nil)
    }
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.splitView.isVertical = UserDefaults.standard[.splitViewVertical]
        self.splitState.isVertical = self.splitView.isVertical
        
        // set first editor view
        self.addEditorView()
        self.setTheme(name: ThemeManager.shared.userDefaultSettingName)
        
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
        self.document.syntaxParser.highlightAll()
        
        NotificationCenter.default.addObserver(self, selector: #selector(textStorageDidProcessEditing),
                                               name: NSTextStorage.didProcessEditingNotification,
                                               object: self.document.textStorage)
        
        // observe
        self.observers = [
            // observe syntax change
            self.document.didChangeSyntax
                .sink { [weak self] _ in
                    self?.outlineParseDebouncer.perform()
                    self?.document.syntaxParser.highlightAll()
                },
            
            // observe theme change
            UserDefaults.standard.publisher(for: .theme, initial: false)
                .sink { [weak self] in self?.setTheme(name: $0) },
            NotificationCenter.default.publisher(for: .didUpdateSettingNotification, object: ThemeManager.shared)
                .map { $0.userInfo!["change"] as! SettingChange }
                .filter { [weak self] in $0.old == self?.theme?.name }
                .compactMap(\.new)
                .throttle(for: 0.1, scheduler: DispatchQueue.main, latest: true)
                .sink { [weak self] in self?.setTheme(name: $0) },
            
            // observe editable change
            self.document.$isEditable
                .receive(on: RunLoop.main)
                .sink { [weak self] isEditable in
                    self?.editorViewControllers
                        .compactMap(\.textView)
                        .forEach { $0.isEditable = isEditable }
                },
            
            // observe appearance change for theme toggle
            self.view.publisher(for: \.effectiveAppearance)
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
                },
            
            // observe focus change
            NotificationCenter.default.publisher(for: EditorTextView.didBecomeFirstResponderNotification)
                .map { $0.object as! EditorTextView }
                .compactMap { [weak self] textView in self?.editorViewControllers.first { $0.textView == textView } }
                .sink { [weak self] in self?.focusedChild = $0 },
        ]
    }
    
    
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        // focus text view
        self.view.window?.makeFirstResponder(self.focusedTextView)
        
        // observe user defaults
        self.defaultsObservers = [
            UserDefaults.standard.publisher(for: .showInvisibles, initial: true)
                .sink { [weak self] in self?.showsInvisibles = $0 },
            UserDefaults.standard.publisher(for: .showLineNumbers, initial: true)
                .sink { [weak self] in self?.showsLineNumber = $0 },
            UserDefaults.standard.publisher(for: .wrapLines, initial: true)
                .sink { [weak self] in self?.wrapsLines = $0 },
            UserDefaults.standard.publisher(for: .showPageGuide, initial: true)
                .sink { [weak self] in self?.showsPageGuide = $0 },
            UserDefaults.standard.publisher(for: .showIndentGuides, initial: true)
                .sink { [weak self] in self?.showsIndentGuides = $0 },
        ]
    }
    
    
    override func viewDidDisappear() {
        
        super.viewDidDisappear()
        
        self.defaultsObservers.removeAll()
    }
    
    
    override static var restorableStateKeyPaths: [String] {
        
        super.restorableStateKeyPaths + [
            #keyPath(showsLineNumber),
            #keyPath(showsPageGuide),
            #keyPath(showsIndentGuides),
            #keyPath(showsInvisibles),
            #keyPath(wrapsLines),
            #keyPath(verticalLayoutOrientation),
            #keyPath(isAutoTabExpandEnabled),
            #keyPath(writingDirection),
        ]
    }
    
    
    override static func allowedClasses(forRestorableStateKeyPath keyPath: String) -> [AnyClass] {
        
        switch keyPath {
            case #keyPath(showsLineNumber),
                #keyPath(showsPageGuide),
                #keyPath(showsIndentGuides),
                #keyPath(showsInvisibles),
                #keyPath(wrapsLines),
                #keyPath(verticalLayoutOrientation),
                #keyPath(isAutoTabExpandEnabled),
                #keyPath(writingDirection):
                // -> Bool is also an NSNumber
                [NSNumber.self]
            default:
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
    
    func validateToolbarItem(_ item: NSToolbarItem) -> Bool {
        
        // manually pass toolbar items to `validateUserInterfaceItem(_:)`,
        // because they actually doesn't use it for validation (2020-08 on macOS 10.15)
        self.validateUserInterfaceItem(item)
    }
    
    
    override func validateUserInterfaceItem(_ item: any NSValidatedUserInterfaceItem) -> Bool {
        
        switch item.action {
            case #selector(toggleLineNumber):
                (item as? NSMenuItem)?.title = self.showsLineNumber
                    ? String(localized: "Hide Line Numbers", table: "MainMenu")
                    : String(localized: "Show Line Numbers", table: "MainMenu")
                
            case #selector(togglePageGuide):
                (item as? NSMenuItem)?.title = self.showsPageGuide
                    ? String(localized: "Hide Page Guide", table: "MainMenu")
                    : String(localized: "Show Page Guide", table: "MainMenu")
                (item as? StatableToolbarItem)?.state = self.showsPageGuide ? .on : .off
                
            case #selector(toggleIndentGuides):
                (item as? NSMenuItem)?.title = self.showsIndentGuides
                    ? String(localized: "Hide Indent Guides", table: "MainMenu")
                    : String(localized: "Show Indent Guides", table: "MainMenu")
                (item as? NSToolbarItem)?.toolTip = self.showsIndentGuides
                    ? String(localized: "Toolbar.indentGuides.tooltip.on",
                             defaultValue: "Hide indent guide lines", table: "Document")
                    : String(localized: "Toolbar.indentGuides.tooltip.off",
                             defaultValue: "Show indent guide lines", table: "Document")
                (item as? StatableToolbarItem)?.state = self.showsIndentGuides ? .on : .off
                
            case #selector(toggleLineWrap):
                (item as? NSMenuItem)?.title = self.wrapsLines
                    ? String(localized: "Unwrap Lines", table: "MainMenu")
                    : String(localized: "Wrap Lines", table: "MainMenu")
                (item as? NSToolbarItem)?.toolTip = self.wrapsLines
                    ? String(localized: "Toolbar.wrapLines.tooltip.on",
                             defaultValue: "Unwrap lines", table: "Document")
                    : String(localized: "Toolbar.wrapLines.tooltip.off",
                             defaultValue: "Wrap lines", table: "Document")
                (item as? StatableToolbarItem)?.state = self.wrapsLines ? .on : .off
                
            case #selector(toggleInvisibleChars):
                (item as? NSMenuItem)?.title = self.showsInvisibles
                    ? String(localized: "Hide Invisibles", table: "MainMenu")
                    : String(localized: "Show Invisibles", table: "MainMenu")
                (item as? StatableToolbarItem)?.state = self.showsInvisibles ? .on : .off
                
                // disable if item cannot be enabled
                let canActivateShowInvisibles = !UserDefaults.standard.showsInvisible.isEmpty
                item.toolTip = canActivateShowInvisibles
                    ? nil
                    : String(localized: "To show invisible characters, set them in the Window settings",
                             table: "MainMenu",
                             comment: "tooltip for the “Show Invisibles” menu item and toolbar item for when all invisible settings are disabled")
                if canActivateShowInvisibles {
                    (item as? NSToolbarItem)?.toolTip = self.showsInvisibles
                        ? String(localized: "Toolbar.invisibles.tooltip.on",
                                 defaultValue: "Hide invisible characters", table: "Document")
                        : String(localized: "Toolbar.invisibles.tooltip.off",
                                 defaultValue: "Show invisible characters", table: "Document")
                }
                return canActivateShowInvisibles
                
            case #selector(toggleAntialias):
                (item as? any StatableItem)?.state = (self.focusedTextView?.usesAntialias ?? false) ? .on : .off
                
            case #selector(toggleLigatures):
                (item as? any StatableItem)?.state = (self.focusedTextView?.ligature != NSTextView.LigatureMode.none) ? .on : .off
                
            case #selector(toggleAutoTabExpand):
                (item as? any StatableItem)?.state = self.isAutoTabExpandEnabled ? .on : .off
                (item as? NSToolbarItem)?.toolTip = self.isAutoTabExpandEnabled
                    ? String(localized: "Toolbar.tabStyle.tooltip.on",
                             defaultValue: "Use tabs for indentation", table: "Document")
                    : String(localized: "Toolbar.tabStyle.tooltip.off",
                             defaultValue: "Use spaces for indentation", table: "Document")
                
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
                return !self.view.isInFullScreenMode
                
            case #selector(changeTheme):
                if let item = item as? NSMenuItem {
                    item.state = (self.theme?.name == item.title) ? .on : .off
                }
                
            case #selector(toggleSplitOrientation):
                (item as? NSMenuItem)?.title = self.splitView.isVertical
                    ? String(localized: "Stack Editors Horizontally", table: "MainMenu")
                    : String(localized: "Stack Editors Vertically", table: "MainMenu")
                
            case #selector(closeSplitTextView):
                return self.splitViewItems.count > 1
                
            default: break
        }
        
        return super.validateUserInterfaceItem(item)
    }
    
    
    // MARK: Notifications
    
    /// Invoked when the text was edited (invoked right **before** notifying layout managers).
    override func textStorageDidProcessEditing(_ notification: Notification) {
        
        assert(Thread.isMainThread)
        
        let textStorage = notification.object as! NSTextStorage
        
        guard textStorage.editedMask.contains(.editedCharacters) else { return }
        
        MainActor.assumeIsolated {
            // tell the parser that text was changed
            self.document.syntaxParser.invalidateHighlight(in: textStorage.editedRange,
                                                           changeInLength: textStorage.changeInLength)
            
            guard self.focusedTextView?.hasMarkedText() != true else { return }
            
            self.document.counter.invalidateContent()
            self.outlineParseDebouncer.schedule()
            
            // -> Perform in the next run loop to give layoutManagers time to update their values.
            DispatchQueue.main.async { [weak self] in
                self?.document.syntaxParser.highlightIfNeeded()
            }
        }
    }
    
    
    /// Invoked when the selection did change.
    @objc private func textViewDidLiveChangeSelection(_ notification: Notification) {
        
        self.document.counter.invalidateSelection()
    }
    
    
    // MARK: Public Methods
    
    /// The text view currently focused on.
    var focusedTextView: EditorTextView? {
        
        self.focusedChild?.textView ?? self.editorViewControllers.first?.textView
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
    @objc dynamic var wrapsLines = true {
        
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
            self.focusedTextView?.tabWidth ?? UserDefaults.standard[.tabWidth]
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
            let textStorage = textView.textStorage,
            textStorage.length > 0
        else { return }
        
        textStorage.addAttributes(textView.typingAttributes, range: textStorage.range)
    }
    
    
    // MARK: Action Messages
    
    /// Recolors whole document.
    @IBAction func recolorAll(_ sender: Any?) {
        
        self.document.syntaxParser.highlightAll()
    }
    
    
    /// Sets new theme from a menu item.
    @IBAction func changeTheme(_ sender: NSMenuItem) {
        
        self.setTheme(name: sender.title)
    }
    
    
    /// Toggles the visibility of the line number views.
    @IBAction func toggleLineNumber(_ sender: Any?) {
        
        self.showsLineNumber.toggle()
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
        
        let opacityView = EditorOpacityView(window: self.view.window as? DocumentWindow)
        let viewController = NSHostingController(rootView: opacityView)
        
        if let toolbarItem = sender as? NSToolbarItem {
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
    
    
    /// Toggles divider orientation.
    @IBAction func toggleSplitOrientation(_ sender: Any?) {
        
        self.splitView.isVertical.toggle()
        self.splitState.isVertical = self.splitView.isVertical
        
        UserDefaults.standard[.splitViewVertical] = self.splitView.isVertical
    }
    
    
    /// Moves focus to the next text view.
    @IBAction func focusNextEditor(_ sender: Any?) {
        
        self.focusNextSplitEditor()
    }
    
    
    /// Moves focus to the previous text view.
    @IBAction func focusPreviousEditor(_ sender: Any?) {
        
        self.focusNextSplitEditor(reverse: true)
    }
    
    
    /// Splits editor view.
    @IBAction func openSplitTextView(_ sender: Any?) {
        
        guard self.splitViewItems.count < Self.maximumNumberOfSplitEditors else { return NSSound.beep() }
        
        guard let currentEditorViewController = self.baseEditorViewController(for: sender) else { return assertionFailure() }
        
        // end current editing
        NSTextInputContext.current?.discardMarkedText()
        
        let newEditorViewController = self.addEditorView(below: currentEditorViewController)
        
        // adjust visible areas
        if let selectedRange = currentEditorViewController.textView?.selectedRange {
            newEditorViewController.textView?.selectedRange = selectedRange
            currentEditorViewController.textView?.scrollRangeToVisible(selectedRange)
            newEditorViewController.textView?.scrollRangeToVisible(selectedRange)
        }
        
        self.splitState.canClose = true
        
        // move focus to the new editor
        self.view.window?.makeFirstResponder(newEditorViewController.textView)
    }
    
    
    /// Closes one of the split editors.
    @IBAction func closeSplitTextView(_ sender: Any?) {
        
        guard
            self.splitViewItems.count > 1,
            let currentEditorViewController = self.baseEditorViewController(for: sender)
        else { return }
        
        if let textView = currentEditorViewController.textView {
            NotificationCenter.default.removeObserver(self, name: EditorTextView.didLiveChangeSelectionNotification, object: textView)
        }
        
        // end current editing
        NSTextInputContext.current?.discardMarkedText()
        
        // move focus to the next text view if the view to close has a focus
        if self.focusedChild == currentEditorViewController {
            let children = self.editorViewControllers
            let deleteIndex = children.firstIndex(of: currentEditorViewController) ?? 0
            let newFocusEditorViewController = children[safe: deleteIndex - 1] ?? children.last!
            
            self.view.window?.makeFirstResponder(newFocusEditorViewController.textView)
        }
        
        // close
        currentEditorViewController.removeFromParent()
        
        self.splitState.canClose = self.splitViewItems.count > 1
    }
    
    
    // MARK: Private Methods
    
    /// The array of all child editor view controllers.
    private var editorViewControllers: [EditorViewController] {
        
        self.children.compactMap { $0 as? EditorViewController }
    }
    
    
    /// Creates a new split editor.
    ///
    /// - Parameter otherViewController: The view controller of the reference editor located above the editor to add.
    /// - Returns: The editor view controller created.
    @discardableResult
    private func addEditorView(below otherViewController: EditorViewController? = nil) -> sending EditorViewController {
        
        let viewController = EditorViewController(document: self.document, splitState: self.splitState)
        
        let splitViewItem = NSSplitViewItem(viewController: viewController)
        splitViewItem.minimumThickness = 100
        
        // add to the split view
        let index = otherViewController.flatMap(self.children.firstIndex(of:))?.advanced(by: 1) ?? 0
        self.insertSplitViewItem(splitViewItem, at: index)
        
        // observe cursor
        NotificationCenter.default.addObserver(self, selector: #selector(textViewDidLiveChangeSelection),
                                               name: EditorTextView.didLiveChangeSelectionNotification,
                                               object: viewController.textView)
        
        // setup textView
        let textView = viewController.textView!
        textView.isEditable = self.document.isEditable
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
            
            // copy parsed syntax highlight
            if let highlights = baseTextView.layoutManager?.syntaxHighlights(), !highlights.isEmpty {
                textView.layoutManager?.apply(highlights: highlights, theme: self.theme, in: textView.string.range)
            }
        }
        
        return viewController
    }
    
    
    /// Finds the base `EditorViewController` for split editor management actions.
    ///
    /// - Parameter sender: The action sender.
    /// - Returns: An editor view controller, or `nil` if not found.
    private func baseEditorViewController(for sender: Any?) -> EditorViewController? {
        
        if let view = sender as? NSView,
           let controller = self.editorViewControllers.first(where: { view.isDescendant(of: $0.view) })
        {
            controller
        } else {
            self.focusedChild
        }
    }
    
    
    /// Moves focus to the next/previous text view, or if not split, refocuses the current text view.
    ///
    /// - Parameter reverse: If `true`, move to the previous editor.
    private func focusNextSplitEditor(reverse: Bool = false) {
        
        let children = self.editorViewControllers
        
        guard let focusedChild = self.focusedChild,
              let focusIndex = children.firstIndex(of: focusedChild),
              let nextChild = reverse
                ? children[safe: focusIndex - 1] ?? children.last
                :children[safe: focusIndex + 1] ?? children.first
        else { return assertionFailure() }
        
        self.view.window?.makeFirstResponder(nextChild.textView)
    }
    
    
    /// Applies the given theme to child text views.
    ///
    /// - Parameter name: The name of the theme to apply.
    private func setTheme(name: String) {
        
        assert(Thread.isMainThread)
        
        let theme: Theme
        do {
            theme = try ThemeManager.shared.setting(name: name)
        } catch {
            return self.presentErrorAsSheet(error)
        }
        
        self.document.syntaxParser.theme = theme
        
        for textView in self.editorViewControllers.compactMap(\.textView) {
            textView.theme = theme
            textView.layoutManager?.invalidateHighlight(theme: theme)
        }
        
        self.invalidateRestorableState()
    }
}
