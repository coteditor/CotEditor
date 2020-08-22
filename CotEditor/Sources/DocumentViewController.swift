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

private let maximumNumberOfSplitEditors = 8


final class DocumentViewController: NSSplitViewController, ThemeHolder, NSTextStorageDelegate, NSToolbarItemValidation {
    
    // MARK: Private Properties
    
    private var documentStyleObserver: AnyCancellable?
    private var outlineSubscriptions: Set<AnyCancellable> = []
    private var appearanceObserver: AnyCancellable?
    private var defaultsObservers: [UserDefaultsObservation] = []
    private var opacityObserver: UserDefaultsObservation?
    private var sheetAvailabilityObservers: Set<AnyCancellable> = []
    private var themeChangeObserver: AnyCancellable?
    
    private lazy var outlineParseTask = Debouncer(delay: .seconds(0.4)) { [weak self] in self?.syntaxParser?.invalidateOutline() }
    private weak var syntaxHighlightProgress: Progress?
    
    @IBOutlet private weak var splitViewItem: NSSplitViewItem?
    @IBOutlet private weak var statusBarItem: NSSplitViewItem?
    
    
    
    // MARK: -
    // MARK: Split View Controller Methods
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // set user defaults
        let defaults = UserDefaults.standard
        self.isStatusBarShown = defaults[.showStatusBar]
        self.showsInvisibles = defaults[.showInvisibles]
        self.showsLineNumber = defaults[.showLineNumbers]
        self.showsNavigationBar = defaults[.showNavigationBar]
        self.wrapsLines = defaults[.wrapLines]
        self.showsPageGuide = defaults[.showPageGuide]
        self.showsIndentGuides = defaults[.showIndentGuides]
        
        // set writing direction
        switch defaults[.writingDirection] {
            case .leftToRight:
                break
            case .rightToLeft:
                self.writingDirection = .rightToLeft
            case .vertical:
                self.verticalLayoutOrientation = true
        }
        
        // set theme
        let themeName = ThemeManager.shared.userDefaultSettingName
        self.setTheme(name: themeName)
        
        // observe theme change
        self.themeChangeObserver = ThemeManager.shared.didUpdateSetting
            .filter { [weak self] in $0.old == self?.theme?.name }
            .compactMap { $0.new }
            .sink { [weak self] in self?.setTheme(name: $0) }
        
        // observe cursor
        NotificationCenter.default.addObserver(self, selector: #selector(textViewDidChangeSelection),
                                               name: NSTextView.didChangeSelectionNotification,
                                               object: self.editorViewControllers.first!.textView!)
        
        // observe defaults change
        self.defaultsObservers = [
            UserDefaults.standard.observe(key: .theme) { [weak self] _ in
                let themeName = ThemeManager.shared.userDefaultSettingName
                self?.setTheme(name: themeName)
            },
            UserDefaults.standard.observe(key: .showInvisibles) { [weak self] (value) in
                self?.showsInvisibles = value!
            },
            UserDefaults.standard.observe(key: .showLineNumbers) { [weak self] (value) in
                self?.showsLineNumber = value!
            },
            UserDefaults.standard.observe(key: .showPageGuide) { [weak self] (value) in
                self?.showsPageGuide = value!
            },
            UserDefaults.standard.observe(key: .showIndentGuides) { [weak self] (value) in
                self?.showsIndentGuides = value!
            },
            UserDefaults.standard.observe(key: .wrapLines) { [weak self] (value) in
                self?.wrapsLines = value!
            },
        ]
        
        // observe appearance change for theme toggle
        self.appearanceObserver = self.view.publisher(for: \.effectiveAppearance)
            .sink { [weak self] (appearance) in
                guard
                    let self = self,
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
        
        // observe opacity setting change
        self.opacityObserver = UserDefaults.standard.observe(key: .windowAlpha, initial: true) { [weak self] value in
            guard let window = self?.view.window as? DocumentWindow else { return assertionFailure() }
            window.backgroundAlpha = value!
        }
    }
    
    
    /// keys to be restored from the last session
    override class var restorableStateKeyPaths: [String] {
        
        return super.restorableStateKeyPaths + [
            #keyPath(showsLineNumber),
            #keyPath(showsPageGuide),
            #keyPath(showsIndentGuides),
            #keyPath(showsInvisibles),
            #keyPath(wrapsLines),
            #keyPath(verticalLayoutOrientation),
            #keyPath(writingDirection),
            #keyPath(isAutoTabExpandEnabled),
        ]
    }
    
    
    /// store UI state
    override func encodeRestorableState(with coder: NSCoder) {
        
        if let themeName = self.theme?.name {
            coder.encode(themeName, forKey: "theme")
        }
        
        // manunally encode `restorableStateKeyPaths` since it doesn't work (macOS 10.14)
        for keyPath in Self.restorableStateKeyPaths {
            coder.encode(self.value(forKeyPath: keyPath), forKey: keyPath)
        }
        
        super.encodeRestorableState(with: coder)
    }
    
    
    /// restore UI state
    override func restoreState(with coder: NSCoder) {
        
        super.restoreState(with: coder)
        
        if let storedThemeName = coder.decodeObject(forKey: "theme") as? String {
            let themeName = UserDefaults.standard[.pinsThemeAppearance]
                ? storedThemeName
                : ThemeManager.shared.equivalentSettingName(to: storedThemeName, forDark: self.view.effectiveAppearance.isDark) ?? storedThemeName
            
            self.setTheme(name: themeName)
        }
        
        // manunally decode `restorableStateKeyPaths` since it doesn't work (macOS 10.14)
        for keyPath in Self.restorableStateKeyPaths where coder.containsValue(forKey: keyPath) {
            self.setValue(coder.decodeObject(forKey: keyPath), forKeyPath: keyPath)
        }
    }
    
    
    /// deliver document to child view controllers
    override var representedObject: Any? {
        
        willSet {
            self.documentStyleObserver = nil
            self.outlineSubscriptions.removeAll()
        }
        
        didSet {
            guard let document = representedObject as? Document else { return }
            
            // This setter can be invoked twice if the view was initially made for a transient document.
            
            (self.statusBarItem?.viewController as? StatusBarController)?.document = document
            
            document.textStorage.delegate = self
            
            let editorViewController = self.editorViewControllers.first!
            self.setup(editorViewController: editorViewController, baseViewController: nil)
            
            // start parcing syntax for highlighting and outline menu
            self.outlineParseTask.perform()
            self.invalidateSyntaxHighlight()
            
            // detect indent style
            if UserDefaults.standard[.detectsIndentStyle],
                let indentStyle = document.textStorage.string.detectedIndentStyle
            {
                self.isAutoTabExpandEnabled = {
                    switch indentStyle {
                        case .tab:
                            return false
                        case .space:
                            return true
                    }
                }()
            }
            
            // focus text view
            self.view.window?.makeFirstResponder(editorViewController.textView)
            
            // observe syntax change
            self.documentStyleObserver = document.didChangeSyntaxStyle
                .receive(on: RunLoop.main)
                .sink { [weak self] _ in self?.didChangeSyntaxStyle() }
            
            // observe syntaxParser for outline update
            document.syntaxParser.$outlineItems
                .debounce(for: 0.1, scheduler: RunLoop.main)
                .removeDuplicates()
                .sink { [weak self] (outlineItems) in
                    self?.editorViewControllers.forEach { $0.outlineItems = outlineItems }
                }
                .store(in: &self.outlineSubscriptions)
        }
    }
    
    
    /// avoid showing draggable cursor
    override func splitView(_ splitView: NSSplitView, effectiveRect proposedEffectiveRect: NSRect, forDrawnRect drawnRect: NSRect, ofDividerAt dividerIndex: Int) -> NSRect {
        
        // -> Super's delegate method must be called anyway.
        super.splitView(splitView, effectiveRect: proposedEffectiveRect, forDrawnRect: drawnRect, ofDividerAt: dividerIndex)
        
        return .zero
    }
    
    
    /// apply current state to related toolbar items
    func validateToolbarItem(_ item: NSToolbarItem) -> Bool {
        
        // manually pass toolbar items to `validateUserInterfaceItem(_:)`,
        // because they actually doesn't use it for validation (2020-08 on macOS 10.15)
        return self.validateUserInterfaceItem(item)
    }
    
    
    /// apply current state to related UI items
    override func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        
        switch item.action {
            case #selector(recolorAll):
                return self.syntaxParser?.canParse ?? false
            
            case #selector(changeTheme):
                if let item = item as? NSMenuItem {
                    item.state = (self.theme?.name == item.title) ? .on : .off
                }
            
            case #selector(toggleNavigationBar):
                (item as? NSMenuItem)?.title = self.showsNavigationBar
                    ? "Hide Navigation Bar".localized
                    : "Show Navigation Bar".localized
            
            case #selector(toggleLineNumber):
                (item as? NSMenuItem)?.title = self.showsLineNumber
                    ? "Hide Line Numbers".localized
                    : "Show Line Numbers".localized
            
            case #selector(toggleStatusBar):
                (item as? NSMenuItem)?.title = self.isStatusBarShown
                    ? "Hide Status Bar".localized
                    : "Show Status Bar".localized
            
            case #selector(togglePageGuide):
                (item as? NSMenuItem)?.title = self.showsPageGuide
                    ? "Hide Page Guide".localized
                    : "Show Page Guide".localized
                (item as? StatableToolbarItem)?.state = self.showsPageGuide ? .on : .off
            
            case #selector(toggleIndentGuides):
                (item as? NSMenuItem)?.title = self.showsIndentGuides
                    ? "Hide Indent Guides".localized
                    : "Show Indent Guides".localized
                (item as? StatableToolbarItem)?.state = self.showsIndentGuides ? .on : .off
            
            case #selector(toggleLineWrap):
                (item as? NSMenuItem)?.title = self.wrapsLines
                    ? "Unwrap Lines".localized
                    : "Wrap Lines".localized
                (item as? StatableToolbarItem)?.state = self.wrapsLines ? .on : .off
            
            case #selector(toggleInvisibleChars):
                (item as? NSMenuItem)?.title = self.showsInvisibles
                    ? "Hide Invisibles".localized
                    : "Show Invisibles".localized
                (item as? StatableToolbarItem)?.state = self.showsInvisibles ? .on : .off
                
                // disable if item cannot be enabled
                let canActivateShowInvisibles = !UserDefaults.standard.showsInvisible.isEmpty
                item.toolTip = canActivateShowInvisibles
                    ? "Show or hide invisible characters in document".localized
                    : "To show invisible characters, set them in Preferences".localized
                return canActivateShowInvisibles
            
            case #selector(toggleAntialias):
                (item as? StatableItem)?.state = (self.focusedTextView?.usesAntialias ?? false) ? .on : .off
            
            case #selector(toggleLigatures):
                (item as? StatableItem)?.state = (self.focusedTextView?.ligature != NSTextView.LigatureMode.none) ? .on : .off
            
            case #selector(toggleAutoTabExpand):
                (item as? StatableItem)?.state = self.isAutoTabExpandEnabled ? .on : .off
            
            case #selector(changeTabWidth):
                (item as? StatableItem)?.state = (self.tabWidth == item.tag) ? .on : .off
            
            case #selector(makeLayoutOrientationHorizontal):
                (item as? StatableItem)?.state = self.verticalLayoutOrientation ? .off : .on
            
            case #selector(makeLayoutOrientationVertical):
                (item as? StatableItem)?.state = self.verticalLayoutOrientation ? .on : .off
            
            case #selector(makeWritingDirectionLeftToRight):
                (item as? StatableItem)?.state = (self.writingDirection == .leftToRight) ? .on : .off
            
            case #selector(makeWritingDirectionRightToLeft):
                (item as? StatableItem)?.state = (self.writingDirection == .rightToLeft) ? .on : .off
            
            case #selector(changeWritingDirection):
                (item as? NSToolbarItemGroup)?.selectedIndex = {
                    switch self.writingDirection {
                        case _ where self.verticalLayoutOrientation: return -1
                        case .rightToLeft: return 1
                        default: return 0
                    }
                }()
            
            case #selector(changeOrientation):
                (item as? NSToolbarItemGroup)?.selectedIndex = self.verticalLayoutOrientation ? 1 : 0
                
            case #selector(showOpacitySlider):
                return self.view.window?.styleMask.contains(.fullScreen) == false
            
            case #selector(closeSplitTextView):
                return (self.splitViewController?.splitViewItems.count ?? 0) > 1
            
            default: break
        }
        
        return super.validateUserInterfaceItem(item)
    }
    
    
    
    // MARK: Delegate
    
    /// text was edited (invoked right **before** notifying layout managers)
    func textStorage(_ textStorage: NSTextStorage, didProcessEditing editedMask: NSTextStorageEditActions, range editedRange: NSRange, changeInLength delta: Int) {
        
        guard
            editedMask.contains(.editedCharacters),
            self.focusedTextView?.hasMarkedText() != true
            else { return }
        
        self.document?.analyzer.invalidateEditorInfo()
        self.document?.incompatibleCharacterScanner.invalidate()
        self.outlineParseTask.schedule()
        
        // -> Perform in the next run loop to give layoutManagers time to update their values.
        DispatchQueue.main.async { [weak self] in
            self?.invalidateSyntaxHighlight(in: editedRange)
        }
    }
    
    
    
    // MARK: Notifications
    
    /// selection did change
    @objc private func textViewDidChangeSelection(_ notification: Notification) {
        
        // update document information
        self.document?.analyzer.invalidateEditorInfo(onlySelection: true)
    }
    
    
    /// document updated syntax style
    private func didChangeSyntaxStyle() {
        
        guard let syntaxParser = self.syntaxParser else { return assertionFailure() }
        
        for viewController in self.editorViewControllers {
            viewController.apply(style: syntaxParser.style)
        }
        
        self.outlineParseTask.perform()
        self.invalidateSyntaxHighlight()
    }
    
    
    
    // MARK: Public Methods
    
    /// setup document
    var document: Document? {
        
        return self.representedObject as? Document
    }
    
    
    /// return textView focused on
    var focusedTextView: EditorTextView? {
        
        return self.splitViewController?.focusedChild?.textView
    }
    
    
    /// coloring theme
    var theme: Theme? {
        
        return self.focusedTextView?.theme
    }
    
    
    /// body font
    var font: NSFont? {
        
        return self.focusedTextView?.font
    }
    
    
    /// Whether status bar is visible
    var isStatusBarShown: Bool {
        
        get {
            return self.statusBarItem?.isCollapsed == false
        }
        
        set {
            assert(self.statusBarItem != nil)
            self.statusBarItem?.isCollapsed = !newValue
        }
    }
    
    
    /// visibility of navigation bars
    var showsNavigationBar = false {
        
        didSet {
            for viewController in self.editorViewControllers {
                viewController.showsNavigationBar = showsNavigationBar
            }
        }
    }
    
    
    /// visibility of line numbers view
    @objc var showsLineNumber = false {
        
        didSet {
            for viewController in self.editorViewControllers {
                viewController.showsLineNumber = showsLineNumber
            }
        }
    }
    
    
    /// if lines soft-wrap at window edge
    @objc var wrapsLines = false {
        
        didSet {
            for viewController in self.editorViewControllers {
                viewController.textView?.wrapsLines = wrapsLines
            }
        }
    }
    
    
    /// visibility of page guide lines in text view
    @objc var showsPageGuide = false {
        
        didSet {
            for viewController in self.editorViewControllers {
                viewController.textView?.showsPageGuide = showsPageGuide
            }
        }
    }
    
    
    /// visibility of indent guides in text view
    @objc var showsIndentGuides = false {
        
        didSet {
            for viewController in self.editorViewControllers {
                viewController.textView?.showsIndentGuides = showsIndentGuides
            }
        }
    }
    
    
    /// visibility of invisible characters
    @objc var showsInvisibles = false {
        
        didSet {
            for viewController in self.editorViewControllers {
                viewController.textView?.showsInvisibles = showsInvisibles
            }
        }
    }
    
    
    /// if text orientation is vertical
    @objc var verticalLayoutOrientation: Bool {
        
        get {
            guard let textView = self.focusedTextView else {
                return UserDefaults.standard[.writingDirection] == .vertical
            }
            
            return textView.layoutOrientation == .vertical
        }
        
        set {
            self.document?.isVerticalText = newValue
            
            let orientation: NSLayoutManager.TextLayoutOrientation = newValue ? .vertical : .horizontal
            
            for viewController in self.editorViewControllers {
                viewController.textView?.setLayoutOrientation(orientation)
            }
        }
    }
    
    
    @objc var writingDirection: NSWritingDirection {
        
        get {
            return self.focusedTextView?.baseWritingDirection ?? .leftToRight
        }
        
        set {
            for viewController in self.editorViewControllers {
                viewController.textView?.baseWritingDirection = newValue
            }
        }
    }
    
    
    /// textView's tab width
    var tabWidth: Int {
        
        get {
            return self.focusedTextView?.tabWidth ?? 0
        }
        
        set {
            for viewController in self.editorViewControllers {
                viewController.textView?.tabWidth = newValue
            }
        }
    }
    
    
    /// whether replace tab with spaces
    @objc var isAutoTabExpandEnabled: Bool {
        
        get {
            return self.focusedTextView?.isAutomaticTabExpansionEnabled ?? UserDefaults.standard[.autoExpandTab]
        }
        
        set {
            for viewController in self.editorViewControllers {
                viewController.textView?.isAutomaticTabExpansionEnabled = newValue
            }
        }
    }
    
    
    /// apply text styles from text view
    func invalidateStyleInTextStorage() {
        
        self.focusedTextView?.invalidateStyle()
    }
    
    
    
    // MARK: Action Messages
    
    /// re-color whole document
    @IBAction func recolorAll(_ sender: Any?) {
        
        self.invalidateSyntaxHighlight()
    }
    
    
    /// set new theme from menu item
    @IBAction func changeTheme(_ sender: AnyObject?) {
        
        guard let name = sender?.title else { return assertionFailure() }
        
        self.setTheme(name: name)
    }
    
    
    /// toggle visibility of navigation bar with fancy animation
    @IBAction func toggleNavigationBar(_ sender: Any?) {
        
        NSAnimationContext.current.withAnimation {
            self.showsNavigationBar.toggle()
        }
        
        UserDefaults.standard[.showNavigationBar] = self.showsNavigationBar
    }
    
    
    /// toggle visibility of line number view
    @IBAction func toggleLineNumber(_ sender: Any?) {
        
        self.showsLineNumber.toggle()
    }
    
    
    /// toggle visibility of status bar with fancy animation
    @IBAction func toggleStatusBar(_ sender: Any?) {
        
        NSAnimationContext.current.withAnimation {
            self.isStatusBarShown.toggle()
        }
        
        UserDefaults.standard[.showStatusBar] = self.isStatusBarShown
    }
    
    
    /// toggle visibility of page guide line in text view
    @IBAction func togglePageGuide(_ sender: Any?) {
        
        self.showsPageGuide.toggle()
    }
    
    
    /// toggle if shows indent guides in text view
    @IBAction func toggleIndentGuides(_ sender: Any?) {
        
        self.showsIndentGuides.toggle()
    }
    
    
    /// toggle if lines wrap at window edge
    @IBAction func toggleLineWrap(_ sender: Any?) {
        
        self.wrapsLines.toggle()
    }
    
    
    /// toggle visibility of invisible characters in text view
    @IBAction func toggleInvisibleChars(_ sender: Any?) {
        
        self.showsInvisibles.toggle()
    }
    
    
    /// toggle if antialias text in text view
    @IBAction func toggleAntialias(_ sender: Any?) {
        
        for viewController in self.editorViewControllers {
            viewController.textView?.usesAntialias.toggle()
        }
    }
    
    
    /// toggle ligature mode in text view
    @IBAction func toggleLigatures(_ sender: Any?) {
        
        for viewController in self.editorViewControllers {
            guard let textView = viewController.textView else { continue }
            
            textView.ligature = (textView.ligature == .none) ? .standard : .none
        }
    }
    
    
    /// toggle if text view expands tab input
    @IBAction func toggleAutoTabExpand(_ sender: Any?) {
        
        self.isAutoTabExpandEnabled.toggle()
    }
    
    
    /// change tab width from the main menu
    @IBAction func changeTabWidth(_ sender: NSMenuItem) {
        
        self.tabWidth = sender.tag
    }
    
    
    /// change tab width to desired number through a sheet
    @IBAction func customizeTabWidth(_ sender: Any?) {
        
        let viewController = CustomTabWidthViewController.instantiate(storyboard: "CustomTabWidthView")
        viewController.defaultWidth = self.tabWidth
        viewController.completionHandler = { [weak self] (tabWidth) in
            self?.tabWidth = tabWidth
        }
        
        self.presentAsSheet(viewController)
    }
    
    
    /// make text layout orientation horizontal
    @IBAction func makeLayoutOrientationHorizontal(_ sender: Any?) {
        
        self.verticalLayoutOrientation = false
    }
    
    
    /// make text layout orientation vertical
    @IBAction func makeLayoutOrientationVertical(_ sender: Any?) {
        
        self.verticalLayoutOrientation = true
    }
    
    
    /// make entire writing direction LTR
    @IBAction func makeWritingDirectionLeftToRight(_ sender: Any?) {
        
        self.writingDirection = .leftToRight
    }
    
    
    /// make entire writing direction RTL
    @IBAction func makeWritingDirectionRightToLeft(_ sender: Any?) {
        
        self.writingDirection = .rightToLeft
    }
    
    
    /// change writing direction by a grouped toolbar item
    @IBAction func changeWritingDirection(_ sender: NSToolbarItemGroup) {
        
        assertionFailure("This is a dummy action designed to be used just for the segmentation selection validation.")
    }
    
    
    /// change layout orientation by a grouped toolbar item
    @IBAction func changeOrientation(_ sender: NSToolbarItemGroup) {
        
        assertionFailure("This is a dummy action designed to be used just for the segmentation selection validation.")
    }
    
    
    /// show editor opacity slider as popover
    @IBAction func showOpacitySlider(_ sender: Any?) {
        
        guard let viewController = self.storyboard?.instantiateController(withIdentifier: "Opacity Slider") as? NSViewController else { return assertionFailure() }
        
        viewController.representedObject = self.view.window
        
        self.present(viewController, asPopoverRelativeTo: .zero, of: sender as? NSView ?? self.view,
                     preferredEdge: .maxY, behavior: .transient)
    }
    
    
    /// split editor view
    @IBAction func openSplitTextView(_ sender: Any?) {
        
        guard
            let splitViewController = self.splitViewController,
            let currentEditorViewController = self.baseEditorViewController(for: sender)
            else { return assertionFailure() }
        
        guard splitViewController.splitViewItems.count < maximumNumberOfSplitEditors else { return NSSound.beep() }
        
        // end current editing
        NSTextInputContext.current?.discardMarkedText()
        
        let newEditorViewController = EditorViewController.instantiate(storyboard: "EditorView")
        splitViewController.addChild(newEditorViewController, relativeTo: currentEditorViewController)
        self.setup(editorViewController: newEditorViewController, baseViewController: currentEditorViewController)
        
        newEditorViewController.outlineItems = self.syntaxParser?.outlineItems ?? []
        self.invalidateSyntaxHighlight()
        
        // adjust visible areas
        newEditorViewController.textView?.selectedRange = currentEditorViewController.textView!.selectedRange
        currentEditorViewController.textView?.centerSelectionInVisibleArea(self)
        newEditorViewController.textView?.centerSelectionInVisibleArea(self)
        
        // observe cursor
        NotificationCenter.default.addObserver(self, selector: #selector(textViewDidChangeSelection),
                                               name: NSTextView.didChangeSelectionNotification,
                                               object: newEditorViewController.textView)
        
        // move focus to the new editor
        self.view.window?.makeFirstResponder(newEditorViewController.textView)
    }
    
    
    /// close one of split views
    @IBAction func closeSplitTextView(_ sender: Any?) {
        
        assert(self.splitViewController!.splitViewItems.count > 1)
        
        guard
            let splitViewController = self.splitViewController,
            let currentEditorViewController = self.baseEditorViewController(for: sender),
            let splitViewItem = splitViewController.splitViewItem(for: currentEditorViewController)
            else { return }
        
        if let textView = currentEditorViewController.textView {
            NotificationCenter.default.removeObserver(self, name: NSTextView.didChangeSelectionNotification, object: textView)
        }
        
        // end current editing
        NSTextInputContext.current?.discardMarkedText()
        
        // move focus to the next text view if the view to close has a focus
        if splitViewController.focusedChild == currentEditorViewController {
            let children = self.editorViewControllers
            let deleteIndex = children.firstIndex(of: currentEditorViewController) ?? 0
            let newFocusEditorViewController = children[safe: deleteIndex - 1] ?? children.last!
            
            self.view.window?.makeFirstResponder(newFocusEditorViewController.textView)
        }
        
        // close
        splitViewController.removeSplitViewItem(splitViewItem)
    }
    
    
    
    // MARK: Private Methods
    
    /// Invalidate the current syntax highlight.
    ///
    /// - Parameter range: The character range to invalidate syntax highlight, or `nil` when entire text is needed to re-highlight.
    private func invalidateSyntaxHighlight(in range: NSRange? = nil) {
        
        var range = range
        
        // retry entire syntax highlight if the last highlightAll has not finished yet
        if let progress = self.syntaxHighlightProgress, !progress.isFinished, !progress.isCancelled {
            progress.cancel()
            self.syntaxHighlightProgress = nil
            range = nil
        }
        
        guard let parser = self.syntaxParser else { return }
        
        // start parse
        let progress = parser.highlight(around: range)
        
        // show indicator for a large update
        let threshold = UserDefaults.standard[.showColoringIndicatorTextLength]
        let highlightLength = range?.length ?? self.textStorage?.length ?? 0
        guard threshold > 0, highlightLength > threshold else { return }
        
        self.syntaxHighlightProgress = progress
        if let progress = progress {
            self.presentHighlightIndicator(progress: progress)
        }
    }
    
    
    /// Show syntax highlight progress as sheet.
    ///
    /// - Parameter progress: The highlight progress
    private func presentHighlightIndicator(progress: Progress) {
        
        guard let window = self.view.window else {
            return assertionFailure("Expected window to be non-nil.")
        }
        
        self.sheetAvailabilityObservers.removeAll()
        
        // display indicator first when window is visible
        let presentBlock = { [weak self, weak progress] in
            guard
                let self = self,
                let progress = progress,
                !progress.isFinished, !progress.isCancelled
                else { return }
            
            let message = "Coloring text…".localized
            let indicator = NSStoryboard(name: "CompactProgressView").instantiateInitialController { (coder) in
                ProgressViewController(coder: coder, progress: progress, message: message)
            }!
            
            self.presentAsSheet(indicator)
        }
        
        if window.occlusionState.contains(.visible), window.attachedSheet == nil {
            presentBlock()
            
        } else {
            [NSWindow.didChangeOcclusionStateNotification,
             NSWindow.didEndSheetNotification]
                .forEach { notificationName in
                    NotificationCenter.default.publisher(for: notificationName, object: window)
                        .map { $0.object as! NSWindow }
                        .filter { $0.occlusionState.contains(.visible) && $0.attachedSheet == nil }
                        .sink { [weak self] _ in
                            self?.sheetAvailabilityObservers.removeAll()
                            presentBlock()
                        }
                        .store(in: &self.sheetAvailabilityObservers)
                }
        }
    }
    
    
    /// create and set-up new (split) editor view
    private func setup(editorViewController: EditorViewController, baseViewController: EditorViewController?) {
        
        editorViewController.setTextStorage(self.textStorage!)
        
        editorViewController.textView?.wrapsLines = self.wrapsLines
        editorViewController.textView?.showsInvisibles = self.showsInvisibles
        editorViewController.textView?.setLayoutOrientation(self.verticalLayoutOrientation ? .vertical : .horizontal)
        editorViewController.textView?.showsPageGuide = self.showsPageGuide
        editorViewController.textView?.showsIndentGuides = self.showsIndentGuides
        editorViewController.showsNavigationBar = self.showsNavigationBar
        editorViewController.showsLineNumber = self.showsLineNumber  // need to be set after setting text orientation
        
        if let syntaxParser = self.syntaxParser {
            editorViewController.apply(style: syntaxParser.style)
        }
        
        // copy textView states
        if let baseTextView = baseViewController?.textView, let textView = editorViewController.textView {
            textView.font = baseTextView.font
            textView.theme = baseTextView.theme
            textView.tabWidth = baseTextView.tabWidth
            textView.baseWritingDirection = baseTextView.baseWritingDirection
            textView.isAutomaticTabExpansionEnabled = baseTextView.isAutomaticTabExpansionEnabled
        }
    }
    
    
    /// split view controller
    private var splitViewController: SplitViewController? {
        
        return self.splitViewItem?.viewController as? SplitViewController
    }
    
    
    /// text storage
    private var textStorage: NSTextStorage? {
        
        return self.document?.textStorage
    }
    
    
    /// document's syntax parser
    private var syntaxParser: SyntaxParser? {
        
        return self.document?.syntaxParser
    }
    
    
    /// child editor view controllers
    private var editorViewControllers: [EditorViewController] {
        
        return self.splitViewController?.children.compactMap { $0 as? EditorViewController } ?? []
    }
    
    
    /// apply theme
    private func setTheme(name: String) {
        
        assert(Thread.isMainThread)
        
        guard let theme = ThemeManager.shared.setting(name: name) else { return }
        
        for viewController in self.editorViewControllers {
            viewController.textView?.theme = theme
            viewController.textView?.layoutManager?.invalidateHighlight(theme: theme)
        }
        
        self.invalidateRestorableState()
    }
    
    
    /// Find the base `EditorViewController` for split editor management actions.
    ///
    /// - Parameter sender: The action sender.
    /// - Returns: An editor view controller, or `nil` if not found.
    private func baseEditorViewController(for sender: Any?) -> EditorViewController? {
        
        if let view = sender as? NSView,
           let controller = self.splitViewController?.children
            .first(where: { view.isDescendant(of: $0.view) }) as? EditorViewController
        {
            return controller
        }
        
        return self.splitViewController?.focusedChild
    }
    
}



// MARK: Protocol

extension DocumentViewController: TextFinderClientProvider {
    
    /// Tell text finder in which text view the text find should perform.
    func textFinderClient() -> NSTextView? {
        
        return self.focusedTextView
    }
}
