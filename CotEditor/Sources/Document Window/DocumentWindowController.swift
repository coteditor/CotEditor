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
//  © 2013-2024 1024jp
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
import ControlUI
import URLUtils

final class DocumentWindowController: NSWindowController, NSWindowDelegate {
    
    // MARK: Public Properties
    
    var isWhitePaper = false {
        
        didSet {
            guard isWhitePaper || oldValue else { return }
            
            self.setDocumentEdited(!isWhitePaper)
        }
    }
    
    
    weak var fileDocument: DataDocument? {
        
        didSet {
            self.updateDocument(fileDocument)
        }
    }
    
    
    // MARK: Private Properties
    
    private var directoryDocument: DirectoryDocument?
    private var isDirectoryDocument: Bool
    
    private var windowAutosaveName: NSWindow.FrameAutosaveName
    private var needsManualOnAppear = false
    
    private lazy var editedIndicator: NSView = NSHostingView(rootView: Circle()
        .fill(.tertiary)
        .frame(width: 4, height: 4)
        .padding(8)
        .help(String(localized: "Document has unsaved changes",
                     table: "Document",
                     comment: "tooltip for the “edited” indicator in the window tab"))
    )
    
    private var opacityObserver: AnyCancellable?
    private var appearanceModeObserver: AnyCancellable?
    private var fileDocumentNameObserver: AnyCancellable?
    
    private var documentSyntaxObserver: AnyCancellable?
    private var syntaxListObserver: AnyCancellable?
    private weak var syntaxPopUpButton: NSPopUpButton?
    
    
    
    // MARK: Lifecycle
    
    required init(document: DataDocument? = nil, directoryDocument: DirectoryDocument? = nil) {
        
        assert(document != nil || directoryDocument != nil)
        
        self.fileDocument = document
        self.directoryDocument = directoryDocument
        self.isDirectoryDocument = (directoryDocument != nil)
        
        // store own autosave name
        // -> `NSWindowController.windowFrameAutosaveName` doesn't work
        //    if multiple window instances have the same name (2024-10, macOS 15).
        self.windowAutosaveName = self.isDirectoryDocument ? "DirectoryDocument": "Document"
        
        let window = DocumentWindow(contentViewController: WindowContentViewController(document: document, directoryDocument: directoryDocument))
        window.styleMask.update(with: .fullSizeContentView)
        window.animationBehavior = .documentWindow
        window.setFrameAutosaveName(self.windowAutosaveName)
        
        if self.isDirectoryDocument {
            window.tabbingMode = .disallowed
        }
        
        // set window size
        let width = UserDefaults.standard[.windowWidth] ?? 0
        let height = UserDefaults.standard[.windowHeight] ?? 0
        if width > 0 || height > 0 {
            let frameSize = NSSize(width: width > window.minSize.width ? width : window.frame.width,
                                   height: height > window.minSize.height ? height : window.frame.height)
            window.setFrame(NSRect(origin: window.frame.origin, size: frameSize), display: false)
        }
        
        super.init(window: window)
        
        self.updateDocument(document)
        
        window.delegate = self
        
        // setup toolbar
        let toolbar = NSToolbar(identifier: self.isDirectoryDocument ? .directoryDocument : .document)
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
        if document?.isInViewingMode != true {
            self.opacityObserver = UserDefaults.standard.publisher(for: .windowAlpha, initial: true)
                .assign(to: \.backgroundAlpha, on: window)
        }
        
        // observe appearance setting change
        self.appearanceModeObserver = UserDefaults.standard.publisher(for: .documentAppearance, initial: true)
            .map { value in
                switch value {
                    case .default: nil
                    case .light: NSAppearance(named: .aqua)
                    case .dark: NSAppearance(named: .darkAqua)
                }
            }
            .assign(to: \.appearance, on: window)
        
        // observe for syntax line-up change
        self.syntaxListObserver = Publishers.Merge(SyntaxManager.shared.$settingNames,
                                                   UserDefaults.standard.publisher(for: .recentSyntaxNames))
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.buildSyntaxPopUpButton() }
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    // MARK: Window Controller Methods
    
    override unowned(unsafe) var document: AnyObject? {
        
        didSet {
            self.documentSyntaxObserver = nil
            if let document = document as? DataDocument {
                self.updateDocument(document)
            }
        }
    }
    
    
    override func setDocumentEdited(_ dirtyFlag: Bool) {
        
        self.window?.tab.accessoryView = dirtyFlag ? self.editedIndicator : nil
        
        super.setDocumentEdited(self.isWhitePaper ? false : dirtyFlag)
    }
    
    
    override func synchronizeWindowTitleWithDocumentName() {
        
        super.synchronizeWindowTitleWithDocumentName()
        
        if self.isDirectoryDocument {
            // display current document title as window subtitle
            self.window?.subtitle = self.fileDocument?.fileURL?.lastPathComponent
                ?? self.fileDocument?.displayName
                ?? ""
        }
    }
    
    
    
    // MARK: Window Delegate
    
    func windowDidResize(_ notification: Notification) {
        
        self.saveWindowFrame()
    }
    
    
    func windowDidMove(_ notification: Notification) {
        
        self.saveWindowFrame()
    }
    
    
    func windowWillMiniaturize(_ notification: Notification) {
        
        // Workaround issue `viewWillAppear()` and `viewDidAppear()` are not invoked
        // on de-miniaturization when the window was initially miniaturized (2024-10, macOS 15, FB15331763)
        if self.window?.isVisible == false {
            self.needsManualOnAppear = true
        }
    }
    
    
    func windowDidDeminiaturize(_ notification: Notification) {
        
        if self.needsManualOnAppear {
            self.contentViewController?.performOnAppearProcedure()
            self.needsManualOnAppear = false
        }
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
    
    /// Updates document by passing it to the content view controller and updating the observation.
    ///
    /// - Parameter document: The new document.
    private func updateDocument(_ document: DataDocument?) {
        
        if let viewController = self.contentViewController as? WindowContentViewController, viewController.document != document {
            viewController.document = document
        }
        
        self.fileDocumentNameObserver = nil
        if self.isDirectoryDocument {
            self.fileDocumentNameObserver = document?.publisher(for: \.fileURL, options: .initial)
                .sink { [weak self] _ in self?.synchronizeWindowTitleWithDocumentName() }
        }
        
        self.synchronizeWindowTitleWithDocumentName()
        
        self.syntaxPopUpButton?.isEnabled = (document is Document)
        
        // observe document's syntax change for toolbar
        self.documentSyntaxObserver = nil
        if let document = document as? Document {
            self.documentSyntaxObserver = document.didChangeSyntax
                .merge(with: Just(document.syntaxParser.name))
                .sink { [weak self] in self?.selectSyntaxPopUpItem(with: $0) }
        }
    }
    
    
    /// Saves the current window frame.
    ///
    /// Workaround the issue that window frame is not saved automatically.
    private func saveWindowFrame() {
        
        assert(self.isWindowLoaded)
        
        self.window?.saveFrame(usingName: self.windowAutosaveName)
    }
    
    
    /// Restores the window opacity.
    private func restoreWindowOpacity() {
        
        self.window?.isOpaque = (self.window as? DocumentWindow)?.backgroundAlpha == 1
    }
    
    
    /// Builds syntax popup menu in toolbar.
    private func buildSyntaxPopUpButton() {
        
        guard let menu = self.syntaxPopUpButton?.menu else { return }
        
        let syntaxNames = SyntaxManager.shared.settingNames
        let recentSyntaxNames = UserDefaults.standard[.recentSyntaxNames]
        let action = #selector(Document.changeSyntax)
        
        menu.removeAllItems()
        
        let noneItem = NSMenuItem(title: String(localized: "SyntaxName.none", defaultValue: "None"), action: #selector((any SyntaxChanging).changeSyntax), keyEquivalent: "")
        noneItem.representedObject = SyntaxName.none
        
        menu.addItem(noneItem)
        menu.addItem(.separator())
        
        if !recentSyntaxNames.isEmpty {
            let title = String(localized: "Toolbar.syntax.menu.recentlyUsed.label",
                               defaultValue: "Recently Used", table: "Document", comment: "menu item header")
            menu.addItem(.sectionHeader(title: title))
            
            menu.items += recentSyntaxNames.map {
                let item = NSMenuItem(title: $0, action: action, keyEquivalent: "")
                item.representedObject = $0
                return item
            }
            menu.addItem(.separator())
        }
        
        menu.items += syntaxNames.map {
            let item = NSMenuItem(title: $0, action: action, keyEquivalent: "")
            item.representedObject = $0
            return item
        }
        
        if let document = self.fileDocument as? Document {
            self.selectSyntaxPopUpItem(with: document.syntaxParser.name)
        }
    }
    
    
    /// Selects the given syntax in the syntax pop-up button for the toolbar.
    ///
    /// - Parameter syntaxName: The name of the syntax to select.
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
        
        let index = popUpButton.indexOfItem(withRepresentedObject: syntaxName)
        if index >= 0 {
            popUpButton.selectItem(at: index)
            
        } else {
            // insert item by adding Deleted item section
            menu.insertItem(NSMenuItem(title: syntaxName, action: nil, keyEquivalent: ""), at: 1)
            menu.item(at: 1)?.tag = deletedTag
            popUpButton.selectItem(at: 1)
            
            menu.insertItem(.sectionHeader(title: String(localized: "Toolbar.syntax.menu.deleted.label",
                                                         defaultValue: "Deleted", table: "Document", comment: "menu item header")), at: 1)
            menu.item(at: 1)?.tag = deletedTag
            
            menu.insertItem(.separator(), at: 1)
            menu.item(at: 1)?.tag = deletedTag
        }
    }
}


private extension NSViewController {
    
    /// Recursively invokes `viewWillAppear()` and `viewDidAppear()`.
    ///
    /// Workaround the issue `viewWillAppear()` and `viewDidAppear()` are not invoked
    /// on de-miniaturization when the window was initially miniaturized (2024-10, macOS 15, FB15331763).
    func performOnAppearProcedure() {
        
        guard self.isViewShown else { return }
        
        self.viewWillAppear()
        self.viewDidAppear()
        
        for child in self.children {
            child.performOnAppearProcedure()
        }
    }
}


// MARK: - Toolbar

private extension NSToolbar.Identifier {
    
    static let document = Self("Document")
    static let directoryDocument = Self("DirectoryDocument")
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
    static let emojiAndSymbols = Self(Self.prefix + "emojiAndSymbols")
    static let fonts = Self(Self.prefix + "fonts")
    static let find = Self(Self.prefix + "find")
    static let print = Self(Self.prefix + "print")
    static let share = Self(Self.prefix + "share")
}


extension DocumentWindowController: NSToolbarDelegate {
    
    private var directoryIdentifiers: [NSToolbarItem.Identifier] {
        
        self.isDirectoryDocument ? [
            .toggleSidebar,
            .sidebarTrackingSeparator,
        ] : []
    }
    
    
    func toolbarImmovableItemIdentifiers(_ toolbar: NSToolbar) -> Set<NSToolbarItem.Identifier> {
        
        Set(self.directoryIdentifiers).union([
            .inspectorTrackingSeparator,
            .flexibleSpace,
            .inspector,
        ])
    }
    
    
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        
        self.directoryIdentifiers + [
            .syntax,
            .inspectorTrackingSeparator,
            .flexibleSpace,
            .inspector,
        ]
    }
    
    
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        
        var identifiers = self.directoryIdentifiers + [
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
            .emojiAndSymbols,
            .fonts,
            .find,
            .print,
            .share,
            .space,
            .flexibleSpace,
        ]
        
        if #available(macOS 15.2, *), NSWritingToolsCoordinator.isWritingToolsAvailable {
            identifiers.insert(.writingToolsItemIdentifier, at: identifiers.count - 3)
        }
        
        return identifiers
    }
    
    
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        
        switch itemIdentifier {
            case .toggleSidebar:
                let item = NSToolbarItem(itemIdentifier: itemIdentifier)
                item.autovalidates = true
                return item
                
            case .syntax:
                let popUpButton = NSPopUpButton()
                popUpButton.bezelStyle = .toolbar
                popUpButton.isEnabled = false  // enable later
                self.syntaxPopUpButton = popUpButton
                self.buildSyntaxPopUpButton()
                
                let item = NSToolbarItem(itemIdentifier: itemIdentifier)
                item.label = String(localized: "Toolbar.syntax.label",
                                    defaultValue: "Syntax", table: "Document")
                item.toolTip = String(localized: "Toolbar.syntax.tooltip",
                                      defaultValue: "Change syntax", table: "Document")
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
                item.label = String(localized: "Toolbar.inspector.label",
                                    defaultValue: "Inspector", table: "Document")
                item.toolTip = String(localized: "Toolbar.inspector.tooltip",
                                      defaultValue: "Show document information", table: "Document")
                item.image = NSImage(systemSymbolName: "info.circle", accessibilityDescription: item.label)
                item.action = #selector(NSSplitViewController.toggleInspector)
                item.visibilityPriority = .high
                return item
                
            case .textSize:
                let smallerItem = NSToolbarItem(itemIdentifier: .smaller)
                smallerItem.label = String(localized: "Toolbar.textSize.smaller.label",
                                           defaultValue: "Smaller", table: "Document")
                smallerItem.toolTip = String(localized: "Toolbar.textSize.smaller.tooltip",
                                             defaultValue: "Decrease text size", table: "Document")
                smallerItem.image = NSImage(systemSymbolName: "textformat.size.smaller", accessibilityDescription: smallerItem.label)!
                smallerItem.action = #selector(EditorTextView.smallerFont)
                
                let biggerItem = NSToolbarItem(itemIdentifier: .bigger)
                biggerItem.label = String(localized: "Toolbar.textSize.bigger.label",
                                          defaultValue: "Bigger", table: "Document")
                biggerItem.toolTip = String(localized: "Toolbar.textSize.small.tooltip",
                                            defaultValue: "Increase text size", table: "Document")
                biggerItem.image = NSImage(systemSymbolName: "textformat.size.larger", accessibilityDescription: biggerItem.label)!
                biggerItem.action = #selector(EditorTextView.biggerFont)
                
                let item = NSToolbarItemGroup(itemIdentifier: itemIdentifier)
                item.isBordered = true
                item.controlRepresentation = .expanded
                item.selectionMode = .momentary
                item.label = String(localized: "Toolbar.textSize.label",
                                    defaultValue: "Text Size", table: "Document")
                item.toolTip = String(localized: "Toolbar.textSize.tooltip",
                                      defaultValue: "Change text size", table: "Document")
                item.subitems = [smallerItem, biggerItem]
                return item
                
            case .writingDirection:
                let ltrItem = NSToolbarItem(itemIdentifier: .leftToRight)
                ltrItem.label = String(localized: "Toolbar.writingDirection.leftToRight.label",
                                       defaultValue: "Left to Right", table: "Document")
                ltrItem.toolTip = String(localized: "Toolbar.writingDirection.leftToRight.tooltip",
                                         defaultValue: "Left to right", table: "Document")
                ltrItem.image = NSImage(systemSymbolName: "text.alignleft", accessibilityDescription: ltrItem.label)
                ltrItem.action = #selector(DocumentViewController.makeWritingDirectionLeftToRight)
                
                let rtlItem = NSToolbarItem(itemIdentifier: .rightToLeft)
                rtlItem.label = String(localized: "Toolbar.writingDirection.rightToLeft.label",
                                       defaultValue: "Right to Left", table: "Document")
                rtlItem.toolTip = String(localized: "Toolbar.writingDirection.rightToLeft.tooltip",
                                         defaultValue: "Right to left", table: "Document")
                rtlItem.image = NSImage(systemSymbolName: "text.alignright", accessibilityDescription: rtlItem.label)
                rtlItem.action = #selector(DocumentViewController.makeWritingDirectionRightToLeft)
                
                let item = NSToolbarItemGroup(itemIdentifier: itemIdentifier)
                item.isBordered = true
                item.controlRepresentation = .expanded
                item.selectionMode = .selectOne
                item.label = String(localized: "Toolbar.writingDirection.label",
                                    defaultValue: "Writing Direction", table: "Document")
                item.toolTip = String(localized: "Toolbar.writingDirection.tooltip",
                                      defaultValue: "Change writing direction", table: "Document")
                item.action = #selector(DocumentViewController.changeWritingDirection)
                item.subitems = [ltrItem, rtlItem]
                return item
                
            case .textOrientation:
                let horizontalItem = NSToolbarItem(itemIdentifier: .horizontalText)
                horizontalItem.label = String(localized: "Toolbar.textOrientation.horizontalText.label",
                                              defaultValue: "Horizontal", table: "Document")
                horizontalItem.toolTip = String(localized: "Toolbar.textOrientation.horizontalText.tooltip",
                                                defaultValue: "Horizontal", table: "Document")
                horizontalItem.image = NSImage(systemSymbolName: "text.alignleft", accessibilityDescription: horizontalItem.label)
                horizontalItem.action = #selector(DocumentViewController.makeLayoutOrientationHorizontal)
                
                let verticalItem = NSToolbarItem(itemIdentifier: .verticalText)
                verticalItem.label = String(localized: "Toolbar.textOrientation.verticalText.label",
                                            defaultValue: "Vertical", table: "Document")
                verticalItem.toolTip = String(localized: "Toolbar.textOrientation.verticalText.tooltip",
                                              defaultValue: "Vertical", table: "Document")
                verticalItem.image = NSImage(resource: .textVertical)
                verticalItem.action = #selector(DocumentViewController.makeLayoutOrientationVertical)
                
                let item = NSToolbarItemGroup(itemIdentifier: itemIdentifier)
                item.isBordered = true
                item.controlRepresentation = .expanded
                item.selectionMode = .selectOne
                item.label = String(localized: "Toolbar.textOrientation.label",
                                    defaultValue: "Text Orientation", table: "Document")
                item.toolTip = String(localized: "Toolbar.textOrientation.tooltip",
                                      defaultValue: "Switch text orientation", table: "Document")
                item.action = #selector(DocumentViewController.changeOrientation)
                item.subitems = [horizontalItem, verticalItem]
                return item
                
            case .indent:
                let leftItem = NSToolbarItem(itemIdentifier: .shiftLeft)
                leftItem.label = String(localized: "Toolbar.indent.shiftLeft.label",
                                        defaultValue: "Shift Left", table: "Document")
                leftItem.toolTip = String(localized: "Toolbar.indent.shiftLeft.tooltip",
                                          defaultValue: "Shift lines to left", table: "Document")
                leftItem.image = NSImage(systemSymbolName: "decrease.indent", accessibilityDescription: leftItem.label)
                leftItem.action = #selector(EditorTextView.shiftLeft)
                
                let rightItem = NSToolbarItem(itemIdentifier: .shiftRight)
                rightItem.label = String(localized: "Toolbar.indent.shiftRight.label",
                                         defaultValue: "Shift Right", table: "Document")
                rightItem.toolTip = String(localized: "Toolbar.indent.shiftRight.tooltip",
                                           defaultValue: "Shift lines to right", table: "Document")
                rightItem.image = NSImage(systemSymbolName: "increase.indent", accessibilityDescription: rightItem.label)
                rightItem.action = #selector(EditorTextView.shiftRight)
                
                let item = NSToolbarItemGroup(itemIdentifier: itemIdentifier)
                item.isBordered = true
                item.controlRepresentation = .expanded
                item.selectionMode = .momentary
                item.label = String(localized: "Toolbar.indent.label",
                                    defaultValue: "Indent", table: "Document")
                item.toolTip = String(localized: "Toolbar.indent.tooltip",
                                      defaultValue: "Indent selection", table: "Document")
                item.subitems = (self.window?.windowTitlebarLayoutDirection == .rightToLeft) ? [rightItem, leftItem] : [leftItem, rightItem]
                return item
                
            case .comment:
                let item = NSToolbarItem(itemIdentifier: itemIdentifier)
                item.isBordered = true
                item.label = String(localized: "Toolbar.comment.label",
                                    defaultValue: "Comment", table: "Document")
                item.toolTip = String(localized: "Toolbar.comment.tooltip",
                                      defaultValue: "Comment-out or uncomment selection", table: "Document")
                item.image = NSImage(resource: .textCommentout)
                item.action = #selector(EditorTextView.toggleComment)
                return item
                
            case .tabStyle:
                let item = StatableMenuToolbarItem(itemIdentifier: itemIdentifier)
                item.isBordered = true
                item.label = String(localized: "Toolbar.tabStyle.label",
                                    defaultValue: "Tab Style", table: "Document")
                item.toolTip = String(localized: "Toolbar.tabStyle.tooltip.off",
                                      defaultValue: "Use spaces for indentation", table: "Document")
                item.stateImages[.on] = NSImage(resource: .tabForwardSplit)
                item.stateImages[.off] = NSImage(resource: .tabForward)
                item.action = #selector(DocumentViewController.toggleAutoTabExpand)
                item.menu.items = [
                    .sectionHeader(title: String(localized: "Toolbar.tabStyle.menu.tabWidth.label",
                                                 defaultValue: "Tab Width", table: "Document", comment: "menu item header"))
                ] + [2, 4, 8].map { width in
                    let item = NSMenuItem(title: width.formatted(), action: #selector(DocumentViewController.changeTabWidth), keyEquivalent: "")
                    item.tag = width
                    return item
                } + [
                    NSMenuItem(title: String(localized: "Toolbar.tabStyle.menu.custom.label",
                                             defaultValue: "Custom…", table: "Document"),
                               action: #selector(DocumentViewController.customizeTabWidth), keyEquivalent: ""),
                    .separator(),
                    NSMenuItem(title: String(localized: "Toolbar.tabStyle.menu.toggle.label",
                                             defaultValue: "Use Spaces for Indentation", table: "Document"),
                               action: #selector(DocumentViewController.toggleAutoTabExpand), keyEquivalent: ""),
                ]
                
                return item
                
            case .wrapLines:
                let item = StatableToolbarItem(itemIdentifier: itemIdentifier)
                item.isBordered = true
                item.label = String(localized: "Toolbar.wrapLines.label",
                                    defaultValue: "Line Wrapping", table: "Document")
                item.toolTip = String(localized: "Toolbar.wrapLines.tooltip.off",
                                      defaultValue: "Wrap lines", table: "Document")
                item.stateImages[.on] = NSImage(resource: .textWrapSlash)
                item.stateImages[.off] = NSImage(resource: .textWrap)
                item.action = #selector(DocumentViewController.toggleLineWrap)
                item.menuFormRepresentation = NSMenuItem(title: item.label, action: item.action, keyEquivalent: "")
                return item
                
            case .invisibles:
                let item = StatableToolbarItem(itemIdentifier: itemIdentifier)
                item.isBordered = true
                item.label = String(localized: "Toolbar.invisibles.label",
                                    defaultValue: "Invisibles", table: "Document")
                item.toolTip = String(localized: "Toolbar.invisibles.tooltip.off",
                                      defaultValue: "Show invisible characters", table: "Document")
                item.stateImages[.on] = NSImage(resource: .paragraphsignSlash)
                item.stateImages[.off] = NSImage(systemSymbolName: "paragraphsign", accessibilityDescription: item.label)
                item.action = #selector(DocumentViewController.toggleInvisibleChars)
                item.menuFormRepresentation = NSMenuItem(title: item.label, action: item.action, keyEquivalent: "")
                return item
                
            case .indentGuides:
                let item = StatableToolbarItem(itemIdentifier: itemIdentifier)
                item.isBordered = true
                item.label = String(localized: "Toolbar.indentGuides.label",
                                    defaultValue: "Indent Guides", table: "Document")
                item.toolTip = String(localized: "Toolbar.indentGuides.tooltip.off",
                                      defaultValue: "Show indent guide lines", table: "Document")
                item.stateImages[.on] = NSImage(resource: .textIndentguides)
                    .withSymbolConfiguration(.init(paletteColors: [.tertiaryLabelColor, .labelColor]))
                item.stateImages[.off] = NSImage(resource: .textIndentguides)
                item.action = #selector(DocumentViewController.toggleIndentGuides)
                item.menuFormRepresentation = NSMenuItem(title: item.label, action: item.action, keyEquivalent: "")
                return item
                
            case .keepOnTop:
                let item = StatableToolbarItem(itemIdentifier: itemIdentifier)
                item.isBordered = true
                item.label = String(localized: "Toolbar.keepOnTop.label",
                                    defaultValue: "Keep on Top", table: "Document")
                item.toolTip = String(localized: "Toolbar.keepOnTop.tooltip",
                                      defaultValue: "Keep the window always on top", table: "Document")
                item.stateImages[.on] = NSImage(systemSymbolName: "pin.slash", accessibilityDescription: item.label)
                item.stateImages[.off] = NSImage(systemSymbolName: "pin", accessibilityDescription: item.label)
                item.action = #selector(DocumentWindow.toggleKeepOnTop)
                return item
                
            case .opacity:
                let item = NSToolbarItem(itemIdentifier: itemIdentifier)
                item.isBordered = true
                item.label = String(localized: "Toolbar.opacity.label",
                                    defaultValue: "Opacity", table: "Document")
                item.toolTip = String(localized: "Toolbar.opacity.tooltip",
                                      defaultValue: "Change editor’s opacity", table: "Document")
                item.image = NSImage(resource: .uiwindowOpacity)
                item.action = #selector(DocumentViewController.showOpacitySlider)
                return item
                
            case .spellCheck:
                let item = NSToolbarItem(itemIdentifier: itemIdentifier)
                item.isBordered = true
                item.label = String(localized: "Toolbar.spellCheck.label",
                                    defaultValue: "Spell Check", table: "Document")
                item.toolTip = String(localized: "Toolbar.spellCheck.tooltip",
                                      defaultValue: "Show spelling and grammar", table: "Document")
                item.image = NSImage(systemSymbolName: "textformat.abc.dottedunderline", accessibilityDescription: item.label)?
                    .withLocale(.init(identifier: "en"))  // fix the symbol with "abc"
                item.action = #selector(NSTextView.showGuessPanel)
                return item
                
            case .emojiAndSymbols:
                let item = NSToolbarItem(itemIdentifier: itemIdentifier)
                item.isBordered = true
                item.label = String(localized: "Toolbar.emojiAndSymbols.label",
                                    defaultValue: "Emoji & Symbols", table: "Document")
                item.toolTip = String(localized: "Toolbar.emojiAndSymbols.tooltip",
                                      defaultValue: "Show Emoji & Symbols palette", table: "Document")
                item.image = NSImage(resource: .emoji)
                item.action = #selector(NSApplication.orderFrontCharacterPalette)
                return item
                
            case .fonts:
                let item = NSMenuToolbarItem(itemIdentifier: itemIdentifier)
                item.isBordered = true
                item.label = String(localized: "Toolbar.fonts.label",
                                    defaultValue: "Fonts", table: "Document")
                item.toolTip = String(localized: "Toolbar.fonts.tooltip",
                                      defaultValue: "Change Font", table: "Document")
                item.image = NSImage(systemSymbolName: "textformat", accessibilityDescription: item.label)
                item.showsIndicator = false
                item.menu.items = [
                    NSMenuItem(),  // dummy item that will be hidden
                    .sectionHeader(title: String(localized: "Toolbar.fonts.menu.fontType.label",
                                                 defaultValue: "Font Type", table: "Document", comment: "menu item header")),
                    NSMenuItem(title: String(localized: "Toolbar.fonts.menu.standard.label",
                                             defaultValue: "Standard", table: "Document"),
                               action: #selector(DocumentViewController.makeFontStandard), keyEquivalent: ""),
                    NSMenuItem(title: String(localized: "Toolbar.fonts.menu.monospaced.label",
                                             defaultValue: "Monospaced", table: "Document"),
                               action: #selector(DocumentViewController.makeFontMonospaced), keyEquivalent: ""),
                    .separator(),
                    NSMenuItem(title: String(localized: "Toolbar.fonts.menu.showFonts.label",
                                             defaultValue: "Show Fonts", table: "Document"),
                               action: #selector(NSFontManager.orderFrontFontPanel), keyEquivalent: ""),
                ]
                return item
                
            case .find:
                let item = NSToolbarItem(itemIdentifier: itemIdentifier)
                item.isBordered = true
                item.label = String(localized: "Toolbar.find.label",
                                    defaultValue: "Find", table: "Document")
                item.toolTip = String(localized: "Toolbar.find.tooltip",
                                      defaultValue: "Show Find & Replace", table: "Document")
                item.image = NSImage(systemSymbolName: "magnifyingglass", accessibilityDescription: item.label)
                item.action = #selector(performTextFinderAction)
                item.tag = TextFinder.Action.showFindInterface.rawValue
                return item
                
            case .print:
                let item = NSToolbarItem(itemIdentifier: itemIdentifier)
                item.isBordered = true
                item.label = String(localized: "Toolbar.print.label",
                                    defaultValue: "Print", table: "Document")
                item.toolTip = String(localized: "Toolbar.print.tooltip",
                                      defaultValue: "Print document", table: "Document")
                item.image = NSImage(systemSymbolName: "printer", accessibilityDescription: item.label)
                item.action = #selector(NSDocument.printDocument)
                return item
                
            case .share:
                let item = NSSharingServicePickerToolbarItem(itemIdentifier: itemIdentifier)
                item.toolTip = String(localized: "Toolbar.share.tooltip",
                                      defaultValue: "Share document file", table: "Document",
                                      comment: "(label for the Share toolbar item is automatically set)")
                item.delegate = self
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
        
        guard let document = self.fileDocument else { return [] }
        
        return [document]
    }
}
