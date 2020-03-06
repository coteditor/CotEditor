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

import Cocoa

private let maximumNumberOfSplitEditors = 8


final class DocumentViewController: NSSplitViewController, SyntaxParserDelegate, ThemeHolder, NSTextStorageDelegate {
    
    // MARK: Private Properties
    
    private var appearanceObserver: NSKeyValueObservation?
    private var defaultsObservers: [UserDefaultsObservation] = []
    private weak var syntaxHighlightProgress: Progress?
    
    @IBOutlet private weak var splitViewItem: NSSplitViewItem?
    @IBOutlet private weak var statusBarItem: NSSplitViewItem?
    
    
    
    // MARK: -
    // MARK: Split View Controller Methods
    
    deinit {
        self.appearanceObserver?.invalidate()
        self.defaultsObservers.forEach { $0.invalidate() }
    }
    
    
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
        NotificationCenter.default.addObserver(self, selector: #selector(didUpdateTheme),
                                               name: didUpdateSettingNotification,
                                               object: ThemeManager.shared)
        
        // observe cursor
        NotificationCenter.default.addObserver(self, selector: #selector(textViewDidChangeSelection),
                                               name: NSTextView.didChangeSelectionNotification,
                                               object: self.editorViewControllers.first!.textView!)
        
        // observe defaults change
        self.defaultsObservers.forEach { $0.invalidate() }
        self.defaultsObservers = [
            UserDefaults.standard.observe(key: .theme) { [weak self] _ in
                let themeName = ThemeManager.shared.userDefaultSettingName
                self?.setTheme(name: themeName)
            },
            UserDefaults.standard.observe(key: .showInvisibles, options: [.new]) { [weak self] change in
                self?.showsInvisibles = change.new!
            },
            UserDefaults.standard.observe(key: .showLineNumbers, options: [.new]) { [weak self] change in
                self?.showsLineNumber = change.new!
            },
            UserDefaults.standard.observe(key: .showPageGuide, options: [.new]) { [weak self] change in
                self?.showsPageGuide = change.new!
            },
            UserDefaults.standard.observe(key: .wrapLines, options: [.new]) { [weak self] change in
                self?.wrapsLines = change.new!
            },
        ]
        
        // observe appearance change for theme toggle
        self.appearanceObserver?.invalidate()
        self.appearanceObserver = self.view.observe(\.effectiveAppearance) { [weak self] (view, _) in
            guard
                let self = self,
                !UserDefaults.standard[.pinsThemeAppearance],
                view.window != nil,
                let currentThemeName = self.theme?.name,
                let themeName = ThemeManager.shared.equivalentSettingName(to: currentThemeName, forDark: view.effectiveAppearance.isDark),
                currentThemeName != themeName
                else { return }
            
            self.setTheme(name: themeName)
        }
    }
    
    
    /// keys to be restored from the last session
    override class var restorableStateKeyPaths: [String] {
        
        return super.restorableStateKeyPaths + [
            #keyPath(showsLineNumber),
            #keyPath(showsPageGuide),
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
            guard let document = representedObject as? Document else { return }
            
            NotificationCenter.default.removeObserver(self, name: Document.didChangeSyntaxStyleNotification, object: document)
        }
        
        didSet {
            guard let document = representedObject as? Document else { return }
            
            // This setter can be invoked twice if the view was initially made for a transient document.
            
            (self.statusBarItem?.viewController as? StatusBarController)?.documentAnalyzer = document.analyzer
            
            document.textStorage.delegate = self
            document.syntaxParser.delegate = self
            
            let editorViewController = self.editorViewControllers.first!
            self.setup(editorViewController: editorViewController, baseViewController: nil)
            
            // start parcing syntax highlights and outline menu
            document.syntaxParser.invalidateOutline()
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
            NotificationCenter.default.addObserver(self, selector: #selector(didChangeSyntaxStyle),
                                                   name: Document.didChangeSyntaxStyleNotification,
                                                   object: document)
        }
    }
    
    
    /// avoid showing draggable cursor
    override func splitView(_ splitView: NSSplitView, effectiveRect proposedEffectiveRect: NSRect, forDrawnRect drawnRect: NSRect, ofDividerAt dividerIndex: Int) -> NSRect {
        
        // -> must call super's delegate method anyway.
        super.splitView(splitView, effectiveRect: proposedEffectiveRect, forDrawnRect: drawnRect, ofDividerAt: dividerIndex)
        
        return .zero
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
            
            case #selector(toggleLineWrap):
                (item as? NSMenuItem)?.title = self.wrapsLines
                    ? "Unwrap Lines".localized
                    : "Wrap Lines".localized
                (item as? StatableToolbarItem)?.state = self.wrapsLines ? .on : .off
            
            case #selector(toggleInvisibleChars):
                (item as? NSMenuItem)?.title = self.showsInvisibles
                    ? "Hide Invisible Characters".localized
                    : "Show Invisible Characters".localized
                (item as? StatableToolbarItem)?.state = self.showsInvisibles ? .on : .off
                
                // disable if item cannot be enabled
                item.toolTip = self.canActivateShowInvisibles
                    ? "Show or hide invisible characters in document".localized
                    : "To show invisible characters, set them in Preferences".localized
                return self.canActivateShowInvisibles
            
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
                return !self.verticalLayoutOrientation
            
            case #selector(changeWritingDirection):
                let tag: Int = {
                    switch (self.verticalLayoutOrientation, self.writingDirection) {
                        case (true, _): return 2
                        case (false, .rightToLeft): return 1
                        default: return 0
                    }
                }()
                (item as? SegmentedToolbarItem)?.segmentedControl?.selectSegment(withTag: tag)
            
            case #selector(changeOrientation):
                let tag = self.verticalLayoutOrientation ? 1 : 0
                (item as? SegmentedToolbarItem)?.segmentedControl?.selectSegment(withTag: tag)
            
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
        
        // update editor information
        self.document?.analyzer.invalidateEditorInfo()
        
        // update incompatible characters list
        self.document?.incompatibleCharacterScanner.invalidate()
        
        // parse outline
        self.syntaxParser?.invalidateOutline()
        
        // perform highlight parsing in the next run loop to give layoutManagers time to update their values
        DispatchQueue.main.async { [weak self] in
            self?.invalidateSyntaxHighlight(in: editedRange)
        }
    }
    
    
    /// update outline menu in navigation bar
    func syntaxParser(_ syntaxParser: SyntaxParser, didParseOutline outlineItems: [OutlineItem]) {
        
        for viewController in self.editorViewControllers {
            viewController.navigationBarController?.outlineProgress = nil
            viewController.navigationBarController?.outlineItems = outlineItems
            // -> The selection update will be done in the `otutlineItems`'s setter above, so you don't need to invoke it (2008-05-16)
        }
    }
    
    
    func syntaxParser(_ syntaxParser: SyntaxParser, didStartParsingOutline progress: Progress) {
        
        for viewController in self.editorViewControllers {
            viewController.navigationBarController?.outlineProgress = progress
        }
    }
    
    
    
    // MARK: Notifications
    
    /// selection did change
    @objc private func textViewDidChangeSelection(_ notification: Notification) {
        
        // update document information
        self.document?.analyzer.invalidateEditorInfo(onlySelection: true)
    }
    
    
    /// document updated syntax style
    @objc private func didChangeSyntaxStyle(_ notification: Notification) {
        
        guard let syntaxParser = self.syntaxParser else { return assertionFailure() }
        
        syntaxParser.delegate = self
        
        for viewController in self.editorViewControllers {
            viewController.apply(style: syntaxParser.style)
            viewController.navigationBarController?.outlineItems = []
            viewController.navigationBarController?.outlineProgress = nil
        }
        
        syntaxParser.invalidateOutline()
        self.invalidateSyntaxHighlight()
    }
    
    
    /// theme did update
    @objc private func didUpdateTheme(_ notification: Notification) {
        
        guard
            let oldName = notification.userInfo?[Notification.UserInfoKey.old] as? String,
            let newName = notification.userInfo?[Notification.UserInfoKey.new] as? String,
            oldName == self.theme?.name else { return }
        
        self.setTheme(name: newName)
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
    
    
    /// change writing direction from segmented control button
    @IBAction func changeWritingDirection(_ sender: NSSegmentedControl) {
        
        switch sender.selectedSegment {
            case 0:
                self.makeLayoutOrientationHorizontal(nil)
                self.makeWritingDirectionLeftToRight(nil)
            case 1:
                self.makeLayoutOrientationHorizontal(nil)
                self.makeWritingDirectionRightToLeft(nil)
            case 2:
                self.makeWritingDirectionLeftToRight(nil)
                self.makeLayoutOrientationVertical(nil)
            default:
                assertionFailure("Segmented writing direction button must have 3 segments only.")
        }
    }
    
    
    /// change layout orientation from segmented control button
    @IBAction func changeOrientation(_ sender: NSSegmentedControl) {
        
        switch sender.selectedSegment {
            case 0:
                self.makeLayoutOrientationHorizontal(nil)
            case 1:
                self.makeLayoutOrientationVertical(nil)
            default:
                assertionFailure("Segmented layout orientation button must have 2 segments only.")
        }
    }
    
    
    /// split editor view
    @IBAction func openSplitTextView(_ sender: Any?) {
        
        guard
            let splitViewController = self.splitViewController,
            let currentEditorViewController = self.findTargetEditorViewController(for: sender)
            else { return assertionFailure() }
        
        guard splitViewController.splitViewItems.count < maximumNumberOfSplitEditors else { return NSSound.beep() }
        
        // end current editing
        NSTextInputContext.current?.discardMarkedText()
        
        let newEditorViewController = EditorViewController.instantiate(storyboard: "EditorView")
        splitViewController.addSubview(for: newEditorViewController, relativeTo: currentEditorViewController)
        self.setup(editorViewController: newEditorViewController, baseViewController: currentEditorViewController)
        
        newEditorViewController.navigationBarController?.outlineItems = self.syntaxParser?.outlineItems ?? []
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
            let currentEditorViewController = self.findTargetEditorViewController(for: sender),
            let splitViewItem = splitViewController.splitViewItem(for: currentEditorViewController)
            else { return }
        
        if let textView = currentEditorViewController.textView {
            NotificationCenter.default.removeObserver(self, name: NSTextView.didChangeSelectionNotification, object: textView)
        }
        
        // end current editing
        NSTextInputContext.current?.discardMarkedText()
        
        // move focus to the next text view if the view to close has a focus
        if splitViewController.focusedChild == currentEditorViewController {
            let childViewControllers = self.editorViewControllers
            let deleteIndex = childViewControllers.firstIndex(of: currentEditorViewController) ?? 0
            let newFocusEditorViewController = childViewControllers[safe: deleteIndex + 1] ?? childViewControllers.last!
            
            self.view.window?.makeFirstResponder(newFocusEditorViewController.textView)
        }
        
        // close
        splitViewController.removeSplitViewItem(splitViewItem)
    }
    
    
    
    // MARK: Private Methods
    
    /// Whether at least one of invisible characters is enabled in the preferences currently.
    private var canActivateShowInvisibles: Bool {
        
        let defaults = UserDefaults.standard
        return (defaults[.showInvisibleSpace] ||
            defaults[.showInvisibleTab] ||
            defaults[.showInvisibleNewLine] ||
            defaults[.showInvisibleFullwidthSpace] ||
            defaults[.showOtherInvisibleChars])
    }
    
    
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
        
        guard let parser = self.syntaxParser, parser.canParse else { return }
        
        // start parse
        let progress: Progress?
        if let range = range {
            progress = parser.highlight(around: range)
        } else {
            progress = parser.highlightAll()
        }
        
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
        
        // display indicator first when window is visible
        let presentBlock = { [weak self, weak progress] in
            guard
                let self = self,
                let progress = progress,
                !progress.isFinished, !progress.isCancelled
                else { return }
            
            self.presentedViewControllers?
                .filter { $0 is ProgressViewController }
                .forEach { $0.dismiss(nil) }
            
            let message = "Coloring text…".localized
            let indicator = ProgressViewController.instantiate(storyboard: "CompactProgressView")
            indicator.setup(progress: progress, message: message)
            
            self.presentAsSheet(indicator)
        }
        
        if window.occlusionState.contains(.visible) {
            presentBlock()
        } else {
            weak var observer: NSObjectProtocol?
            observer = NotificationCenter.default.addObserver(forName: NSWindow.didChangeOcclusionStateNotification, object: window, queue: .main) { (notification) in
                guard
                    let window = notification.object as? NSWindow,
                    window.occlusionState.contains(.visible)
                    else { return }
                
                if let observer = observer {
                    NotificationCenter.default.removeObserver(observer)
                }
                
                presentBlock()
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
    
    
    /// find target EditorViewController to manage split views for action sender
    private func findTargetEditorViewController(for sender: Any?) -> EditorViewController? {
        
        guard
            let view = (sender is NSMenuItem) ? (self.view.window?.firstResponder as? NSView) : sender as? NSView,
            let editorView = sequence(first: view, next: { $0.superview })
                .first(where: { $0.identifier == NSUserInterfaceItemIdentifier("EditorView") })
            else { return nil }
        
        return self.splitViewController?.viewController(for: editorView)
    }
    
}



// MARK: Protocol

extension DocumentViewController: TextFinderClientProvider {
    
    /// Tell text finder in which text view the text find should perform.
    func textFinderClient() -> NSTextView? {
        
        return self.focusedTextView
    }
}
