/*
 
 NavigationBarController.swift
 
 CotEditor
 https://coteditor.com
 
 Created by nakamuxu on 2005-08-22.
 
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014-2018 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 https://www.apache.org/licenses/LICENSE-2.0
 
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
    var textView: NSTextView? {  // NSTextView cannot be weak
        
        didSet {
            guard let textView = self.textView else { return }
          
            // -> DO NOT use block-based KVO for NSTextView sublcass
            //    since it causes application crash on OS X 10.11 (but ok on macOS 10.12 and later 2018-02)
            textView.addObserver(self, forKeyPath: #keyPath(NSTextView.layoutOrientation), options: .initial, context: nil)
            
            // observe text selection change to update outline menu selection
            NotificationCenter.default.addObserver(self, selector: #selector(invalidateOutlineMenuSelection), name: NSTextView.didChangeSelectionNotification, object: textView)
        }
    }
    
    
    // MARK: Private Properties
    
    private var isParsingOutline = false  // flag to control outline indicator
    
    private weak var prevButton: NSButton?
    private weak var nextButton: NSButton?
    
    @IBOutlet private weak var outlineMenu: NSPopUpButton?
    @IBOutlet private weak var leftButton: NSButton?
    @IBOutlet private weak var rightButton: NSButton?
    
    @IBOutlet private weak var openSplitButton: NSButton?
    @IBOutlet private weak var closeSplitButton: NSButton?
    
    @IBOutlet private weak var outlineIndicator: NSProgressIndicator?
    @IBOutlet private weak var outlineLoadingMessage: NSTextField?
    
    
    
    // MARK: -
    
    deinit {
        self.textView?.removeObserver(self, forKeyPath: #keyPath(NSTextView.layoutOrientation))
    }
    
    
    
    // MARK: View Controller Methods
    
    /// setup UI
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // hide outline navigations
        self.leftButton!.isHidden = true
        self.rightButton!.isHidden = true
        self.outlineMenu!.isHidden = true
    }
    
    
    /// observed key value did update
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        
        if keyPath == #keyPath(NSTextView.layoutOrientation), let orientation = self.textView?.layoutOrientation {
            self.updateTextOrientation(to: orientation)
        }
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
            
            self.prevButton!.isHidden = outlineItems.isEmpty
            self.nextButton!.isHidden = outlineItems.isEmpty
            self.outlineMenu!.isHidden = outlineItems.isEmpty
            
            guard !outlineItems.isEmpty else { return }
            
            let menu = self.outlineMenu!.menu!
            
            let baseAttributes: [NSAttributedStringKey: Any] = [.font: menu.font,
                                                                .paragraphStyle: self.menuItemParagraphStyle]
            
            // add headding item
            let headdingItem = NSMenuItem(title: NSLocalizedString("<Outline Menu>", comment: ""), action: #selector(selectOutlineMenuItem), keyEquivalent: "")
            headdingItem.target = self
            headdingItem.representedObject = NSRange(location: 0, length: 0)
            menu.addItem(headdingItem)
            
            // add outline items
            for outlineItem in outlineItems {
                // separator
                if outlineItem.title == String.separator {
                    menu.addItem(.separator())
                    continue
                }
                
                let titleRange = outlineItem.title.nsRange
                let attrTitle = NSMutableAttributedString(string: outlineItem.title, attributes: baseAttributes)
                
                let boldTrait: NSFontTraitMask = outlineItem.style.contains(.bold) ? .boldFontMask : []
                let italicTrait: NSFontTraitMask = outlineItem.style.contains(.italic) ? .italicFontMask : []
                attrTitle.applyFontTraits([boldTrait, italicTrait], range: titleRange)
                
                if outlineItem.style.contains(.underline) {
                    attrTitle.addAttribute(.underlineStyle, value: NSUnderlineStyle.styleSingle.rawValue, range: titleRange)
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
    
    
    /// can select prev item in outline menu?
    var canSelectPrevItem: Bool {
        
        guard let menu = self.outlineMenu else { return false }
        
        return (menu.indexOfSelectedItem > 1)
    }
    
    
    /// can select next item in outline menu?
    var canSelectNextItem: Bool {
        
        guard let menu = self.outlineMenu else { return false }
        
        let nextRange = (menu.indexOfSelectedItem + 1)..<menu.numberOfItems
        
        return menu.itemArray[nextRange].contains { !$0.isSeparatorItem }
    }
    
    
    /// start displaying outline indicator
    func showOutlineIndicator() {
        
        guard self.outlineMenu!.isEnabled else {
            self.isParsingOutline = false
            return
        }
        
        self.isParsingOutline = true
        
        // display only if it takes longer than 1 sec.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard self?.isParsingOutline ?? false else { return }
            
            self?.outlineIndicator!.startAnimation(self)
            self?.outlineLoadingMessage!.isHidden = false
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
    @IBAction func selectPrevItemOfOutlineMenu(_ sender: Any?) {
        
        guard let popUp = self.outlineMenu, self.canSelectPrevItem else { return }
        
        let index = stride(from: popUp.indexOfSelectedItem - 1, to: 0, by: -1)
            .first { !popUp.item(at: $0)!.isSeparatorItem } ?? 0
        
        popUp.menu!.performActionForItem(at: index)
    }
    
    
    /// select next outline menu item
    @IBAction func selectNextItemOfOutlineMenu(_ sender: Any?) {
        
        guard let popUp = self.outlineMenu, self.canSelectNextItem else { return }
        
        let index = stride(from: popUp.indexOfSelectedItem + 1, to: popUp.numberOfItems, by: 1)
            .first { !popUp.item(at: $0)!.isSeparatorItem }
        
        if let index = index {
            popUp.menu!.performActionForItem(at: index)
        }
    }
    
    
    
    // MARK: Private Methods
    
    private lazy var menuItemParagraphStyle: NSParagraphStyle = {
        
        let paragraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        paragraphStyle.tabStops = []
        paragraphStyle.defaultTabInterval = 2.0 * self.outlineMenu!.menu!.font.spaceWidth
        paragraphStyle.lineBreakMode = .byTruncatingMiddle
        paragraphStyle.tighteningFactorForTruncation = 0  // don't tighten
        
        return paragraphStyle
    }()
    
    
    /// update enabilities of jump buttons
    private func updatePrevNextButtonEnabled() {
        
        self.prevButton!.isEnabled = self.canSelectPrevItem
        self.nextButton!.isEnabled = self.canSelectNextItem
    }
    
    
    /// set outline menu selection
    @objc private func invalidateOutlineMenuSelection() {
        
        guard
            let popUp = self.outlineMenu, popUp.isEnabled,
            let items = popUp.menu?.items,
            let firstItem = items.first
            else { return }
        
        let location = self.textView!.selectedRange.location
        let selectedItem = items.reversed().first { menuItem in
            guard
                !menuItem.isSeparatorItem,
                let itemRange = menuItem.representedObject as? NSRange
                else { return false }
            
            return itemRange.location <= location
        } ?? firstItem
        
        popUp.select(selectedItem)
        self.updatePrevNextButtonEnabled()
    }
    
    
    /// update menu item arrows
    private func updateTextOrientation(to orientation: NSLayoutManager.TextLayoutOrientation) {
        
        switch orientation {
        case .horizontal:
            self.prevButton = self.leftButton
            self.nextButton = self.rightButton
            self.leftButton?.image = #imageLiteral(resourceName: "UpArrowTemplate")
            self.rightButton?.image = #imageLiteral(resourceName: "DownArrowTemplate")
            
        case .vertical:
            self.prevButton = self.rightButton
            self.nextButton = self.leftButton
            self.leftButton?.image = #imageLiteral(resourceName: "LeftArrowTemplate")
            self.rightButton?.image = #imageLiteral(resourceName: "RightArrowTemplate")
        }
        
        self.prevButton?.action = #selector(selectPrevItemOfOutlineMenu(_:))
        self.prevButton?.toolTip = NSLocalizedString("Jump to previous outline item", comment: "")
        
        self.nextButton?.action = #selector(selectNextItemOfOutlineMenu(_:))
        self.nextButton?.toolTip = NSLocalizedString("Jump to next outline item", comment: "")
        
        self.updatePrevNextButtonEnabled()
    }
    
}
