//
//  ToolbarController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by nakamuxu on 2005-01-07.
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
    static let pageGuide = Self(Self.prefix + "pageGuilde")
    static let indentGuides = Self(Self.prefix + "indentGuildes")
    
    static let opacity = Self(Self.prefix + "opacity")
    static let spellCheck = Self(Self.prefix + "spellCheck")
    static let colorCode = Self(Self.prefix + "colorCode")
    static let emojiAndSymbols = Self(Self.prefix + "emojiAndSymbols")
    static let fonts = Self(Self.prefix + "fonts")
    static let find = Self(Self.prefix + "find")
    static let print = Self(Self.prefix + "print")
    static let share = Self(Self.prefix + "share")
}



final class ToolbarController: NSObject {
    
    // MARK: Public Properties
    
    weak var document: Document? {
        
        willSet {
            self.documentStyleObserver = nil
        }
        
        didSet {
            guard let document = document else { return }
            
            self.toolbar?.items.lazy.compactMap { $0 as? NSSharingServicePickerToolbarItem }.first?.delegate = document
            self.invalidateSyntaxStyleSelection()
            
            // observe document's style change
            self.documentStyleObserver = document.didChangeSyntaxStyle
                .receive(on: RunLoop.main)
                .sink { [weak self] _ in self?.invalidateSyntaxStyleSelection() }
        }
    }
    
    
    // MARK: Private Properties
    
    private var documentStyleObserver: AnyCancellable?
    private var styleListObserver: AnyCancellable?
    private var recentStyleNamesObserver: UserDefaultsObservation?
    private weak var syntaxPopUpButton: NSPopUpButton?
    
    @IBOutlet private weak var toolbar: NSToolbar?
    @IBOutlet private var tabStyleControl: NSSegmentedControl?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    override init() {
        
        super.init()
        
        //  observe for syntax style line-up change
        self.styleListObserver = SyntaxManager.shared.didUpdateSettingList
            .sink { [weak self] _ in self?.buildSyntaxPopupButton() }
        self.recentStyleNamesObserver = UserDefaults.standard.observe(key: .recentStyleNames) { [weak self] _ in
            self?.buildSyntaxPopupButton()
        }
    }
    
    
    
    // MARK: Private Methods
    
    /// select item in the syntax style menu
    private func invalidateSyntaxStyleSelection() {
        
        guard let styleName = self.document?.syntaxParser.style.name else { return }
        
        self.syntaxPopUpButton?.selectItem(withTitle: styleName)
    }
    
    
    /// build syntax style popup menu
    private func buildSyntaxPopupButton() {
        
        guard let menu = self.syntaxPopUpButton?.menu else { return }
        
        let styleNames = SyntaxManager.shared.settingNames
        let recentStyleNames = UserDefaults.standard[.recentStyleNames]!
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
        
        self.invalidateSyntaxStyleSelection()
    }
    
}



extension ToolbarController: NSToolbarDelegate {
    
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        
        return [
            .flexibleSpace,
            .syntaxStyle,
            .toggleSidebar,
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
            .invisibles,
            .wrapLines,
            .pageGuide,
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
                self.buildSyntaxPopupButton()
                
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
                item.image = #imageLiteral(resourceName: "Inspector")
                item.label = "Inspector".localized
                item.toolTip = "Show document information".localized
                item.action = #selector(WindowContentViewController.toggleInspector)
                return item
                
            case .textSize:
                let smallerItem = NSToolbarItem()
                smallerItem.image = #imageLiteral(resourceName: "TextSizeSmallerTemplate")
                smallerItem.label = "Smaller".localized
                smallerItem.toolTip = "Smaller".localized
                smallerItem.action = #selector(EditorTextView.smallerFont)
                
                let biggerItem = NSToolbarItem()
                biggerItem.image = #imageLiteral(resourceName: "TextSizeLargerTemplate")
                biggerItem.label = "Bigger".localized
                biggerItem.toolTip = "Bigger".localized
                biggerItem.action = #selector(EditorTextView.biggerFont)
                
                let item = NSToolbarItemGroup(itemIdentifier: itemIdentifier)
                item.isBordered = true
                item.controlRepresentation = .expanded
                item.selectionMode = .momentary
                item.label = "Text Size".localized
                item.toolTip = "Change text size".localized
                item.subitems = [smallerItem, biggerItem]
                item.useSubitemsForMenuFormRepresentation()
                return item
                
            case .writingDirection:
                let ltrItem = NSToolbarItem()
                ltrItem.image = #imageLiteral(resourceName: "WritingDirectionLTRTemplate")
                ltrItem.label = "Left to Right".localized
                ltrItem.toolTip = "Left to Right".localized
                ltrItem.action = #selector(DocumentViewController.makeWritingDirectionLeftToRight)
                
                let rtlItem = NSToolbarItem()
                rtlItem.image = #imageLiteral(resourceName: "WritingDirectionRTLTemplate")
                rtlItem.label = "Right to Left".localized
                rtlItem.toolTip = "Right to Left".localized
                rtlItem.action = #selector(DocumentViewController.makeWritingDirectionRightToLeft)
                
                let item = ToolbarItemGroup(itemIdentifier: itemIdentifier)
                item.isBordered = true
                item.controlRepresentation = .expanded
                item.selectionMode = .selectOne
                item.label = "Writing Direction".localized
                item.toolTip = "Change writing direction".localized
                item.action = #selector(DocumentViewController.changeWritingDirection)
                item.subitems = [ltrItem, rtlItem]
                item.useSubitemsForMenuFormRepresentation()
                return item
                
            case .textOrientation:
                let horizontalItem = NSToolbarItem()
                horizontalItem.image = #imageLiteral(resourceName: "WritingDirectionLTRTemplate")
                horizontalItem.label = "Horizontal".localized
                horizontalItem.toolTip = "Horizontal".localized
                horizontalItem.action = #selector(DocumentViewController.makeLayoutOrientationHorizontal)
                
                let verticalItem = NSToolbarItem()
                verticalItem.image = #imageLiteral(resourceName: "WritingDirectionVerticalTemplate")
                verticalItem.label = "Vertical".localized
                verticalItem.toolTip = "Vertical".localized
                verticalItem.action = #selector(DocumentViewController.makeLayoutOrientationVertical)
                
                let item = ToolbarItemGroup(itemIdentifier: itemIdentifier)
                item.isBordered = true
                item.controlRepresentation = .expanded
                item.selectionMode = .selectOne
                item.label = "Text Orientation".localized
                item.toolTip = "Toggle text orientation".localized
                item.action = #selector(DocumentViewController.changeOrientation)
                item.subitems = [horizontalItem, verticalItem]
                item.useSubitemsForMenuFormRepresentation()
                return item
                
            case .indent:
                let leftItem = NSToolbarItem()
                leftItem.image = #imageLiteral(resourceName: "ShiftLeft")
                leftItem.label = "Shift Left".localized
                leftItem.toolTip = "Shift lines to left".localized
                leftItem.action = #selector(EditorTextView.shiftLeft)
                
                let rightItem = NSToolbarItem()
                rightItem.image = #imageLiteral(resourceName: "ShiftRight")
                rightItem.label = "Shift Right".localized
                rightItem.toolTip = "Shift lines to right".localized
                rightItem.action = #selector(EditorTextView.shiftRight)
                
                let item = NSToolbarItemGroup(itemIdentifier: itemIdentifier)
                item.isBordered = true
                item.controlRepresentation = .expanded
                item.selectionMode = .momentary
                item.label = "Indent".localized
                item.toolTip = "Indent selection".localized
                item.subitems = [leftItem, rightItem]
                item.useSubitemsForMenuFormRepresentation()
                return item
                
            case .comment:
                let item = NSToolbarItem(itemIdentifier: itemIdentifier)
                item.isBordered = true
                item.image = #imageLiteral(resourceName: "Comment")
                item.label = "Comment".localized
                item.toolTip = "Comment-out or uncomment selection".localized
                item.action = #selector(EditorTextView.toggleComment)
                return item
                
            case .tabStyle:
                let menu = NSMenu()
                menu.autoenablesItems = false
                menu.addItem(withTitle: "Tab Width".localized, action: nil, keyEquivalent: "")
                menu.items.last!.isEnabled = false
                menu.items += [2, 3, 4, 8]
                    .map { (width) in
                        let item = NSMenuItem(title: String(width), action: #selector(DocumentViewController.changeTabWidth), keyEquivalent: "")
                        item.tag = width
                        return item
                    }
                menu.addItem(withTitle: "Custom…".localized, action: #selector(DocumentViewController.customizeTabWidth), keyEquivalent: "")
                menu.addItem(.separator())
                menu.addItem(withTitle: "Auto-Expand Tabs", action: #selector(DocumentViewController.toggleAutoTabExpand), keyEquivalent: "")
                
                let item = StatableMenuToolbarItem(itemIdentifier: itemIdentifier, control: self.tabStyleControl!, menu: menu)
                item.label = "Tab Style".localized
                item.toolTip = "Toggle tab auto-expansion".localized
                item.action = #selector(DocumentViewController.toggleAutoTabExpand)
                
                let menuForm = NSMenuItem()
                menuForm.title = item.label
                menuForm.action = item.action
                item.menuFormRepresentation = menuForm
                
                return item
                
            case .invisibles:
                let item = StatableToolbarItem(itemIdentifier: itemIdentifier)
                item.isBordered = true
                item.image = #imageLiteral(resourceName: "Invisibles_On")
                item.label = "Invisibles".localized
                item.toolTip = "Show or hide invisible characters in text".localized
                item.action = #selector(DocumentViewController.toggleInvisibleChars)
                return item
                
            case .wrapLines:
                let item = StatableToolbarItem(itemIdentifier: itemIdentifier)
                item.isBordered = true
                item.image = #imageLiteral(resourceName: "WrapLines_On")
                item.label = "Wrap Lines".localized
                item.toolTip = "Toggle wrap lines".localized
                item.action = #selector(DocumentViewController.toggleLineWrap)
                return item
                
            case .pageGuide:
                let item = StatableToolbarItem(itemIdentifier: itemIdentifier)
                item.isBordered = true
                item.image = #imageLiteral(resourceName: "PageGuide_On")
                item.label = "Page Guide".localized
                item.toolTip = "Show or hide page guide line".localized
                item.action = #selector(DocumentViewController.togglePageGuide)
                return item
                
            case .indentGuides:
                let item = StatableToolbarItem(itemIdentifier: itemIdentifier)
                item.isBordered = true
                item.image = #imageLiteral(resourceName: "IndentGuides_On")
                item.label = "Indent Guides".localized
                item.toolTip = "Show or hide indent guide lines".localized
                item.action = #selector(DocumentViewController.toggleIndentGuides)
                return item
                
            case .opacity:
                let item = NSToolbarItem(itemIdentifier: itemIdentifier)
                item.isBordered = true
                item.image = #imageLiteral(resourceName: "Opacity")
                item.label = "Opacity".localized
                item.toolTip = "Change editor’s opacity".localized
                item.action = #selector(DocumentWindowController.showOpacitySlider)
                // use custom view to locate popup view
                let button = NSButton(image: item.image!, target: nil, action: item.action)
                button.bezelStyle = .texturedRounded
                item.view = button
                return item
                
            case .spellCheck:
                let item = NSToolbarItem(itemIdentifier: itemIdentifier)
                item.isBordered = true
                item.image = #imageLiteral(resourceName: "SpellCheck")
                item.label = "Spell Check".localized
                item.toolTip = "Show spelling and grammar".localized
                item.action = #selector(NSTextView.showGuessPanel)
                return item
                
            case .colorCode:
                let item = NSToolbarItem(itemIdentifier: itemIdentifier)
                item.isBordered = true
                item.image = #imageLiteral(resourceName: "ColorCode")
                item.label = "Color Code".localized
                item.toolTip = "Open Color Code Editor and set selection as color code".localized
                item.action = #selector(EditorTextView.editColorCode)
                return item
                
            case .emojiAndSymbols:
                let item = NSToolbarItem(itemIdentifier: itemIdentifier)
                item.isBordered = true
                item.image = #imageLiteral(resourceName: "Emoji")
                item.label = "Emoji & Symbols".localized
                item.toolTip = "Show Emoji & Symbols palette".localized
                item.action = #selector(NSApplication.orderFrontCharacterPalette)
                return item
                
            case .fonts:
                let item = NSToolbarItem(itemIdentifier: itemIdentifier)
                item.isBordered = true
                item.image = #imageLiteral(resourceName: "FontsTemplate")
                item.label = "Fonts".localized
                item.toolTip = "Show Font Panel".localized
                item.action = #selector(NSFontManager.orderFrontFontPanel)
                return item
                
            case .find:
                let item = NSToolbarItem(itemIdentifier: itemIdentifier)
                item.isBordered = true
                item.image = #imageLiteral(resourceName: "MagnifierTemplate")
                item.label = "Find".localized
                item.toolTip = "Show “Find and Replace”".localized
                item.action = #selector(TextFinder.showFindPanel)
                return item
                
            case .print:
                let item = NSToolbarItem(itemIdentifier: itemIdentifier)
                item.isBordered = true
                item.image = #imageLiteral(resourceName: "PrintTemplate")
                item.label = "Print".localized
                item.toolTip = "Print".localized
                item.action = #selector(NSDocument.printDocument)
                return item
                
            case .share:
                let item = NSSharingServicePickerToolbarItem(itemIdentifier: itemIdentifier)
                item.toolTip = "Share document file".localized
                item.delegate = self.document
                return item
            
            default:
                return NSToolbarItem(itemIdentifier: itemIdentifier)
        }
    }
    
}



extension NSDocument: NSSharingServicePickerToolbarItemDelegate {
    
    public func items(for pickerToolbarItem: NSSharingServicePickerToolbarItem) -> [Any] {
        
        return [self]
    }
    
}
