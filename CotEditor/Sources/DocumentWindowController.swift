//
//  DocumentWindowController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by nakamuxu on 2004-12-13.
//
//  ---------------------------------------------------------------------------
//
//  © 2004-2007 nakamuxu
//  © 2013-2021 1024jp
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

final class DocumentWindowController: NSWindowController, NSWindowDelegate {
    
    // MARK: Public Properties
    
    var isWhitepaper = false {
        
        didSet {
            guard isWhitepaper || oldValue else { return }
            
            self.setDocumentEdited(!isWhitepaper)
        }
    }
    
    
    // MARK: Private Properties
    
    private var appearanceModeObserver: AnyCancellable?
    
    private var documentStyleObserver: AnyCancellable?
    private var styleListObserver: AnyCancellable?
    private weak var syntaxPopUpButton: NSPopUpButton?
    
    
    
    // MARK: -
    // MARK: Window Controller Methods
    
    /// prepare window
    override func windowDidLoad() {
        
        super.windowDidLoad()
        
        // -> It's set as false by default if the window controller was invoked from a storyboard.
        self.shouldCascadeWindows = true
        // -> Do not use "document" for autosave name because somehow windows forget the size with that name. (2018-09)
        self.windowFrameAutosaveName = "Document Window"
        
        // set window size
        let width = UserDefaults.standard[.windowWidth]
        let height = UserDefaults.standard[.windowHeight]
        if let window = self.window, width > 0 || height > 0 {
            let contentSize = NSSize(width: width >= window.minSize.width ? width : window.frame.width,
                                     height: height >= window.minSize.height ? height : window.frame.height)
            window.setContentSize(contentSize)
            (self.contentViewController as! WindowContentViewController).restoreAutosavingState()
        }
        
        // observe appearance setting change
        self.appearanceModeObserver = UserDefaults.standard.publisher(for: .documentAppearance, initial: true)
            .map { (value) in
                switch value {
                    case .default: return nil
                    case .light:   return NSAppearance(named: .aqua)
                    case .dark:    return NSAppearance(named: .darkAqua)
                }
            }
            .assign(to: \.appearance, on: self.window!)
        
        //  observe for syntax style line-up change
        self.styleListObserver = Publishers.Merge(SyntaxManager.shared.$settingNames.eraseToVoid(),
                                                  UserDefaults.standard.publisher(for: .recentStyleNames).eraseToVoid())
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.buildSyntaxPopUpButton() }
    }
    
    
    /// apply passed-in document instance to window
    override unowned(unsafe) var document: AnyObject? {
        
        didSet {
            guard let document = document as? Document else { return }
            
            self.contentViewController!.representedObject = document
            
            // -> In case when the window was created as a restored window (the right side ones in the browsing mode).
            if document.isInViewingMode {
                self.window?.isOpaque = true
            }
            
            self.window?.toolbar?.items.lazy.compactMap { $0 as? NSSharingServicePickerToolbarItem }.first?.delegate = document
            self.selectSyntaxPopUpItem(with: document.syntaxParser.style.name)
            
            // observe document's style change
            self.documentStyleObserver = document.didChangeSyntaxStyle
                .receive(on: RunLoop.main)
                .sink { [weak self] in self?.selectSyntaxPopUpItem(with: $0) }
        }
    }
    
    
    override func setDocumentEdited(_ dirtyFlag: Bool) {
        
        super.setDocumentEdited(self.isWhitepaper ? false : dirtyFlag)
    }
    
    
    
    // MARK: Window Delegate
    
    func window(_ window: NSWindow, willPositionSheet sheet: NSWindow, using rect: NSRect) -> NSRect {
        
        // remove "Use small size" button before showing the customization sheet
        if sheet.isToolbarConfigPanel {
            sheet.removeSmallSizeToolbarButton()
        }
        
        return rect
    }
    
    
    func windowWillEnterFullScreen(_ notification: Notification) {
        
        self.window?.isOpaque = true
    }
    
    
    func windowWillEnterVersionBrowser(_ notification: Notification) {
        
        self.window?.isOpaque = true
    }
    
    
    func windowWillExitFullScreen(_ notification: Notification) {
        
        self.restoreWindowOpacity()
    }
    
    
    func windowWillExitVersionBrowser(_ notification: Notification) {
        
        self.restoreWindowOpacity()
    }
    
    
    
    // MARK: Private Methods
    
    private func restoreWindowOpacity() {
        
        self.window?.isOpaque = (self.window as? DocumentWindow)?.backgroundAlpha == 1
    }
    
    
    /// Build syntax style popup menu in toolbar.
    private func buildSyntaxPopUpButton() {
        
        guard let menu = self.syntaxPopUpButton?.menu else { return }
        
        let styleNames = SyntaxManager.shared.settingNames
        let recentStyleNames = UserDefaults.standard[.recentStyleNames]
        let action = #selector(Document.changeSyntaxStyle)
        
        menu.removeAllItems()
        
        menu.addItem(withTitle: BundledStyleName.none, action: action, keyEquivalent: "")
        menu.addItem(.separator())
        
        if !recentStyleNames.isEmpty {
            let labelItem = NSMenuItem()
            labelItem.title = "Recently Used".localized(comment: "menu heading in syntax style list on toolbar popup")
            labelItem.isEnabled = false
            menu.addItem(labelItem)
            
            menu.items += recentStyleNames.map { NSMenuItem(title: $0, action: action, keyEquivalent: "") }
            menu.addItem(.separator())
        }
        
        menu.items += styleNames.map { NSMenuItem(title: $0, action: action, keyEquivalent: "") }
        
        if let styleName = (self.document as? Document)?.syntaxParser.style.name {
            self.selectSyntaxPopUpItem(with: styleName)
        }
    }
    
    
    private func selectSyntaxPopUpItem(with styleName: String) {
        
        guard let popUpButton = self.syntaxPopUpButton else { return }
        
        let deletedTag = -1
        
        // remove deleted items
        popUpButton.menu?.items.removeAll { $0.tag == deletedTag }
        
        // deselect current one
        popUpButton.selectItem(at: -1)
        
        if let item = popUpButton.item(withTitle: styleName) {
            popUpButton.select(item)
        
        } else {
            // insert item by adding deleted item section
            popUpButton.insertItem(withTitle: styleName, at: 1)
            popUpButton.item(at: 1)?.tag = deletedTag
            popUpButton.selectItem(at: 1)
            
            popUpButton.insertItem(withTitle: "Deleted".localized, at: 1)
            popUpButton.item(at: 1)?.tag = deletedTag
            popUpButton.item(at: 1)?.isEnabled = false
            
            popUpButton.menu?.insertItem(.separator(), at: 1)
            popUpButton.item(at: 1)?.tag = deletedTag
        }
    }
    
}



// MARK: - Toolbar

private extension NSToolbarItem.Identifier {
    
    private static let prefix = "com.coteditor.CotEditor.ToolbarItem."
    
    
    static let syntaxStyle = Self(Self.prefix + "syntaxStyle")
    static let inspector = Self(Self.prefix + "inspector")
    
    static let textSize = Self(Self.prefix + "textSize")
    static let writingDirection = Self(Self.prefix + "writingDirection")
    static let textOrientation = Self(Self.prefix + "textOrientation")
    
    static let indent = Self(Self.prefix + "indent")
    static let comment = Self(Self.prefix + "comment")
    
    static let tabStyle = Self(Self.prefix + "tabStyle")
    static let invisibles = Self(Self.prefix + "invisibles")
    static let wrapLines = Self(Self.prefix + "wrapLines")
    static let indentGuides = Self(Self.prefix + "indentGuildes")
    
    static let opacity = Self(Self.prefix + "opacity")
    static let spellCheck = Self(Self.prefix + "spellCheck")
    static let colorCode = Self(Self.prefix + "colorCode")
    static let emojiAndSymbols = Self(Self.prefix + "emojiAndSymbols")
    static let fonts = Self(Self.prefix + "fonts")
    static let find = Self(Self.prefix + "find")
    static let print = Self(Self.prefix + "print")
    static let share = Self(Self.prefix + "share")
    static let inspectorTrackingSeparator = Self(Self.prefix + "inspectorTrackingSeparator")
}


extension DocumentWindowController: NSToolbarDelegate {
    
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        
        return [
            .syntaxStyle,
            .inspectorTrackingSeparator,
            .inspector,
        ]
    }
    
    
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        
        return [
            .syntaxStyle,
            .inspector,
            .textSize,
            .writingDirection,
            .textOrientation,
            .indent,
            .comment,
            .tabStyle,
            .wrapLines,
            .invisibles,
            .indentGuides,
            .opacity,
            .spellCheck,
            .colorCode,
            .emojiAndSymbols,
            .fonts,
            .find,
            .print,
            .share,
            .space,
            .flexibleSpace,
        ]
    }
    
    
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        
        switch itemIdentifier {
            case .syntaxStyle:
                let popUpButton = NSPopUpButton()
                popUpButton.bezelStyle = .texturedRounded
                popUpButton.menu?.autoenablesItems = false
                self.syntaxPopUpButton = popUpButton
                self.buildSyntaxPopUpButton()
                
                let item = NSToolbarItem(itemIdentifier: itemIdentifier)
                item.label = "Syntax Style".localized
                item.toolTip = "Change syntax style".localized
                item.view = popUpButton
                item.visibilityPriority = .high
                
                let menuItem = NSMenuItem()
                menuItem.submenu = popUpButton.menu
                menuItem.title = item.label
                item.menuFormRepresentation = menuItem
                
                return item
                
            case .inspector:
                let item = NSToolbarItem(itemIdentifier: itemIdentifier)
                item.isBordered = true
                item.label = "Inspector".localized
                item.toolTip = "Show document information".localized
                item.image = NSImage(systemSymbolName: "info.circle", accessibilityDescription: item.label)
                item.action = #selector(WindowContentViewController.toggleInspector)
                item.visibilityPriority = .high
                return item
                
            case .textSize:
                let smallerItem = NSToolbarItem()
                smallerItem.label = "Smaller".localized
                smallerItem.toolTip = "Smaller".localized
                smallerItem.image = NSImage(systemSymbolName: "a", accessibilityDescription: smallerItem.label)!
                    .withSymbolConfiguration(.init(scale: .small))
                smallerItem.action = #selector(EditorTextView.smallerFont)
                
                let biggerItem = NSToolbarItem()
                biggerItem.label = "Bigger".localized
                biggerItem.toolTip = "Bigger".localized
                biggerItem.image = NSImage(systemSymbolName: "a", accessibilityDescription: biggerItem.label)!
                biggerItem.action = #selector(EditorTextView.biggerFont)
                
                let item = NSToolbarItemGroup(itemIdentifier: itemIdentifier)
                item.isBordered = true
                item.controlRepresentation = .expanded
                item.selectionMode = .momentary
                item.label = "Text Size".localized
                item.toolTip = "Change text size".localized
                item.subitems = [smallerItem, biggerItem]
                return item
                
            case .writingDirection:
                let ltrItem = NSToolbarItem()
                ltrItem.label = "Left to Right".localized
                ltrItem.toolTip = "Left to Right".localized
                ltrItem.image = NSImage(systemSymbolName: "text.alignleft", accessibilityDescription: ltrItem.label)
                ltrItem.action = #selector(DocumentViewController.makeWritingDirectionLeftToRight)
                
                let rtlItem = NSToolbarItem()
                rtlItem.label = "Right to Left".localized
                rtlItem.toolTip = "Right to Left".localized
                rtlItem.image = NSImage(systemSymbolName: "text.alignright", accessibilityDescription: rtlItem.label)
                rtlItem.action = #selector(DocumentViewController.makeWritingDirectionRightToLeft)
                
                let item = ToolbarItemGroup(itemIdentifier: itemIdentifier)
                item.isBordered = true
                item.controlRepresentation = .expanded
                item.selectionMode = .selectOne
                item.label = "Writing Direction".localized
                item.toolTip = "Change writing direction".localized
                item.action = #selector(DocumentViewController.changeWritingDirection)
                item.subitems = [ltrItem, rtlItem]
                return item
                
            case .textOrientation:
                let horizontalItem = NSToolbarItem()
                horizontalItem.label = "Horizontal".localized
                horizontalItem.toolTip = "Horizontal".localized
                horizontalItem.image = NSImage(systemSymbolName: "text.alignleft", accessibilityDescription: horizontalItem.label)
                horizontalItem.action = #selector(DocumentViewController.makeLayoutOrientationHorizontal)
                
                let verticalItem = NSToolbarItem()
                verticalItem.label = "Vertical".localized
                verticalItem.toolTip = "Vertical".localized
                verticalItem.image = NSImage(named: "text.verticalorientation")
                verticalItem.action = #selector(DocumentViewController.makeLayoutOrientationVertical)
                
                let item = ToolbarItemGroup(itemIdentifier: itemIdentifier)
                item.isBordered = true
                item.controlRepresentation = .expanded
                item.selectionMode = .selectOne
                item.label = "Text Orientation".localized
                item.toolTip = "Toggle text orientation".localized
                item.action = #selector(DocumentViewController.changeOrientation)
                item.subitems = [horizontalItem, verticalItem]
                return item
                
            case .indent:
                let leftItem = NSToolbarItem()
                leftItem.label = "Shift Left".localized
                leftItem.toolTip = "Shift lines to left".localized
                leftItem.image = NSImage(systemSymbolName: "increase.indent", accessibilityDescription: leftItem.label)
                leftItem.action = #selector(EditorTextView.shiftLeft)
                
                let rightItem = NSToolbarItem()
                rightItem.label = "Shift Right".localized
                rightItem.toolTip = "Shift lines to right".localized
                rightItem.image = NSImage(systemSymbolName: "decrease.indent", accessibilityDescription: rightItem.label)
                rightItem.action = #selector(EditorTextView.shiftRight)
                
                let item = NSToolbarItemGroup(itemIdentifier: itemIdentifier)
                item.isBordered = true
                item.controlRepresentation = .expanded
                item.selectionMode = .momentary
                item.label = "Indent".localized
                item.toolTip = "Indent selection".localized
                item.subitems = [leftItem, rightItem]
                return item
                
            case .comment:
                let item = NSToolbarItem(itemIdentifier: itemIdentifier)
                item.isBordered = true
                item.label = "Comment".localized
                item.toolTip = "Comment-out or uncomment selection".localized
                item.image = NSImage(named: "text.commentout")
                item.action = #selector(EditorTextView.toggleComment)
                return item
                
            case .tabStyle:
                let menu = NSMenu()
                menu.addItem(withTitle: "Tab Width".localized, action: nil, keyEquivalent: "")
                menu.items += [2, 3, 4, 8]
                    .map { (width) in
                        let item = NSMenuItem(title: String(width), action: #selector(DocumentViewController.changeTabWidth), keyEquivalent: "")
                        item.tag = width
                        return item
                    }
                menu.addItem(withTitle: "Custom…".localized, action: #selector(DocumentViewController.customizeTabWidth), keyEquivalent: "")
                
                let item = StatableMenuToolbarItem(itemIdentifier: itemIdentifier)
                item.label = "Tab Style".localized
                item.toolTip = "Expand tabs to spaces automatically".localized
                item.stateImages[.on] = NSImage(named: "tab.right.split")
                item.stateImages[.off] = NSImage(named: "tab.right")
                item.action = #selector(DocumentViewController.toggleAutoTabExpand)
                item.menu = menu
                
                return item
                
            case .wrapLines:
                let item = StatableToolbarItem(itemIdentifier: itemIdentifier)
                item.isBordered = true
                item.label = "Wrap Lines".localized
                item.toolTip = "Wrap lines".localized
                item.stateImages[.on] = NSImage(named: "text.unwrap")
                item.stateImages[.off] = NSImage(named: "text.wrap")
                item.action = #selector(DocumentViewController.toggleLineWrap)
                return item
                
            case .invisibles:
                let item = StatableToolbarItem(itemIdentifier: itemIdentifier)
                item.isBordered = true
                item.label = "Invisibles".localized
                item.toolTip = "Show invisible characters".localized
                item.stateImages[.on] = NSImage(named: "paragraphsign.slash")
                item.stateImages[.off] = NSImage(systemSymbolName: "paragraphsign", accessibilityDescription: item.label)
                item.action = #selector(DocumentViewController.toggleInvisibleChars)
                return item
                
            case .indentGuides:
                let item = StatableToolbarItem(itemIdentifier: itemIdentifier)
                item.isBordered = true
                item.label = "Indent Guides".localized
                item.toolTip = "Hide indent guide lines".localized
                item.stateImages[.on] = NSImage(named: "text.indentguides.hide")
                item.stateImages[.off] = NSImage(named: "text.indentguides")
                item.action = #selector(DocumentViewController.toggleIndentGuides)
                return item
                
            case .opacity:
                let opacityViewController = self.storyboard!.instantiateController(withIdentifier: "Opacity Slider") as! NSViewController
                opacityViewController.representedObject = self.window
                let menuItem = NSMenuItem()
                menuItem.view = opacityViewController.view
                menuItem.representedObject = opacityViewController
                
                let item = MenuToolbarItem(itemIdentifier: itemIdentifier)
                item.label = "Opacity".localized
                item.toolTip = "Change editor’s opacity".localized
                item.image = NSImage(named: "uiwindow.opacity")
                item.target = self
                item.showsIndicator = false
                item.menu = NSMenu()
                item.menu.items = [menuItem]
                return item
                
            case .spellCheck:
                let item = NSToolbarItem(itemIdentifier: itemIdentifier)
                item.isBordered = true
                item.label = "Spell Check".localized
                item.toolTip = "Show spelling and grammar".localized
                item.image = NSImage(named: "abc.checkmark")
                item.action = #selector(NSTextView.showGuessPanel)
                return item
                
            case .colorCode:
                let item = NSToolbarItem(itemIdentifier: itemIdentifier)
                item.isBordered = true
                item.label = "Color Code".localized
                item.toolTip = "Open Color Code Editor and set selection as color code".localized
                item.image = NSImage(systemSymbolName: "eyedropper.halffull", accessibilityDescription: item.label)
                item.action = #selector(EditorTextView.editColorCode)
                return item
                
            case .emojiAndSymbols:
                let item = NSToolbarItem(itemIdentifier: itemIdentifier)
                item.isBordered = true
                item.label = "Emoji & Symbols".localized
                item.toolTip = "Show Emoji & Symbols palette".localized
                item.image = NSImage(named: "emoji")
                item.action = #selector(NSApplication.orderFrontCharacterPalette)
                return item
                
            case .fonts:
                let item = NSToolbarItem(itemIdentifier: itemIdentifier)
                item.isBordered = true
                item.label = "Fonts".localized
                item.toolTip = "Show Font Panel".localized
                item.image = NSImage(systemSymbolName: "textformat", accessibilityDescription: item.label)
                item.action = #selector(NSFontManager.orderFrontFontPanel)
                return item
                
            case .find:
                let item = NSToolbarItem(itemIdentifier: itemIdentifier)
                item.isBordered = true
                item.label = "Find".localized
                item.toolTip = "Show “Find and Replace”".localized
                item.image = NSImage(systemSymbolName: "magnifyingglass", accessibilityDescription: item.label)
                item.action = #selector(TextFinder.showFindPanel)
                return item
                
            case .print:
                let item = NSToolbarItem(itemIdentifier: itemIdentifier)
                item.isBordered = true
                item.label = "Print".localized
                item.toolTip = "Print".localized
                item.image = NSImage(systemSymbolName: "printer", accessibilityDescription: item.label)
                item.action = #selector(NSDocument.printDocument)
                return item
                
            case .share:
                let item = NSSharingServicePickerToolbarItem(itemIdentifier: itemIdentifier)
                item.toolTip = "Share document file".localized
                item.delegate = self.document as? NSSharingServicePickerToolbarItemDelegate
                return item
                
            case .inspectorTrackingSeparator:
                guard let splitView = (self.contentViewController as? NSSplitViewController)?.splitView else { return nil }
                let item = NSTrackingSeparatorToolbarItem(identifier: itemIdentifier, splitView: splitView, dividerIndex: 0)
                return item
            
            default:
                return NSToolbarItem(itemIdentifier: itemIdentifier)
        }
    }
    
}


extension DocumentWindowController: NSToolbarItemValidation {
    
    func validateToolbarItem(_ item: NSToolbarItem) -> Bool {
        
        switch item.itemIdentifier {
            case .opacity:
                return self.window?.styleMask.contains(.fullScreen) == false
            default:
                return item.action == nil
        }
    }
    
}


extension NSDocument: NSSharingServicePickerToolbarItemDelegate {
    
    public func items(for pickerToolbarItem: NSSharingServicePickerToolbarItem) -> [Any] {
        
        return [self]
    }
    
}
