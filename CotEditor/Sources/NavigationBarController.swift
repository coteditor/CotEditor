/*
 
 NavigationBarController.swift
 
 CotEditor
 https://coteditor.com
 
 Created by nakamuxu on 2005-08-22.
 
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

final class NavigationBarController: NSViewController {
    
    // MARK: Public Properties
    
    /// observe textView
    var textView: NSTextView?  // NSTextView cannot be weak
        {
        didSet {
            guard let textView = textView else { return }
            
            // observe text selection change to update outline menu selection
            NotificationCenter.default.addObserver(self, selector: #selector(invalidateOutlineMenuSelection), name: .NSTextViewDidChangeSelection, object: textView)
        }
    }
    
    
    // MARK: Private Properties
    
    var isParsingOutline = false  // flag to control outline indicator
    
    @IBOutlet private weak var outlineMenu: NSPopUpButton?
    @IBOutlet private weak var prevButton: NSButton?
    @IBOutlet private weak var nextButton: NSButton?
    
    @IBOutlet private weak var openSplitButton: NSButton?
    @IBOutlet private weak var closeSplitButton: NSButton?
    
    @IBOutlet private weak var outlineIndicator: NSProgressIndicator?
    @IBOutlet private weak var outlineLoadingMessage: NSTextField?
    
    
    
    // MARK:
    // MARK: Lifecycle
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    
    // MARK: View Controller Methods
    
    /// setup UI
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // hide as default
        self.prevButton!.isHidden = true
        self.nextButton!.isHidden = true
        self.outlineMenu!.isHidden = true
    }
    
    
    
    // MARK: Public Methods
    
    /// build outline menu from given array
    var outlineItems: [OutlineItem] = [] {
        
        didSet {
            // stop outline extracting indicator
            self.isParsingOutline = false
            self.outlineIndicator!.stopAnimation(self)
            self.outlineLoadingMessage!.isHidden = true
            
            self.outlineMenu!.removeAllItems()
            
            // set buttons status here to avoid flicking (2008-05-17)
            self.prevButton!.isHidden = outlineItems.isEmpty
            self.nextButton!.isHidden = outlineItems.isEmpty
            self.outlineMenu!.isHidden = outlineItems.isEmpty
            
            guard !outlineItems.isEmpty else { return }
            
            let menu = self.outlineMenu!.menu!
            
            let baseAttributes: [String: Any] = [NSFontAttributeName: menu.font,
                                                 NSParagraphStyleAttributeName: self.menuItemParagraphStyle]
            
            // add headding item
            let headdingItem = NSMenuItem(title: NSLocalizedString("<Outline Menu>", comment: ""), action: #selector(selectOutlineMenuItem), keyEquivalent: "")
            headdingItem.target = self
            headdingItem.representedObject = NSRange(location: 0, length: 0)
            menu.addItem(headdingItem)
            
            // add outline items
            for outlineItem in outlineItems {
                // separator
                if outlineItem.title == String.separator {
                    menu.addItem(NSMenuItem.separator())
                    continue
                }
                
                let titleRange = outlineItem.title.nsRange
                let attrTitle = NSMutableAttributedString(string: outlineItem.title, attributes: baseAttributes)
                
                let boldTrait: NSFontTraitMask = outlineItem.isBold ? .boldFontMask : []
                let italicTrait: NSFontTraitMask = outlineItem.isItalic ? .italicFontMask : []
                attrTitle.applyFontTraits([boldTrait, italicTrait], range: titleRange)
                
                if outlineItem.hasUnderline {
                    attrTitle.addAttribute(NSUnderlineStyleAttributeName, value: NSNumber(integerLiteral: NSUnderlineStyle.styleSingle.rawValue), range: titleRange)
                }
                
                let menuItem = NSMenuItem()
                menuItem.attributedTitle = attrTitle
                menuItem.action = #selector(selectOutlineMenuItem)
                menuItem.target = self
                menuItem.representedObject = outlineItem.range
                
                menu.addItem(menuItem)
            }
            
            self.invalidateOutlineMenuSelection()
        }
    }
    
    
    /// update enabilities of jump buttons
    func updatePrevNextButtonEnabled() {
        
        self.prevButton!.isEnabled = self.canSelectPrevItem
        self.nextButton!.isEnabled = self.canSelectNextItem
    }
    
    
    /// can select prev item in outline menu?
    var canSelectPrevItem: Bool {
        
        guard let index = self.outlineMenu?.indexOfSelectedItem else { return false }
        
        return (index > 1)
    }
    
    
    /// can select next item in outline menu?
    var canSelectNextItem: Bool {
        
        guard let menu = self.outlineMenu else { return false }
        
        for menuItem in menu.itemArray[(menu.indexOfSelectedItem + 1)..<menu.numberOfItems] {
            if !menuItem.isSeparatorItem {
                return true
            }
        }
        return false
    }
    
    
    /// start displaying outline indicator
    func showOutlineIndicator() {
        
        guard self.outlineMenu!.isEnabled else { return }
        
        self.isParsingOutline = true
        
        // display only if it takes longer than 1 sec.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let `self` = self,
                self.isParsingOutline else { return }
            
            self.outlineIndicator!.startAnimation(self)
            self.outlineLoadingMessage!.isHidden = false
        }
    }
    
    
    /// set closeSplitButton enabled or disabled
    var isCloseSplitButtonEnabled: Bool = false {
        
        didSet {
            self.closeSplitButton!.isHidden = !isCloseSplitButtonEnabled
        }
    }
    
    
    /// set image of open split view button
    var isSplitOrientationVertical: Bool = false {
        
        didSet {
            self.openSplitButton!.image = isSplitOrientationVertical ? #imageLiteral(resourceName: "OpenSplitVerticalTemplate") : #imageLiteral(resourceName: "OpenSplitTemplate")
        }
    }
    
    
    
    // MARK: Action Messages
    
    /// select outline menu item via pupup menu
    @IBAction func selectOutlineMenuItem(_ sender: AnyObject?) {
        
        guard let range = sender?.representedObject as? NSRange else { return }
        
        let textView = self.textView!
        
        textView.selectedRange = range
        textView.centerSelectionInVisibleArea(self)
        textView.window?.makeFirstResponder(textView)
    }
    
    
    /// select previous outline menu item
    @IBAction func selectPrevItemOfOutlineMenu(_ sender: AnyObject?) {
        
        guard let popUp = self.outlineMenu, self.canSelectPrevItem else { return }
        
        var targetIndex = popUp.indexOfSelectedItem - 1
        
        while popUp.item(at: targetIndex)!.isSeparatorItem {
            targetIndex -= 1
            guard targetIndex >= 0 else { break }
        }
        
        popUp.menu!.performActionForItem(at: targetIndex)
    }
    
    
    /// select next outline menu item
    @IBAction func selectNextItemOfOutlineMenu(_ sender: AnyObject?) {
        
        guard let popUp = self.outlineMenu, self.canSelectNextItem else { return }
        
        var targetIndex = popUp.indexOfSelectedItem + 1
        let maxIndex = popUp.numberOfItems - 1
        
        while popUp.item(at: targetIndex)!.isSeparatorItem {
            targetIndex += 1
            guard targetIndex <= maxIndex else { break }
        }
        
        popUp.menu!.performActionForItem(at: targetIndex)
    }
    
    
    
    // MARK: Private Methods
    
    private lazy var menuItemParagraphStyle: NSParagraphStyle = {
        
        let paragraphStyle = NSParagraphStyle.default().mutableCopy() as! NSMutableParagraphStyle
        paragraphStyle.tabStops = []
        paragraphStyle.defaultTabInterval = 2.0 * self.outlineMenu!.menu!.font.advancement(character: " ").width
        paragraphStyle.lineBreakMode = .byTruncatingMiddle
        paragraphStyle.tighteningFactorForTruncation = 0  // don't tighten
        
        return paragraphStyle
    }()
    
    
    /// set outline menu selection
    func invalidateOutlineMenuSelection() {
        
        guard let popUp = self.outlineMenu, popUp.isEnabled && (popUp.menu!.numberOfItems > 0) else { return }
        
        let range = self.textView!.selectedRange
        var selectedIndex = 0
        for (index, menuItem) in popUp.menu!.items.enumerated().reversed() {
            guard !menuItem.isSeparatorItem else { continue }
            
            guard let itemRange = menuItem.representedObject as? NSRange else { continue }
            
            if itemRange.location <= range.location {
                selectedIndex = index
                break
            }
        }
        
        self.outlineMenu!.selectItem(at: selectedIndex)
        self.updatePrevNextButtonEnabled()
    }
    
}
