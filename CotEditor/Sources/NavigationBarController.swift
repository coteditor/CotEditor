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
            
            self.outlineIndicator?.stopAnimation(nil)
            self.outlineLoadingMessage?.isHidden = true
            
            if let progress = outlineProgress, !progress.isFinished {
                self.indicatorTask.schedule()
            } else {
                self.indicatorTask.cancel()
            }
        }
    }
    
    
    // MARK: Private Properties
    
    private var orientationObserver: NSKeyValueObservation?
    private var selectionObserver: NSObjectProtocol?
    
    private lazy var indicatorTask = Debouncer(delay: .milliseconds(200)) { [weak self] in
        guard
            let progress = self?.outlineProgress, !progress.isFinished,
            self?.outlineMenu?.isHidden ?? true
            else { return }
        
        self?.outlineIndicator?.startAnimation(nil)
        self?.outlineLoadingMessage?.isHidden = false
    }
    
    @IBOutlet private weak var leftButton: NSButton?
    @IBOutlet private weak var rightButton: NSButton?
    @IBOutlet private weak var outlineMenu: NSPopUpButton?
    @IBOutlet private weak var outlineIndicator: NSProgressIndicator?
    @IBOutlet private weak var outlineLoadingMessage: NSTextField?
    
    @IBOutlet private weak var openSplitButton: NSButton?
    @IBOutlet private weak var closeSplitButton: NSButton?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    deinit {
        self.orientationObserver?.invalidate()
        
        if let observer = self.selectionObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    
    
    // MARK: View Controller Methods
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        if let progress = self.outlineProgress, (!progress.isFinished || !progress.isCancelled) {
            self.outlineIndicator?.startAnimation(nil)
            self.outlineLoadingMessage?.isHidden = false
        }
        
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
        self.selectionObserver = NotificationCenter.default.addObserver(forName: NSTextView.didChangeSelectionNotification, object: textView, queue: .main) { [weak self] (notification) in
            // avoid updating outline item selection before finishing outline parse
            // -> Otherwise, a wrong item can be selected because of using the outdated outline ranges.
            //    You can ignore text selection change at this time point as the outline selection will be updated when the parse finished.
            guard
                let textView = notification.object as? NSTextView,
                !textView.hasMarkedText(),
                let textStorage = textView.textStorage,
                !textStorage.editedMask.contains(.editedCharacters)
                else { return }
            
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
        
        guard
            let range = sender.representedObject as? NSRange,
            let textView = self.textView
            else { return assertionFailure() }
        
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
        paragraphStyle.defaultTabInterval = 2.0 * self.outlineMenu!.menu!.font.width(of: " ")
        paragraphStyle.lineBreakMode = .byTruncatingMiddle
        paragraphStyle.tighteningFactorForTruncation = 0  // don't tighten
        
        return paragraphStyle
    }()
    
    
    private var prevButton: NSButton? {
        
        return (self.textView?.layoutOrientation == .vertical) ? self.rightButton : self.leftButton
    }
    
    
    private var nextButton: NSButton? {
        
        return (self.textView?.layoutOrientation == .vertical) ? self.leftButton : self.rightButton
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
                    // add dummy item to avoid merging sequential separators into a single separator
                    if menu.items.last?.isSeparatorItem == true {
                        let menuItem = NSMenuItem()
                        menuItem.view = NSView()
                        menu.addItem(menuItem)
                    }
                    
                    menu.addItem(.separator())
                
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
            let location = self.textView?.selectedRange.location,
            let popUp = self.outlineMenu, popUp.isEnabled
            else { return }
        
        let selectedItem = popUp.itemArray.last { menuItem in
            guard
                menuItem.isEnabled,
                let itemRange = menuItem.representedObject as? NSRange
                else { return false }
            
            return itemRange.location <= location
        } ?? popUp.itemArray.first
        
        popUp.select(selectedItem)
        
        self.prevButton?.isEnabled = self.canSelectPrevItem
        self.nextButton?.isEnabled = self.canSelectNextItem
    }
    
    
    /// Update the direction of the menu item arrows.
    ///
    /// - Parameter orientation: The text orientation in the text view.
    private func updateTextOrientation(to orientation: NSLayoutManager.TextLayoutOrientation) {
        
        switch orientation {
            case .horizontal:
                self.leftButton?.image = #imageLiteral(resourceName: "UpArrowTemplate")
                self.rightButton?.image = #imageLiteral(resourceName: "DownArrowTemplate")
            case .vertical:
                self.leftButton?.image = #imageLiteral(resourceName: "LeftArrowTemplate")
                self.rightButton?.image = #imageLiteral(resourceName: "RightArrowTemplate")
            @unknown default:
                fatalError()
        }
        
        self.prevButton?.action = #selector(selectPrevItemOfOutlineMenu)
        self.prevButton?.toolTip = "Jump to previous outline item".localized
        self.prevButton?.isEnabled = self.canSelectPrevItem
        
        self.nextButton?.action = #selector(selectNextItemOfOutlineMenu)
        self.nextButton?.toolTip = "Jump to next outline item".localized
        self.nextButton?.isEnabled = self.canSelectNextItem
    }
    
}
