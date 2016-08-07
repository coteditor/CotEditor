/*
 
 EditorWrapper.swift
 
 CotEditor
 https://coteditor.com
 
 Created by nakamuxu on 2004-12-08.
 
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014-2016 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Cocoa

final class EditorWrapper: NSResponder, TextFinderClientProvider, SyntaxStyleDelegate, NSTextStorageDelegate {
    
    // MARK: Private Properties
    
    @IBOutlet private var splitViewItem: NSSplitViewItem?
    
    
    
    // MARK:
    // MARK: Lifecycle
    
    override init() {
        
        let defaults = UserDefaults.standard
        
        self.showsInvisibles = defaults.bool(forKey: DefaultKey.showInvisibles)
        self.showsLineNumber = defaults.bool(forKey: DefaultKey.showLineNumbers)
        self.showsNavigationBar = defaults.bool(forKey: DefaultKey.showNavigationBar)
        self.wrapsLines = defaults.bool(forKey: DefaultKey.wrapLines)
        self.verticalLayoutOrientation = defaults.bool(forKey: DefaultKey.layoutTextVertical)
        self.showsPageGuide = defaults.bool(forKey: DefaultKey.showPageGuide)
        
        super.init()
        
        NotificationCenter.default.addObserver(self, selector: #selector(didUpdateTheme),
                                               name: .ThemeDidUpdate,
                                               object: nil)
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        
        self.textStorage?.delegate = nil
    }
    
    
    
    // MARK: Responder Methods
    
    /// join to responder chain
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        self.window?.nextResponder = self
    }
    
    
    /// keys to be restored from the last session
    override class func restorableStateKeyPaths() -> [String] {
        
        return [#keyPath(showsNavigationBar),
                #keyPath(showsLineNumber),
                #keyPath(showsPageGuide),
                #keyPath(showsInvisibles),
                #keyPath(verticalLayoutOrientation)]
    }
    
    
    /// apply current state to related menu items
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        
        guard let action = menuItem.action else { return false }
        
        switch action {
        case #selector(recolorAll):
            return self.syntaxStyle?.canParse ?? false
            
        case #selector(toggleLineNumber):
            let title = self.showsLineNumber ? "Hide Line Numbers" : "Show Line Numbers"
            menuItem.title = NSLocalizedString(title, comment: "")
            
        case #selector(toggleNavigationBar):
            let title = self.showsNavigationBar ? "Hide Navigation Bar" : "Show Navigation Bar"
            menuItem.title = NSLocalizedString(title, comment: "")
            
        case #selector(toggleLineWrap):
            let title = self.wrapsLines ? "Unwrap Lines" : "Wrap Lines"
            menuItem.title = NSLocalizedString(title, comment: "")
            
        case #selector(toggleLayoutOrientation):
            let title = self.verticalLayoutOrientation ? "Use Horizontal Orientation" : "Use Vertical Orientation"
            menuItem.title = NSLocalizedString(title, comment: "")
            
        case #selector(togglePageGuide):
            let title = self.showsPageGuide ? "Hide Page Guide" : "Show Page Guide"
            menuItem.title = NSLocalizedString(title, comment: "")
            
        case #selector(toggleInvisibleChars):
            let title = self.showsPageGuide ? "Hide Invisible Characters" : "Show Invisible Characters"
            menuItem.title = NSLocalizedString(title, comment: "")
            // disable button if item cannot be enable
            if self.canActivateShowInvisibles {
                menuItem.toolTip = NSLocalizedString("Show or hide invisible characters in document", comment: "")
            } else {
                menuItem.toolTip = NSLocalizedString("To show invisible characters, set them in Preferences", comment: "")
                return false
            }
            
        case #selector(toggleAutoTabExpand):
            menuItem.state = self.isAutoTabExpandEnabled ? NSOnState : NSOffState
            
        case #selector(toggleAntialias):
            menuItem.state = (self.focusedTextView?.usesAntialias ?? false) ? NSOnState : NSOffState
            
        case #selector(changeTabWidth):
            menuItem.state = (self.tabWidth == menuItem.tag) ? NSOnState : NSOffState
            
        case #selector(closeSplitTextView):
            return (self.splitViewController?.splitViewItems.count > 1)
            
        case #selector(changeTheme):
            menuItem.state = (self.theme?.name == menuItem.title) ? NSOnState : NSOffState
            
        default: break
        }
        
        return true
    }
    
    
    /// apply current state to related toolbar items
    override func validateToolbarItem(_ item: NSToolbarItem) -> Bool {
        
        guard let action = item.action else { return false }
        
        switch action {
        case #selector(recolorAll):
            return self.syntaxStyle?.canParse ?? false
            
        default: break
        }
        
        // validate button image state
        if let imageItem = item as? TogglableToolbarItem {
            switch action {
            case #selector(toggleLineWrap):
                imageItem.state = self.wrapsLines ? NSOnState : NSOffState
                
            case #selector(toggleLayoutOrientation):
                imageItem.state = self.verticalLayoutOrientation ? NSOnState : NSOffState
                
            case #selector(togglePageGuide):
                imageItem.state = self.showsPageGuide ? NSOnState : NSOffState
                
            case #selector(toggleInvisibleChars):
                imageItem.state = self.showsInvisibles ? NSOnState : NSOffState
                
                // disable button if item cannot be enabled
                if self.canActivateShowInvisibles {
                    imageItem.toolTip = NSLocalizedString("Show or hide invisible characters in document", comment: "")
                } else {
                    imageItem.toolTip = NSLocalizedString("To show invisible characters, set them in Preferences", comment: "")
                    return false
                }
                
            case #selector(toggleAutoTabExpand):
                imageItem.state = self.isAutoTabExpandEnabled ? NSOnState : NSOffState
                
            default: break
            }
        }
        
        return true
    }
    
    
    
    // MARK: Protocol
    
    /// tell text finder in which text view should it find text
    func textFinderClient() -> NSTextView? {
        
        return self.focusedTextView
    }
    
    
    
    // MARK: Delegate
    
    /// text did edit
    override func textStorageDidProcessEditing(_ notification: Notification) {
        
        // ignore if only attributes did change
        guard let textStorage = notification.object as? NSTextStorage,
            textStorage.editedMask.contains(.editedCharacters) else { return }
        
        // update editor information
        // -> In case, if "Replace All" performed without moving caret.
        self.document?.analyzer.invalidateEditorInfo()
        
        // parse syntax
        self.syntaxStyle?.invalidateOutline()
        if let syntaxStyle = self.syntaxStyle, syntaxStyle.canParse {
            // perform highlight in the next run loop to give layoutManager time to update temporary attribute
            let updateRange = textStorage.editedRange
            DispatchQueue.main.async {
                syntaxStyle.highlight(around: updateRange)
            }
        }
        
        // update incompatible chars list
        self.document?.incompatibleCharacterScanner.invalidate()
    }
    
    
    /// update outline menu in navigation bar
    func syntaxStyle(_ syntaxStyle: SyntaxStyle, didParseOutline outlineItems: [OutlineItem]?) {
        
        guard let childViewControllers = self.splitViewController?.childViewControllers as? [EditorViewController],
            let outlineItems = outlineItems else { return }
        
        for viewController in childViewControllers {
            viewController.navigationBarController?.outlineItems = outlineItems
            // -> The selection update will be done in the `setOutlineItems` method above, so you don't need invoke it (2008-05-16)
        }
    }
    
    
    
    // MARK: Notifications
    
    /// selection did change
    func textViewDidChangeSelection(_ notification: NSNotification?) {
        
        // update document information
        self.document?.analyzer.invalidateEditorInfo()
    }
    
    
    /// document updated syntax style
    func didChangeSyntaxStyle(_ notification: NSNotification?) {
        
        guard let syntaxStyle = self.syntaxStyle else { return }
        
        syntaxStyle.delegate = self
        
        if let childViewControllers = self.splitViewController?.childViewControllers as? [EditorViewController]  {
            for viewController in childViewControllers {
                viewController.apply(syntax: syntaxStyle)
                if syntaxStyle.canParse {
                    viewController.navigationBarController?.showOutlineIndicator()
                }
            }
        }
        
        syntaxStyle.invalidateOutline()
        self.invalidateSyntaxHighlight()
    }
    
    
    /// theme did update
    func didUpdateTheme(_ notification: NSNotification?) {
        
        guard
            let oldName = notification?.userInfo?[SettingFileManager.NotificationKey.old] as? String,
            let newName = notification?.userInfo?[SettingFileManager.NotificationKey.new] as? String else { return }
        
        if oldName == self.theme?.name {
            self.setTheme(name: newName)
        }
    }
    
    
    
    // MARK: Public Methods
    
    /// return textView focused on
    var focusedTextView: EditorTextView? {
        
        return self.splitViewController?.focusedSubviewController?.textView
    }
    
    
    /// setup document
    var document: Document? {
        
        didSet {
            guard let document = document else { return }
            
            // detect indent style
            if UserDefaults.standard.bool(forKey: DefaultKey.detectsIndentStyle),
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
            
            document.textStorage.delegate = self
            document.syntaxStyle.delegate = self
            
            let editorViewController = self.createEditor(baseViewController: nil)
            
            // start parcing syntax highlights and outline menu
            if document.syntaxStyle.canParse {
                editorViewController.navigationBarController?.showOutlineIndicator()
            }
            document.syntaxStyle.invalidateOutline()
            self.invalidateSyntaxHighlight()
            
            // focus text view
            self.window?.makeFirstResponder(editorViewController.textView)
            
            // observe syntax/theme change
            NotificationCenter.default.addObserver(self, selector: #selector(didChangeSyntaxStyle),
                                                   name: .DocumentDidChangeSyntaxStyle,
                                                   object: document)
        }
    }
    
    
    /// visibility of navigation bars
    var showsNavigationBar: Bool {
        
        didSet {
            guard let childViewControllers = self.splitViewController?.childViewControllers as? [EditorViewController] else { return }
            
            for viewController in childViewControllers {
                viewController.setShowsNavigationBar(showsNavigationBar, animate: false)
            }
        }
    }
    
    
    /// visibility of line numbers view
    var showsLineNumber: Bool {
        
        didSet {
            guard let childViewControllers = self.splitViewController?.childViewControllers as? [EditorViewController] else { return }
            
            for viewController in childViewControllers {
                viewController.showsLineNumber = showsLineNumber
            }
        }
    }
    
    
    /// if lines soft-wrap at window edge
    var wrapsLines: Bool {
        
        didSet {
            guard let childViewControllers = self.splitViewController?.childViewControllers as? [EditorViewController] else { return }
            
            for viewController in childViewControllers {
                viewController.textView?.wrapsLines = wrapsLines
            }
        }
    }
    
    
    /// visibility of page guide lines in text view
    var showsPageGuide = false {
        
        didSet {
            guard let childViewControllers = self.splitViewController?.childViewControllers as? [EditorViewController] else { return }
            
            for viewController in childViewControllers {
                guard let textView = viewController.textView else { continue }
                textView.showsPageGuide = showsPageGuide
                textView.setNeedsDisplay(textView.visibleRect, avoidAdditionalLayout: true)
            }
        }
    }
    
    
    /// visibility of invisible characters
    var showsInvisibles = false {
        
        didSet {
            guard let childViewControllers = self.splitViewController?.childViewControllers as? [EditorViewController] else { return }
            
            for viewController in childViewControllers {
                viewController.textView?.showsInvisibles = showsInvisibles
            }
        }
    }
    
    
    /// if text orientation is vertical
    var verticalLayoutOrientation: Bool {
        
        didSet {
            guard let childViewControllers = self.splitViewController?.childViewControllers as? [EditorViewController] else { return }
            
            let orientation: NSTextLayoutOrientation = verticalLayoutOrientation ? .vertical : .horizontal
            
            for viewController in childViewControllers {
                viewController.textView?.setLayoutOrientation(orientation)
            }
        }
    }
    
    
    /// textView's tab width
    var tabWidth: Int {
        
        get {
            return self.focusedTextView?.tabWidth ?? 0
        }
        set (tabWidth) {
            guard let childViewControllers = self.splitViewController?.childViewControllers as? [EditorViewController] else { return }
            
            for viewController in childViewControllers {
                viewController.textView?.tabWidth = tabWidth
            }
        }
    }
    
    
    /// body font
    var font: NSFont? {
        
        return self.focusedTextView?.font
    }
    
    
    /// coloring theme
    var theme: Theme? {
        
        return self.focusedTextView?.theme
    }
    
    
    /// change background color of pased-in ranges (incompatible chars scannar may use this method)
    func markup(ranges: [NSRange]) {
        
        guard
            let textStorage = self.textStorage,
            let lineEnding = self.document?.lineEnding,
            let color = textStorage.layoutManagers.first?.firstTextView?.textColor?.withAlphaComponent(0.2) else { return }
        
        for range in ranges {
            let viewRange = textStorage.string.convert(range: range, from: lineEnding, to: .LF)
            
            for manager in textStorage.layoutManagers {
                manager.addTemporaryAttribute(NSBackgroundColorAttributeName, value: color, forCharacterRange: viewRange)
            }
        }
    }
    
    
    /// clear all background highlight (including text finder's highlights)
    func clearAllMarkup() {
        
        guard let textStorage = self.textStorage else { return }
        
        let range = textStorage.string.nsRange
        
        for manager in textStorage.layoutManagers {
            manager.removeTemporaryAttribute(NSBackgroundColorAttributeName, forCharacterRange: range)
        }
    }
    
    
    /// apply text styles from text view
    func invalidateStyleInTextStorage() {
        
        self.focusedTextView?.invalidateStyle()
    }
    
    
    
    // MARK: Action Messages
    
    /// toggle visibility of line number view
    @IBAction func toggleLineNumber(_ sender: AnyObject?) {
        
        self.showsLineNumber = !self.showsLineNumber
        
    }
    
    
    /// toggle visibility of navigation bar
    @IBAction func toggleNavigationBar(_ sender: AnyObject?) {
        
        self.showsNavigationBar = !self.showsNavigationBar
        
        guard let childViewControllers = self.splitViewController?.childViewControllers as? [EditorViewController] else { return }
        
        for viewController in childViewControllers {
            viewController.setShowsNavigationBar(self.showsNavigationBar, animate: true)
        }
    }
    
    
    /// toggle if lines wrap at window edge
    @IBAction func toggleLineWrap(_ sender: AnyObject?) {
        
        self.wrapsLines = !self.wrapsLines
    }
    
    
    /// toggle text layout orientation (vertical/horizontal)
    @IBAction func toggleLayoutOrientation(_ sender: AnyObject?) {
        
        self.verticalLayoutOrientation = !self.verticalLayoutOrientation
    }
    
    
    /// toggle if antialias text in text view
    @IBAction func toggleAntialias(_ sender: AnyObject?) {
        
        guard
            let usesAntialias = self.focusedTextView?.usesAntialias,
            let childViewControllers = self.splitViewController?.childViewControllers as? [EditorViewController] else { return }
        
        for viewController in childViewControllers {
            viewController.textView?.usesAntialias = !usesAntialias
        }
    }
    
    
    /// toggle visibility of invisible characters in text view
    @IBAction func toggleInvisibleChars(_ sender: AnyObject?) {
        
        self.showsInvisibles = !self.showsInvisibles
    }
    
    
    /// toggle visibility of page guide line in text view
    @IBAction func togglePageGuide(_ sender: AnyObject?) {
        
        self.showsPageGuide = !self.showsPageGuide
    }
    
    
    /// toggle if text view expands tab input
    @IBAction func toggleAutoTabExpand(_ sender: AnyObject?) {
        
        self.isAutoTabExpandEnabled = !(self.focusedTextView?.isAutomaticTabExpansionEnabled ?? false)
        
    }
    
    
    /// change tab width from the main menu
    @IBAction func changeTabWidth(_ sender: AnyObject?) {
        
        guard let tabWidth = sender?.tag else { return }
        
        self.tabWidth = tabWidth
    }
    
    
    /// set new theme from menu item
    @IBAction func changeTheme(_ sender: AnyObject?) {
        
        guard let name = sender?.title, !name.isEmpty else { return }
        
        self.setTheme(name: name)
    }
    
    
    /// re-color whole document
    @IBAction func recolorAll(_ sender: AnyObject?) {
        
        self.invalidateSyntaxHighlight()
    }
    
    
    /// split editor view
    @IBAction func openSplitTextView(_ sender: AnyObject?) {
        
        // find target EditorViewController
        var view: NSView? = (sender is NSMenuItem) ? (self.window?.firstResponder as? NSView) : sender as? NSView
        while view != nil {
            if view?.identifier == "EditorView" { break }
            view = view?.superview
        }
        guard let editorView = view, let currentEditorViewController = self.splitViewController?.viewController(for: editorView) else { return }
        
        // end current editing
        NSTextInputContext.current()?.discardMarkedText()
        
        let newEditorViewController = self.createEditor(baseViewController: currentEditorViewController)
        
        newEditorViewController.navigationBarController?.outlineItems = self.syntaxStyle?.outlineItems ?? []
        self.invalidateSyntaxHighlight()
        
        // adjust visible areas
        newEditorViewController.textView?.selectedRange = currentEditorViewController.textView!.selectedRange()
        currentEditorViewController.textView?.centerSelectionInVisibleArea(self)
        newEditorViewController.textView?.centerSelectionInVisibleArea(self)
        
        // move focus to the new editor
        self.window?.makeFirstResponder(newEditorViewController.textView)
    }
    
    
    /// close one of split views
    @IBAction func closeSplitTextView(_ sender: AnyObject?) {
        
        // find target EditorViewController
        var view: NSView? = (sender is NSMenuItem) ? (self.window?.firstResponder as? NSView) : sender as? NSView
        while view != nil {
            if view?.identifier == "EditorView" { break }
            view = view?.superview
        }
        guard let editorView = view, let currentEditorViewController = self.splitViewController?.viewController(for: editorView) else { return }
        
        guard let splitViewController = self.splitViewController else { return }
        
        // end current editing
        NSTextInputContext.current()?.discardMarkedText()
        
        // move focus to the next text view if the view to close has a focus
        if splitViewController.focusedSubviewController == currentEditorViewController {
            let childViewControllers = splitViewController.childViewControllers as! [EditorViewController]
            let deleteIndex = childViewControllers.index(of: currentEditorViewController) ?? 0
            let count = childViewControllers.count
            var index = deleteIndex + 1
            if index >= count {
                index = count - 2
            }
            let newFocusEditorViewController = childViewControllers[index]
            guard newFocusEditorViewController != currentEditorViewController else { return }
            
            self.window?.makeFirstResponder(newFocusEditorViewController.textView)
        }
        
        // close
        if let splitViewItem = splitViewController.splitViewItem(for: currentEditorViewController) {
            splitViewController.removeSplitViewItem(splitViewItem)
        }
    }
    
    
    
    // MARK: Private Methods
    
    /// whether at least one of invisible characters is enabled in the preferences currently
    private var canActivateShowInvisibles: Bool {
        
        let defaults = UserDefaults.standard
        
        return (defaults.bool(forKey: DefaultKey.showInvisibleSpace) ||
                defaults.bool(forKey: DefaultKey.showInvisibleTab) ||
                defaults.bool(forKey: DefaultKey.showInvisibleNewLine) ||
                defaults.bool(forKey: DefaultKey.showInvisibleFullwidthSpace) ||
                defaults.bool(forKey: DefaultKey.showInvisibles))
    }
    
    
    /// re-highlight whole content
    private func invalidateSyntaxHighlight() {
        
        self.syntaxStyle?.highlightAll()
    }
    
    
    /// create and set-up new (split) editor view
    private func createEditor(baseViewController: EditorViewController?) -> EditorViewController {
        
        let storyboard = NSStoryboard(name: "EditorView", bundle: nil)
        let editorViewController = storyboard.instantiateInitialController() as! EditorViewController
        editorViewController.textStorage = self.textStorage
        
        // instert new editorView just below the editorView that the pressed button belongs to or has focus
        self.splitViewController?.addSubview(for: editorViewController, relativeTo: baseViewController)
        
        editorViewController.showsLineNumber = self.showsLineNumber
        editorViewController.setShowsNavigationBar(self.showsNavigationBar, animate: false)
        editorViewController.textView?.wrapsLines = self.wrapsLines
        editorViewController.textView?.showsInvisibles = self.showsInvisibles
        editorViewController.textView?.setLayoutOrientation(self.verticalLayoutOrientation ? .vertical : .horizontal)
        editorViewController.textView?.showsPageGuide = self.showsPageGuide
        
        if let syntaxStyle = self.syntaxStyle {
            editorViewController.apply(syntax: syntaxStyle)
        }
        
        // copy textView states
        if let textView = editorViewController.textView, let baseTextView = baseViewController?.textView {
            textView.font = baseTextView.font
            textView.theme = baseTextView.theme
            textView.tabWidth = baseTextView.tabWidth
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(textViewDidChangeSelection),
                                               name: .NSTextViewDidChangeSelection,
                                               object: editorViewController.textView)
        
        return editorViewController
    }
    
    
    /// split view controller
    private var splitViewController: SplitViewController? {
        
        return self.splitViewItem?.viewController as? SplitViewController
    }
    
    
    /// window
    private var window: NSWindow? {
        
        return self.splitViewController?.view.window
    }
    
    
    /// text storage
    private var textStorage: NSTextStorage? {
        
        return self.document?.textStorage
    }
    
    
    /// document's syntax style
    private var syntaxStyle: SyntaxStyle? {
        
        return self.document?.syntaxStyle
    }
    
    
    /// whether replace tab with spaces
    private var isAutoTabExpandEnabled: Bool {
        
        get {
            guard let textView = self.focusedTextView else {
                return UserDefaults.standard.bool(forKey: DefaultKey.autoExpandTab)
            }
            
            return textView.isAutomaticTabExpansionEnabled
        }
        
        set (isAutoTabExpandEnabled) {
            guard let childViewControllers = self.splitViewController?.childViewControllers as? [EditorViewController] else { return }
            for viewController in childViewControllers {
                viewController.textView?.isAutomaticTabExpansionEnabled = isAutoTabExpandEnabled
            }
        }
    }
    
    
    /// apply theme
    private func setTheme(name: String) {
        
        guard
            let theme = ThemeManager.shared.theme(name: name),
            let childViewControllers = self.splitViewController?.childViewControllers as? [EditorViewController] else { return }
        
        for viewController in childViewControllers {
            viewController.textView?.theme = theme
        }
        self.invalidateSyntaxHighlight()
    }
    
}
