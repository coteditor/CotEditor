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

private let maximumNumberOfSplitEditors = 8


final class DocumentViewController: NSSplitViewController, ThemeHolder, NSToolbarItemValidation {
    
    private enum SerializationKey {
        
        static let theme = "theme"
        static let writingDirection = "writingDirection"
    }
    
    
    // MARK: Private Properties
    
    /// keys for bool values to be restored from the last session
    private var restorableBoolStateKeyPaths: [String] = [
        #keyPath(showsLineNumber),
        #keyPath(showsPageGuide),
        #keyPath(showsIndentGuides),
        #keyPath(showsInvisibles),
        #keyPath(wrapsLines),
        #keyPath(verticalLayoutOrientation),
        #keyPath(isAutoTabExpandEnabled),
    ]
    
    private var documentStyleObserver: AnyCancellable?
    private var outlineObserver: AnyCancellable?
    private var appearanceObserver: AnyCancellable?
    private var defaultsObservers: Set<AnyCancellable> = []
    private var themeChangeObserver: AnyCancellable?
    
    private lazy var outlineParseDebouncer = Debouncer(delay: .seconds(0.4)) { [weak self] in self?.syntaxParser?.invalidateOutline() }
    
    @IBOutlet private weak var splitViewItem: NSSplitViewItem?
    @IBOutlet private weak var statusBarItem: NSSplitViewItem?
    
    
    
    // MARK: -
    // MARK: Split View Controller Methods
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
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
        self.statusBarItem?.isCollapsed = !defaults[.showStatusBar]
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
        
        // observe cursor
        NotificationCenter.default.addObserver(self, selector: #selector(textViewDidLiveChangeSelection),
                                               name: EditorTextView.didLiveChangeSelectionNotification,
                                               object: self.editorViewControllers.first!.textView!)
        
        // observe appearance change for theme toggle
        self.appearanceObserver = self.view.publisher(for: \.effectiveAppearance)
            .sink { [weak self] (appearance) in
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
    
    
    override func encodeRestorableState(with coder: NSCoder, backgroundQueue queue: OperationQueue) {
        
        super.encodeRestorableState(with: coder, backgroundQueue: queue)
        
        if let themeName = self.theme?.name {
            coder.encode(themeName, forKey: SerializationKey.theme)
        }
        
        coder.encode(self.writingDirection.rawValue, forKey: SerializationKey.writingDirection)
        
        // manually encode `restorableStateKeyPaths` for secure state restoration
        for keyPath in self.restorableBoolStateKeyPaths {
            coder.encode(self.value(forKeyPath: keyPath), forKey: keyPath)
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
        
        if coder.containsValue(forKey: SerializationKey.writingDirection),
           let direction = NSWritingDirection(rawValue: coder.decodeInteger(forKey: SerializationKey.writingDirection))
        {
            self.writingDirection = direction
        }
        
        // manually decode `restorableStateKeyPaths` for secure state restoration
        for keyPath in self.restorableBoolStateKeyPaths where coder.containsValue(forKey: keyPath) {
            let value = coder.decodeObject(of: NSNumber.self, forKey: keyPath)
            self.setValue(value, forKeyPath: keyPath)
        }
    }
    
    
    /// deliver document to child view controllers
    override var representedObject: Any? {
        
        willSet {
            self.documentStyleObserver = nil
            self.outlineObserver = nil
        }
        
        didSet {
            guard let document = representedObject as? Document else { return }
            
            // This setter can be invoked twice if the view was initially made for a transient document.
            
            (self.statusBarItem?.viewController as? StatusBarController)?.document = document
            
            NotificationCenter.default.addObserver(self, selector: #selector(textStorageDidProcessEditing),
                                                   name: NSTextStorage.didProcessEditingNotification,
                                                   object: document.textStorage)
            
            let editorViewController = self.editorViewControllers.first!
            self.setup(editorViewController: editorViewController, baseViewController: nil)
            
            // start parsing syntax for highlighting and outlines
            self.outlineParseDebouncer.perform()
            document.syntaxParser.highlight()
            
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
            self.outlineObserver = document.syntaxParser.$outlineItems
                .removeDuplicates()
                .receive(on: RunLoop.main)
                .sink { [weak self] (outlineItems) in
                    self?.editorViewControllers.forEach { $0.outlineItems = outlineItems }
                }
        }
    }
    
    
    /// avoid showing draggable cursor for the status bar boundary
    override func splitView(_ splitView: NSSplitView, effectiveRect proposedEffectiveRect: NSRect, forDrawnRect drawnRect: NSRect, ofDividerAt dividerIndex: Int) -> NSRect {
        
        .zero
    }
    
    
    /// apply current state to related toolbar items
    func validateToolbarItem(_ item: NSToolbarItem) -> Bool {
        
        // manually pass toolbar items to `validateUserInterfaceItem(_:)`,
        // because they actually doesn't use it for validation (2020-08 on macOS 10.15)
        return self.validateUserInterfaceItem(item)
    }
    
    
    override func validateUserInterfaceItem(_ item: any NSValidatedUserInterfaceItem) -> Bool {
        
        switch item.action {
            case #selector(changeTheme):
                if let item = item as? NSMenuItem {
                    item.state = (self.theme?.name == item.title) ? .on : .off
                }
                
            case #selector(toggleLineNumber):
                (item as? NSMenuItem)?.title = self.showsLineNumber
                    ? "Hide Line Numbers".localized
                    : "Show Line Numbers".localized
                
            case #selector(toggleStatusBar):
                (item as? NSMenuItem)?.title = self.statusBarItem?.isCollapsed == false
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
                (item as? NSToolbarItem)?.toolTip = self.showsIndentGuides
                    ? "Hide indent guide lines".localized
                    : "Show indent guide lines".localized
                (item as? StatableToolbarItem)?.state = self.showsIndentGuides ? .on : .off
                
            case #selector(toggleLineWrap):
                (item as? NSMenuItem)?.title = self.wrapsLines
                    ? "Unwrap Lines".localized
                    : "Wrap Lines".localized
                if #available(macOS 13, *) {
                    (item as? NSToolbarItem)?.label = self.wrapsLines
                        ? "Unwrap lines".localized
                        : "Wrap lines".localized
                }
                (item as? StatableToolbarItem)?.state = self.wrapsLines ? .on : .off
                
            case #selector(toggleInvisibleChars):
                (item as? NSMenuItem)?.title = self.showsInvisibles
                    ? "Hide Invisibles".localized
                    : "Show Invisibles".localized
                (item as? StatableToolbarItem)?.state = self.showsInvisibles ? .on : .off
                
                // disable if item cannot be enabled
                let canActivateShowInvisibles = !UserDefaults.standard.showsInvisible.isEmpty
                item.toolTip = canActivateShowInvisibles ? nil : "To show invisible characters, set them in Settings".localized
                if canActivateShowInvisibles {
                    (item as? NSToolbarItem)?.toolTip = self.showsInvisibles
                        ? "Hide invisible characters".localized
                        : "Show invisible characters".localized
                }
                return canActivateShowInvisibles
                
            case #selector(toggleAntialias):
                (item as? any StatableItem)?.state = (self.focusedTextView?.usesAntialias ?? false) ? .on : .off
                
            case #selector(toggleLigatures):
                (item as? any StatableItem)?.state = (self.focusedTextView?.ligature != NSTextView.LigatureMode.none) ? .on : .off
                
            case #selector(toggleAutoTabExpand):
                (item as? any StatableItem)?.state = self.isAutoTabExpandEnabled ? .on : .off
                (item as? NSToolbarItem)?.toolTip = self.isAutoTabExpandEnabled
                    ? "Turn off expanding tabs to spaces".localized
                    : "Expand tabs to spaces automatically".localized
                
            case #selector(changeTabWidth):
                (item as? any StatableItem)?.state = (self.tabWidth == item.tag) ? .on : .off
                
            case #selector(makeLayoutOrientationHorizontal):
                (item as? any StatableItem)?.state = self.verticalLayoutOrientation ? .off : .on
                
            case #selector(makeLayoutOrientationVertical):
                (item as? any StatableItem)?.state = self.verticalLayoutOrientation ? .on : .off
                
            case #selector(makeWritingDirectionLeftToRight):
                (item as? any StatableItem)?.state = (self.writingDirection == .leftToRight) ? .on : .off
                
            case #selector(makeWritingDirectionRightToLeft):
                (item as? any StatableItem)?.state = (self.writingDirection == .rightToLeft) ? .on : .off
                
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
    
    
    
    // MARK: Notifications
    
    /// text was edited (invoked right **before** notifying layout managers)
    override func textStorageDidProcessEditing(_ notification: Notification) {
        
        let textStorage = notification.object as! NSTextStorage
        
        guard
            textStorage.editedMask.contains(.editedCharacters),
            self.focusedTextView?.hasMarkedText() != true
        else { return }
        
        self.document?.analyzer.invalidate()
        self.document?.incompatibleCharacterScanner.invalidate()
        self.outlineParseDebouncer.schedule()
        
        // -> Perform in the next run loop to give layoutManagers time to update their values.
        let editedRange = textStorage.editedRange
        DispatchQueue.main.async { [weak self] in
            self?.syntaxParser?.highlight(around: editedRange)
        }
    }
    
    
    /// selection did change
    @objc private func textViewDidLiveChangeSelection(_ notification: Notification) {
        
        self.document?.analyzer.invalidate(onlySelection: true)
    }
    
    
    /// document updated syntax style
    private func didChangeSyntaxStyle() {
        
        guard let syntaxParser = self.syntaxParser else { return assertionFailure() }
        
        for viewController in self.editorViewControllers {
            viewController.apply(style: syntaxParser.style)
        }
        
        self.outlineParseDebouncer.perform()
        syntaxParser.highlight()
    }
    
    
    
    // MARK: Public Methods
    
    /// setup document
    var document: Document? {
        
        self.representedObject as? Document
    }
    
    
    /// return textView focused on
    var focusedTextView: EditorTextView? {
        
        self.splitViewController?.focusedChild?.textView ?? self.editorViewControllers.first?.textView
    }
    
    
    /// coloring theme
    var theme: Theme? {
        
        self.focusedTextView?.theme
    }
    
    
    /// body font
    var font: NSFont? {
        
        self.focusedTextView?.font
    }
    
    
    /// visibility of line numbers view
    @objc var showsLineNumber = false {
        
        didSet {
            for viewController in self.editorViewControllers {
                viewController.showsLineNumber = showsLineNumber
            }
            self.invalidateRestorableState()
        }
    }
    
    
    /// if lines soft-wrap at window edge
    @objc var wrapsLines = false {
        
        didSet {
            for textView in self.editorViewControllers.compactMap(\.textView) {
                textView.wrapsLines = wrapsLines
            }
            self.invalidateRestorableState()
        }
    }
    
    
    /// visibility of page guide lines in text view
    @objc var showsPageGuide = false {
        
        didSet {
            for textView in self.editorViewControllers.compactMap(\.textView) {
                textView.showsPageGuide = showsPageGuide
            }
            self.invalidateRestorableState()
        }
    }
    
    
    /// visibility of indent guides in text view
    @objc var showsIndentGuides = false {
        
        didSet {
            for textView in self.editorViewControllers.compactMap(\.textView) {
                textView.showsIndentGuides = showsIndentGuides
            }
            self.invalidateRestorableState()
        }
    }
    
    
    /// visibility of invisible characters
    @objc var showsInvisibles = false {
        
        didSet {
            for textView in self.editorViewControllers.compactMap(\.textView) {
                textView.showsInvisibles = showsInvisibles
            }
            self.invalidateRestorableState()
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
            
            for textView in self.editorViewControllers.compactMap(\.textView) {
                textView.setLayoutOrientation(orientation)
            }
            self.invalidateRestorableState()
        }
    }
    
    
    var writingDirection: NSWritingDirection {
        
        get {
            self.focusedTextView?.baseWritingDirection ?? .leftToRight
        }
        
        set {
            for textView in self.editorViewControllers.compactMap(\.textView) where textView.baseWritingDirection != newValue {
                textView.baseWritingDirection = newValue
            }
            self.invalidateRestorableState()
        }
    }
    
    
    /// textView's tab width
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
    
    
    /// whether replace tab with spaces
    @objc var isAutoTabExpandEnabled: Bool {
        
        get {
            self.focusedTextView?.isAutomaticTabExpansionEnabled ?? UserDefaults.standard[.autoExpandTab]
        }
        
        set {
            for textView in self.editorViewControllers.compactMap(\.textView) {
                textView.isAutomaticTabExpansionEnabled = newValue
            }
            self.invalidateRestorableState()
        }
    }
    
    
    /// apply text styles from text view
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
    
    /// recolor whole document
    @IBAction func recolorAll(_ sender: Any?) {
        
        self.syntaxParser?.highlight()
    }
    
    
    /// set new theme from menu item
    @IBAction func changeTheme(_ sender: AnyObject?) {
        
        guard let name = sender?.title else { return assertionFailure() }
        
        self.setTheme(name: name)
    }
    
    
    /// toggle visibility of line number view
    @IBAction func toggleLineNumber(_ sender: Any?) {
        
        self.showsLineNumber.toggle()
    }
    
    
    /// toggle visibility of status bar with fancy animation (sync all documents)
    @IBAction func toggleStatusBar(_ sender: Any?) {
        
        UserDefaults.standard[.showStatusBar].toggle()
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
        
        for textView in self.editorViewControllers.compactMap(\.textView) {
            textView.usesAntialias.toggle()
        }
    }
    
    
    /// toggle ligature mode in text view
    @IBAction func toggleLigatures(_ sender: Any?) {
        
        for textView in self.editorViewControllers.compactMap(\.textView) {
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
        
        let view = CustomTabWidthView(tabWidth: self.tabWidth) { [weak self] (tabWidth) in
            self?.tabWidth = tabWidth
        }
        let viewController = NSHostingController(rootView: view)
        viewController.rootView.parent = viewController
        
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
        
        self.verticalLayoutOrientation = false
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
        
        let opacityView = OpacityView(window: self.view.window as? DocumentWindow)
        let viewController = NSHostingController(rootView: opacityView)
        viewController.ensureFrameSize()
        
        self.present(viewController, asPopoverRelativeTo: .zero, of: self.view,
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
        
        let newEditorViewController = NSStoryboard(name: "EditorView").instantiateInitialController() as! EditorViewController
        splitViewController.addChild(newEditorViewController, relativeTo: currentEditorViewController)
        self.setup(editorViewController: newEditorViewController, baseViewController: currentEditorViewController)
        
        newEditorViewController.outlineItems = self.syntaxParser?.outlineItems ?? []
        
        // adjust visible areas
        if let selectedRange = currentEditorViewController.textView?.selectedRange {
            newEditorViewController.textView?.selectedRange = selectedRange
            currentEditorViewController.textView?.scrollRangeToVisible(selectedRange)
            newEditorViewController.textView?.scrollRangeToVisible(selectedRange)
        }
        
        // observe cursor
        NotificationCenter.default.addObserver(self, selector: #selector(textViewDidLiveChangeSelection),
                                               name: EditorTextView.didLiveChangeSelectionNotification,
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
    
    /// create and set-up new (split) editor view
    private func setup(editorViewController: EditorViewController, baseViewController: EditorViewController?) {
        
        editorViewController.setTextStorage(self.textStorage!)
        
        guard let textView = editorViewController.textView else { return assertionFailure() }
        
        textView.wrapsLines = self.wrapsLines
        textView.showsInvisibles = self.showsInvisibles
        textView.setLayoutOrientation(self.verticalLayoutOrientation ? .vertical : .horizontal)
        if textView.baseWritingDirection != self.writingDirection {
            textView.baseWritingDirection = self.writingDirection
        }
        textView.showsPageGuide = self.showsPageGuide
        textView.showsIndentGuides = self.showsIndentGuides
        editorViewController.showsLineNumber = self.showsLineNumber  // need to be set after setting text orientation
        
        if let syntaxParser = self.syntaxParser {
            editorViewController.apply(style: syntaxParser.style)
        }
        
        // copy textView states
        if let baseTextView = baseViewController?.textView {
            textView.font = baseTextView.font
            textView.usesAntialias = baseTextView.usesAntialias
            textView.ligature = baseTextView.ligature
            textView.theme = baseTextView.theme
            textView.tabWidth = baseTextView.tabWidth
            textView.isAutomaticTabExpansionEnabled = baseTextView.isAutomaticTabExpansionEnabled
            
            if let highlights = baseTextView.layoutManager?.syntaxHighlights(), !highlights.isEmpty {
                textView.layoutManager?.apply(highlights: highlights, range: textView.string.range)
            }
        }
    }
    
    
    /// split view controller
    private var splitViewController: SplitViewController? {
        
        self.splitViewItem?.viewController as? SplitViewController
    }
    
    
    /// text storage
    private var textStorage: NSTextStorage? {
        
        self.document?.textStorage
    }
    
    
    /// document's syntax parser
    private var syntaxParser: SyntaxParser? {
        
        self.document?.syntaxParser
    }
    
    
    /// child editor view controllers
    private var editorViewControllers: [EditorViewController] {
        
        self.splitViewController?.children.compactMap { $0 as? EditorViewController } ?? []
    }
    
    
    /// apply theme
    private func setTheme(name: String) {
        
        assert(Thread.isMainThread)
        
        guard let theme = ThemeManager.shared.setting(name: name) else { return }
        
        for textView in self.editorViewControllers.compactMap(\.textView) {
            textView.theme = theme
            textView.layoutManager?.invalidateHighlight(theme: theme)
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
