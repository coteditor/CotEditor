//
//  NavigationBarController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by nakamuxu on 2005-08-22.
//
//  ---------------------------------------------------------------------------
//
//  © 2004-2007 nakamuxu
//  © 2014-2018 1024jp
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

final class NavigationBarController: NSViewController {
    
    // MARK: Public Properties
    
    /// observe textView
    var textView: NSTextView? {  // NSTextView cannot be weak
        
        willSet {
            guard let textView = self.textView else { return }
            
            self.orientationObserver?.invalidate()
            NotificationCenter.default.removeObserver(self, name: NSTextView.didChangeSelectionNotification, object: textView)
        }
        
        didSet {
            guard let textView = self.textView else { return }
          
            self.orientationObserver = textView.observe(\.layoutOrientation, options: .initial) { [unowned self] (textView, _) in
                self.updateTextOrientation(to: textView.layoutOrientation)
            }
            
            // observe text selection change to update outline menu selection
            NotificationCenter.default.addObserver(self, selector: #selector(invalidateOutlineMenuSelection), name: NSTextView.didChangeSelectionNotification, object: textView)
        }
    }
    
    
    weak var outlineProgress: Progress? {
        
        didSet {
            assert(Thread.isMainThread)
            
            guard let progress = self.outlineProgress else {
                self.outlineIndicator?.stopAnimation(nil)
                self.outlineLoadingMessage?.isHidden = true
                return
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200)) { [weak self] in
                guard !progress.isFinished else { return }
                
                self?.outlineIndicator?.startAnimation(nil)
                self?.outlineLoadingMessage?.isHidden = false
            }
        }
    }
    
    
    // MARK: Private Properties
    
    private var orientationObserver: NSKeyValueObservation?
    
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
        self.orientationObserver?.invalidate()
    }
    
    
    
    // MARK: View Controller Methods
    
    /// setup UI
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // hide outline navigations
        self.leftButton!.isHidden = true
        self.rightButton!.isHidden = true
        self.outlineMenu!.isHidden = true
        
        // set accessibility
        self.view.setAccessibilityElement(true)
        self.view.setAccessibilityRole(.group)
        self.view.setAccessibilityLabel("navigation bar".localized)
        
        self.outlineMenu?.setAccessibilityLabel("outline menu".localized)
    }
    
    
    
    // MARK: Public Methods
    
    /// build outline menu from given array
    var outlineItems: [OutlineItem] = [] {
        
        didSet {
            self.outlineMenu!.removeAllItems()
            
            self.prevButton!.isHidden = outlineItems.isEmpty
            self.nextButton!.isHidden = outlineItems.isEmpty
            self.outlineMenu!.isHidden = outlineItems.isEmpty
            
            guard !outlineItems.isEmpty else { return }
            
            let menu = self.outlineMenu!.menu!
            
            // add headding item
            let headdingItem = NSMenuItem()
            headdingItem.title = "<Outline Menu>".localized
            headdingItem.representedObject = NSRange(location: 0, length: 0)
            menu.addItem(headdingItem)
            
            // add outline items
            for outlineItem in self.outlineItems {
                switch outlineItem.title {
                case .separator:
                    menu.addItem(.separator())
                    
                    // add a dummy item to avoid merging series separators to a single separator
                    let menuItem = NSMenuItem()
                    menuItem.view = NSView()
                    menu.addItem(menuItem)
                    
                default:
                    let menuItem = NSMenuItem()
                    menuItem.attributedTitle = outlineItem.attributedTitle(for: menu.font, attributes: [.paragraphStyle: self.menuItemParagraphStyle])
                    menuItem.representedObject = outlineItem.range
                    menu.addItem(menuItem)
                }
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
        
        return menu.itemArray[nextRange].contains { $0.representedObject != nil }
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
    @IBAction func selectOutlineMenuItem(_ sender: NSMenuItem) {
        
        guard let range = sender.representedObject as? NSRange else { return assertionFailure() }
        
        let textView = self.textView!
        
        textView.selectedRange = range
        textView.centerSelectionInVisibleArea(self)
        textView.window?.makeFirstResponder(textView)
    }
    
    
    /// select previous outline menu item
    @IBAction func selectPrevItemOfOutlineMenu(_ sender: Any?) {
        
        guard let popUp = self.outlineMenu, self.canSelectPrevItem else { return }
        
        let index = stride(from: popUp.indexOfSelectedItem - 1, to: 0, by: -1)
            .first { popUp.item(at: $0)!.representedObject != nil } ?? 0
        
        popUp.menu!.performActionForItem(at: index)
    }
    
    
    /// select next outline menu item
    @IBAction func selectNextItemOfOutlineMenu(_ sender: Any?) {
        
        guard let popUp = self.outlineMenu, self.canSelectNextItem else { return }
        
        let index = stride(from: popUp.indexOfSelectedItem + 1, to: popUp.numberOfItems, by: 1)
            .first { popUp.item(at: $0)!.representedObject != nil }
        
        if let index = index {
            popUp.menu!.performActionForItem(at: index)
        }
    }
    
    
    
    // MARK: Private Methods
    
    private lazy var menuItemParagraphStyle: NSParagraphStyle = {
        
        let paragraphStyle = NSParagraphStyle.default.mutable
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
        let selectedItem = items.last { menuItem in
            guard
                menuItem.isEnabled,
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
        self.prevButton?.toolTip = "Jump to previous outline item".localized
        
        self.nextButton?.action = #selector(selectNextItemOfOutlineMenu(_:))
        self.nextButton?.toolTip = "Jump to next outline item".localized
        
        self.updatePrevNextButtonEnabled()
    }
    
}
