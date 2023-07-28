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
//  © 2013-2023 1024jp
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

final class DocumentWindowController: NSWindowController, NSWindowDelegate {
    
    // MARK: Public Properties
    
    var isWhitepaper = false {
        
        didSet {
            guard isWhitepaper || oldValue else { return }
            
            self.setDocumentEdited(!isWhitepaper)
        }
    }
    
    
    // MARK: Private Properties
    
    private static let windowFrameName = NSWindow.FrameAutosaveName("Document")
    
    private lazy var editedIndicator: NSView = {
        
        let dotView = DotView()
        dotView.color = .tertiaryLabelColor
        dotView.toolTip = String(localized: "Document has unsaved changes")
        dotView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return dotView
    }()
    
    private var opacityObserver: AnyCancellable?
    private var appearanceModeObserver: AnyCancellable?
    
    private var documentSyntaxObserver: AnyCancellable?
    private var syntaxListObserver: AnyCancellable?
    private weak var syntaxPopUpButton: NSPopUpButton?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    convenience init(document: Document) {
        
        let viewController: NSViewController? = NSStoryboard(name: "DocumentWindow")
            .instantiateInitialController()
        let window = DocumentWindow(contentViewController: viewController!)
        
        // set window size
        window.setFrameUsingName(Self.windowFrameName)
        let width = UserDefaults.standard[.windowWidth]
        let height = UserDefaults.standard[.windowHeight]
        if width > 0 || height > 0 {
            let frameSize = NSSize(width: width > window.minSize.width ? width : window.frame.width,
                                   height: height > window.minSize.height ? height : window.frame.height)
            window.setFrame(.init(origin: window.frame.origin, size: frameSize), display: false)
        }
        
        self.init(window: window)
        
        self.windowFrameAutosaveName = Self.windowFrameName
        
        window.delegate = self
        
        // setup toolbar
        let toolbar = NSToolbar(identifier: .document)
        toolbar.displayMode = .iconOnly
        toolbar.allowsUserCustomization = true
        toolbar.autosavesConfiguration = true
        toolbar.delegate = self
        window.toolbarStyle = .unified
        window.toolbar = toolbar
        
        // cascade window position
        // -> Perform after setting the toolbar.
        let cascadingPoint = NSApp.mainWindow?.cascadeTopLeft(from: .zero) ?? .zero
        window.cascadeTopLeft(from: cascadingPoint)
        
        // observe opacity setting change
        // -> Keep opaque when the window was created as a browsing window (the right side ones in the browsing mode).
        if !document.isInViewingMode {
            self.opacityObserver = UserDefaults.standard.publisher(for: .windowAlpha, initial: true)
                .assign(to: \.backgroundAlpha, on: window)
        }
        
        // observe appearance setting change
        self.appearanceModeObserver = UserDefaults.standard.publisher(for: .documentAppearance, initial: true)
            .map { (value) in
                switch value {
                    case .default: nil
                    case .light:   NSAppearance(named: .aqua)
                    case .dark:    NSAppearance(named: .darkAqua)
                }
            }
            .assign(to: \.appearance, on: window)
        
        //  observe for syntax line-up change
        self.syntaxListObserver = Publishers.Merge(SyntaxManager.shared.$settingNames,
                                                   UserDefaults.standard.publisher(for: .recentSyntaxNames))
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.buildSyntaxPopUpButton() }
    }
    
    
    
    // MARK: Window Controller Methods
    
    override unowned(unsafe) var document: AnyObject? {
        
        willSet {
            self.documentSyntaxObserver = nil
        }
        
        didSet {
            // deliver represented object to child view controllers
            for child in self.contentViewController!.children {
                child.representedObject = document
            }
            
            guard let document = document as? Document else { return }
            
            // observe document's syntax change
            self.documentSyntaxObserver = document.didChangeSyntax
                .merge(with: Just(document.syntaxParser.syntax.name))
                .receive(on: RunLoop.main)
                .sink { [weak self] in self?.selectSyntaxPopUpItem(with: $0) }
        }
    }
    
    
    override func setDocumentEdited(_ dirtyFlag: Bool) {
        
        self.window?.tab.accessoryView = dirtyFlag ? self.editedIndicator : nil
        
        super.setDocumentEdited(self.isWhitepaper ? false : dirtyFlag)
    }
    
    
    
    // MARK: Window Delegate
    
    func windowDidResize(_ notification: Notification) {
        
        guard self.isWindowLoaded, let window = self.window else { return }
        
        // workaround issue that window frame is not saved automatically (2022-08 macOS 12.5, FB11082729)
        window.saveFrame(usingName: self.windowFrameAutosaveName)
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
    
    
    /// Build syntax popup menu in toolbar.
    private func buildSyntaxPopUpButton() {
        
        guard let menu = self.syntaxPopUpButton?.menu else { return }
        
        let syntaxNames = SyntaxManager.shared.settingNames
        let recentSyntaxNames = UserDefaults.standard[.recentSyntaxNames]
        let action = #selector(Document.changeSyntax)
        
        menu.removeAllItems()
        
        menu.addItem(withTitle: BundledSyntaxName.none, action: action, keyEquivalent: "")
        menu.addItem(.separator())
        
        if !recentSyntaxNames.isEmpty {
            let title = String(localized: "Recently Used", comment: "menu heading in syntax list on toolbar popup")
            menu.addItem(.sectionHeader(title: title))
            
            menu.items += recentSyntaxNames.map { NSMenuItem(title: $0, action: action, keyEquivalent: "") }
            menu.addItem(.separator())
        }
        
        menu.items += syntaxNames.map { NSMenuItem(title: $0, action: action, keyEquivalent: "") }
        
        if let syntaxName = (self.document as? Document)?.syntaxParser.syntax.name {
            self.selectSyntaxPopUpItem(with: syntaxName)
        }
    }
    
    
    private func selectSyntaxPopUpItem(with syntaxName: String) {
        
        guard
            let popUpButton = self.syntaxPopUpButton,
            let menu = popUpButton.menu
        else { return }
        
        let deletedTag = -1
        
        // remove deleted items
        menu.items.removeAll { $0.tag == deletedTag }
        
        // deselect current one
        popUpButton.selectItem(at: -1)
        
        if let item = popUpButton.item(withTitle: syntaxName) {
            popUpButton.select(item)
            
        } else {
            // insert item by adding Deleted item section
            menu.insertItem(NSMenuItem(title: syntaxName, action: nil, keyEquivalent: ""), at: 1)
            menu.item(at: 1)?.tag = deletedTag
            popUpButton.selectItem(at: 1)
            
            menu.insertItem(.sectionHeader(title: String(localized: "Deleted")), at: 1)
            menu.item(at: 1)?.tag = deletedTag
            
            menu.insertItem(.separator(), at: 1)
            menu.item(at: 1)?.tag = deletedTag
        }
    }
}



// MARK: - Toolbar

private extension NSToolbar.Identifier {
    
    static let document = Self("7E7590E9-43BC-40F7-B967-07FA2780E47B")
}


private extension NSToolbarItem.Identifier {
    
    private static let prefix = "com.coteditor.CotEditor.ToolbarItem."
    
    
    static let syntax = Self(Self.prefix + "syntaxStyle")
    static let inspector = Self(Self.prefix + "inspector")
    
    static let textSize = Self(Self.prefix + "textSize")
    static let smaller = Self(Self.prefix + "smaller")
    static let bigger = Self(Self.prefix + "bigger")
    
    static let writingDirection = Self(Self.prefix + "writingDirection")
    static let leftToRight = Self(Self.prefix + "leftToRight")
    static let rightToLeft = Self(Self.prefix + "rightToLeft")
    
    static let textOrientation = Self(Self.prefix + "textOrientation")
    static let horizontalText = Self(Self.prefix + "horizontalText")
    static let verticalText = Self(Self.prefix + "verticalText")
    
    static let indent = Self(Self.prefix + "indent")
    static let shiftLeft = Self(Self.prefix + "shiftLeft")
    static let shiftRight = Self(Self.prefix + "shiftRight")
    
    static let comment = Self(Self.prefix + "comment")
    
    static let tabStyle = Self(Self.prefix + "tabStyle")
    static let invisibles = Self(Self.prefix + "invisibles")
    static let wrapLines = Self(Self.prefix + "wrapLines")
    static let indentGuides = Self(Self.prefix + "indentGuides")
    
    static let keepOnTop = Self(Self.prefix + "keepOnTop")
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
        
        [
            .syntax,
            .inspectorTrackingSeparator,
            .inspector,
        ]
    }
    
    
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        
        [
            .syntax,
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
            .keepOnTop,
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
            case .syntax:
                let popUpButton = NSPopUpButton()
                popUpButton.bezelStyle = .texturedRounded
                popUpButton.menu?.autoenablesItems = false
                self.syntaxPopUpButton = popUpButton
                self.buildSyntaxPopUpButton()
                
                let item = NSToolbarItem(itemIdentifier: itemIdentifier)
                item.label = String(localized: "Syntax")
                item.toolTip = String(localized: "Change syntax")
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
                item.label = String(localized: "Inspector")
                item.toolTip = String(localized: "Show document information")
                item.image = NSImage(systemSymbolName: "info.circle", accessibilityDescription: item.label)
                item.action = #selector(WindowContentViewController.toggleInspector)
                item.visibilityPriority = .high
                return item
                
            case .textSize:
                let smallerItem = NSToolbarItem(itemIdentifier: .smaller)
                smallerItem.label = String(localized: "Smaller")
                smallerItem.toolTip = String(localized: "Smaller")
                smallerItem.image = NSImage(systemSymbolName: "textformat.size.smaller", accessibilityDescription: smallerItem.label)!
                smallerItem.action = #selector(EditorTextView.smallerFont)
                
                let biggerItem = NSToolbarItem(itemIdentifier: .bigger)
                biggerItem.label = String(localized: "Bigger")
                biggerItem.toolTip = String(localized: "Bigger")
                biggerItem.image = NSImage(systemSymbolName: "textformat.size.larger", accessibilityDescription: biggerItem.label)!
                biggerItem.action = #selector(EditorTextView.biggerFont)
                
                let item = NSToolbarItemGroup(itemIdentifier: itemIdentifier)
                item.isBordered = true
                item.controlRepresentation = .expanded
                item.selectionMode = .momentary
                item.label = String(localized: "Text Size")
                item.toolTip = String(localized: "Change text size")
                item.subitems = [smallerItem, biggerItem]
                return item
                
            case .writingDirection:
                let ltrItem = NSToolbarItem(itemIdentifier: .leftToRight)
                ltrItem.label = String(localized: "Left to Right")
                ltrItem.toolTip = String(localized: "Left to Right")
                ltrItem.image = NSImage(systemSymbolName: "text.alignleft", accessibilityDescription: ltrItem.label)
                ltrItem.action = #selector(DocumentViewController.makeWritingDirectionLeftToRight)
                
                let rtlItem = NSToolbarItem(itemIdentifier: .rightToLeft)
                rtlItem.label = String(localized: "Right to Left")
                rtlItem.toolTip = String(localized: "Right to Left")
                rtlItem.image = NSImage(systemSymbolName: "text.alignright", accessibilityDescription: rtlItem.label)
                rtlItem.action = #selector(DocumentViewController.makeWritingDirectionRightToLeft)
                
                let item = ToolbarItemGroup(itemIdentifier: itemIdentifier)
                item.isBordered = true
                item.controlRepresentation = .expanded
                item.selectionMode = .selectOne
                item.label = String(localized: "Writing Direction")
                item.toolTip = String(localized: "Change writing direction")
                item.action = #selector(DocumentViewController.changeWritingDirection)
                item.subitems = [ltrItem, rtlItem]
                return item
                
            case .textOrientation:
                let horizontalItem = NSToolbarItem(itemIdentifier: .horizontalText)
                horizontalItem.label = String(localized: "Horizontal")
                horizontalItem.toolTip = String(localized: "Horizontal")
                horizontalItem.image = NSImage(systemSymbolName: "text.alignleft", accessibilityDescription: horizontalItem.label)
                horizontalItem.action = #selector(DocumentViewController.makeLayoutOrientationHorizontal)
                
                let verticalItem = NSToolbarItem(itemIdentifier: .verticalText)
                verticalItem.label = String(localized: "Vertical")
                verticalItem.toolTip = String(localized: "Vertical")
                verticalItem.image = NSImage(systemSymbolName: "text.verticalorientation", accessibilityDescription: verticalItem.label)
                verticalItem.action = #selector(DocumentViewController.makeLayoutOrientationVertical)
                
                let item = ToolbarItemGroup(itemIdentifier: itemIdentifier)
                item.isBordered = true
                item.controlRepresentation = .expanded
                item.selectionMode = .selectOne
                item.label = String(localized: "Text Orientation")
                item.toolTip = String(localized: "Switch text orientation")
                item.action = #selector(DocumentViewController.changeOrientation)
                item.subitems = [horizontalItem, verticalItem]
                return item
                
            case .indent:
                let leftItem = NSToolbarItem(itemIdentifier: .shiftLeft)
                leftItem.label = String(localized: "Shift Left")
                leftItem.toolTip = String(localized: "Shift lines to left")
                leftItem.image = NSImage(systemSymbolName: "decrease.indent", accessibilityDescription: leftItem.label)
                leftItem.action = #selector(EditorTextView.shiftLeft)
                
                let rightItem = NSToolbarItem(itemIdentifier: .shiftRight)
                rightItem.label = String(localized: "Shift Right")
                rightItem.toolTip = String(localized: "Shift lines to right")
                rightItem.image = NSImage(systemSymbolName: "increase.indent", accessibilityDescription: rightItem.label)
                rightItem.action = #selector(EditorTextView.shiftRight)
                
                let item = NSToolbarItemGroup(itemIdentifier: itemIdentifier)
                item.isBordered = true
                item.controlRepresentation = .expanded
                item.selectionMode = .momentary
                item.label = String(localized: "Indent")
                item.toolTip = String(localized: "Indent selection")
                item.subitems = [leftItem, rightItem]
                return item
                
            case .comment:
                let item = NSToolbarItem(itemIdentifier: itemIdentifier)
                item.isBordered = true
                item.label = String(localized: "Comment")
                item.toolTip = String(localized: "Comment-out or uncomment selection")
                item.image = NSImage(resource: .textCommentout)
                item.action = #selector(EditorTextView.toggleComment)
                return item
                
            case .tabStyle:
                let menu = NSMenu()
                menu.addItem(.sectionHeader(title: String(localized: "Tab Width")))
                menu.items += [2, 3, 4, 8]
                    .map { (width) in
                        let item = NSMenuItem(title: width.formatted(), action: #selector(DocumentViewController.changeTabWidth), keyEquivalent: "")
                        item.tag = width
                        return item
                    }
                menu.addItem(withTitle: String(localized: "Custom…"), action: #selector(DocumentViewController.customizeTabWidth), keyEquivalent: "")
                menu.addItem(.separator())
                menu.addItem(withTitle: String(localized: "Expand to Spaces Automatically"), action: #selector(DocumentViewController.toggleAutoTabExpand), keyEquivalent: "")
                
                let item = StatableMenuToolbarItem(itemIdentifier: itemIdentifier)
                item.label = String(localized: "Tab Style")
                item.toolTip = String(localized: "Expand tabs to spaces automatically")
                item.stateImages[.on] = NSImage(resource: .tabRightSplit)
                item.stateImages[.off] = NSImage(resource: .tabRight)
                item.action = #selector(DocumentViewController.toggleAutoTabExpand)
                item.menu = menu
                item.menuFormRepresentation = NSMenuItem(title: item.label, action: #selector(DocumentViewController.changeTabWidth), keyEquivalent: "")
                
                return item
                
            case .wrapLines:
                let item = StatableToolbarItem(itemIdentifier: itemIdentifier)
                item.isBordered = true
                item.label = String(localized: "Wrap Lines")
                item.possibleLabels = [String(localized: "Wrap Lines"),
                                       String(localized: "Unwrap Lines")]
                item.toolTip = String(localized: "Wrap lines")
                item.stateImages[.on] = NSImage(resource: .textWrapSlash)
                item.stateImages[.off] = NSImage(resource: .textWrap)
                item.action = #selector(DocumentViewController.toggleLineWrap)
                item.menuFormRepresentation = NSMenuItem(title: item.label, action: item.action, keyEquivalent: "")
                return item
                
            case .invisibles:
                let item = StatableToolbarItem(itemIdentifier: itemIdentifier)
                item.isBordered = true
                item.label = String(localized: "Invisibles")
                item.toolTip = String(localized: "Show invisible characters")
                item.stateImages[.on] = NSImage(resource: .paragraphsignSlash)
                item.stateImages[.off] = NSImage(systemSymbolName: "paragraphsign", accessibilityDescription: item.label)
                item.action = #selector(DocumentViewController.toggleInvisibleChars)
                item.menuFormRepresentation = NSMenuItem(title: item.label, action: item.action, keyEquivalent: "")
                return item
                
            case .indentGuides:
                let item = StatableToolbarItem(itemIdentifier: itemIdentifier)
                item.isBordered = true
                item.label = String(localized: "Indent Guides")
                item.toolTip = String(localized: "Hide indent guide lines")
                item.stateImages[.on] = NSImage(resource: .textIndentguidesHide)
                
                item.stateImages[.off] = NSImage(resource: .textIndentguides)
                item.action = #selector(DocumentViewController.toggleIndentGuides)
                item.menuFormRepresentation = NSMenuItem(title: item.label, action: item.action, keyEquivalent: "")
                return item
                
            case .keepOnTop:
                let item = StatableToolbarItem(itemIdentifier: itemIdentifier)
                item.isBordered = true
                item.label = String(localized: "Keep on Top")
                item.toolTip = String(localized: "Keep the window always on top")
                item.stateImages[.on] = NSImage(systemSymbolName: "pin.slash", accessibilityDescription: item.label)
                item.stateImages[.off] = NSImage(systemSymbolName: "pin", accessibilityDescription: item.label)
                item.action = #selector(DocumentWindow.toggleKeepOnTop)
                return item
                
            case .opacity:
                guard #available(macOS 14, *) else {
                    let menuItem = NSMenuItem()
                    menuItem.view = OpacityHostingView(window: self.window as? DocumentWindow)
                    let item = MenuToolbarItem(itemIdentifier: itemIdentifier)
                    item.label = String(localized: "Opacity")
                    item.toolTip = String(localized: "Change editor’s opacity")
                    item.image = NSImage(resource: .uiwindowOpacity)
                    item.target = self
                    item.showsIndicator = false
                    item.menu = NSMenu()
                    item.menu.items = [menuItem]
                    return item
                }
                let item = NSToolbarItem(itemIdentifier: itemIdentifier)
                item.isBordered = true
                item.label = String(localized: "Opacity")
                item.toolTip = String(localized: "Change editor’s opacity")
                item.image = NSImage(resource: .uiwindowOpacity)
                item.action = #selector(DocumentViewController.showOpacitySlider)
                return item
                
            case .spellCheck:
                let item = NSToolbarItem(itemIdentifier: itemIdentifier)
                item.isBordered = true
                item.label = String(localized: "Spell Check")
                item.toolTip = String(localized: "Show spelling and grammar")
                item.image = NSImage(resource: .abcCheckmark)
                item.action = #selector(NSTextView.showGuessPanel)
                return item
                
            case .colorCode:
                let item = NSToolbarItem(itemIdentifier: itemIdentifier)
                item.isBordered = true
                item.label = String(localized: "Color Code")
                item.toolTip = String(localized: "Open Color Code Editor and set selection as color code")
                item.image = NSImage(systemSymbolName: "eyedropper.halffull", accessibilityDescription: item.label)
                item.action = #selector(EditorTextView.editColorCode)
                return item
                
            case .emojiAndSymbols:
                let item = NSToolbarItem(itemIdentifier: itemIdentifier)
                item.isBordered = true
                item.label = String(localized: "Emoji & Symbols")
                item.toolTip = String(localized: "Show Emoji & Symbols palette")
                item.image = NSImage(resource: .emoji)
                item.action = #selector(NSApplication.orderFrontCharacterPalette)
                return item
                
            case .fonts:
                let item = NSToolbarItem(itemIdentifier: itemIdentifier)
                item.isBordered = true
                item.label = String(localized: "Fonts")
                item.toolTip = String(localized: "Show Fonts")
                item.image = NSImage(systemSymbolName: "textformat", accessibilityDescription: item.label)
                item.action = #selector(NSFontManager.orderFrontFontPanel)
                return item
                
            case .find:
                let item = NSToolbarItem(itemIdentifier: itemIdentifier)
                item.isBordered = true
                item.label = String(localized: "Find")
                item.toolTip = String(localized: "Show Find & Replace")
                item.image = NSImage(systemSymbolName: "magnifyingglass", accessibilityDescription: item.label)
                item.action = #selector(performTextFinderAction)
                item.tag = TextFinder.Action.showFindInterface.rawValue
                return item
                
            case .print:
                let item = NSToolbarItem(itemIdentifier: itemIdentifier)
                item.isBordered = true
                item.label = String(localized: "Print")
                item.toolTip = String(localized: "Print")
                item.image = NSImage(systemSymbolName: "printer", accessibilityDescription: item.label)
                item.action = #selector(NSDocument.printDocument)
                return item
                
            case .share:
                let item = NSSharingServicePickerToolbarItem(itemIdentifier: itemIdentifier)
                item.toolTip = String(localized: "Share document file")
                item.delegate = self
                return item
                
            case .inspectorTrackingSeparator:
                let splitView = (self.contentViewController as! NSSplitViewController).splitView
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


extension DocumentWindowController: NSSharingServicePickerToolbarItemDelegate {
    
    public func items(for pickerToolbarItem: NSSharingServicePickerToolbarItem) -> [Any] {
        
        guard let document = self.document else { return [] }
        
        return [document]
    }
}
