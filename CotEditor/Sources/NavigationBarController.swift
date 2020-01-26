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

final class NavigationBarController: NSViewController {
    
    // MARK: Public Properties
    
    weak var textView: NSTextView?
    
    var outlineItems: [OutlineItem] = [] {
        
        didSet {
            guard self.isViewShown, outlineItems != oldValue else { return }
            
            self.updateOutlineMenu()
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
    private var selectionObserver: NSObjectProtocol?
    
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
        
        if let observer = self.selectionObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    
    
    // MARK: View Controller Methods
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // set accessibility
        self.view.setAccessibilityElement(true)
        self.view.setAccessibilityRole(.group)
        self.view.setAccessibilityLabel("navigation bar".localized)
        
        self.outlineMenu?.setAccessibilityLabel("outline menu".localized)
    }
    
    
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        guard let textView = self.textView else { return assertionFailure() }

        self.orientationObserver = textView.observe(\.layoutOrientation, options: .initial) { [weak self] (textView, _) in
          self?.updateTextOrientation(to: textView.layoutOrientation)
        }

        if let observer = self.selectionObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        self.selectionObserver = NotificationCenter.default.addObserver(forName: NSTextView.didChangeSelectionNotification, object: textView, queue: .main) { [weak self] _ in
            self?.invalidateOutlineMenuSelection()
        }
        
        self.updateOutlineMenu()
    }
    
    
    override func viewDidDisappear() {
        
        super.viewDidDisappear()
        
        self.orientationObserver?.invalidate()
        self.orientationObserver = nil
        
        if let observer = self.selectionObserver {
            NotificationCenter.default.removeObserver(observer)
            self.selectionObserver = nil
        }
    }
    
    
    
    // MARK: Public Methods
    
    /// Can select the prev item in outline menu?
    var canSelectPrevItem: Bool {
        
        guard let menu = self.outlineMenu else { return false }
        
        return (menu.indexOfSelectedItem > 1)
    }
    
    
    /// Can select the next item in outline menu?
    var canSelectNextItem: Bool {
        
        guard let menu = self.outlineMenu else { return false }
        
        return menu.itemArray[(menu.indexOfSelectedItem + 1)...].contains { $0.representedObject != nil }
    }
    
    
    /// Set closeSplitButton enabled or disabled.
    var isCloseSplitButtonEnabled: Bool = false {
        
        didSet {
            self.closeSplitButton!.isHidden = !isCloseSplitButtonEnabled
        }
    }
    
    
    /// Set the image of the open split view button.
    var isSplitOrientationVertical: Bool = false {
        
        didSet {
            self.openSplitButton!.image = isSplitOrientationVertical ? #imageLiteral(resourceName: "OpenSplitVerticalTemplate") : #imageLiteral(resourceName: "OpenSplitTemplate")
        }
    }
    
    
    
    // MARK: Action Messages
    
    /// Select outline menu item from the popup menu.
    @IBAction func selectOutlineMenuItem(_ sender: NSMenuItem) {
        
        guard let range = sender.representedObject as? NSRange else { return assertionFailure() }
        
        let textView = self.textView!
        
        textView.selectedRange = range
        textView.centerSelectionInVisibleArea(self)
        textView.window?.makeFirstResponder(textView)
    }
    
    
    /// Select the previous outline menu item.
    @IBAction func selectPrevItemOfOutlineMenu(_ sender: Any?) {
        
        guard let popUp = self.outlineMenu, self.canSelectPrevItem else { return }
        
        let index = popUp.itemArray[..<popUp.indexOfSelectedItem]
            .lastIndex { $0.representedObject != nil } ?? 0
        
        popUp.menu!.performActionForItem(at: index)
    }
    
    
    /// Select the next outline menu item.
    @IBAction func selectNextItemOfOutlineMenu(_ sender: Any?) {
        
        guard let popUp = self.outlineMenu, self.canSelectNextItem else { return }
        
        let index = popUp.itemArray[(popUp.indexOfSelectedItem + 1)...]
            .firstIndex { $0.representedObject != nil }
        
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
    
    
    /// Update enabilities of jump buttons.
    private func updatePrevNextButtonEnabled() {
        
        self.prevButton!.isEnabled = self.canSelectPrevItem
        self.nextButton!.isEnabled = self.canSelectNextItem
    }
    
    
    /// Build outline menu from `outlineItems`.
    private func updateOutlineMenu() {
        
        self.outlineMenu!.removeAllItems()
        
        self.leftButton!.isHidden = self.outlineItems.isEmpty
        self.rightButton!.isHidden = self.outlineItems.isEmpty
        self.outlineMenu!.isHidden = self.outlineItems.isEmpty
        
        guard !self.outlineItems.isEmpty else { return }
        
        let menu = self.outlineMenu!.menu!
        
        // add headding item
        let headdingItem = NSMenuItem()
        headdingItem.title = "<Outline Menu>".localized
        headdingItem.representedObject = NSRange(0..<0)
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
    
    
    /// Select the proper item in outline menu based on the current selection in the text view.
    private func invalidateOutlineMenuSelection() {
        
        guard
            let textView = self.textView,
            let popUp = self.outlineMenu, popUp.isEnabled,
            let items = popUp.menu?.items,
            let firstItem = items.first
            else { return }
        
        let location = textView.selectedRange.location
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
    
    
    /// Update the direction of the menu item arrows.
    ///
    /// - Parameter orientation: The text orientation in the text view.
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
            
        @unknown default: fatalError()
        }
        
        self.prevButton?.action = #selector(selectPrevItemOfOutlineMenu)
        self.prevButton?.toolTip = "Jump to previous outline item".localized
        
        self.nextButton?.action = #selector(selectNextItemOfOutlineMenu)
        self.nextButton?.toolTip = "Jump to next outline item".localized
        
        self.updatePrevNextButtonEnabled()
    }
    
}
