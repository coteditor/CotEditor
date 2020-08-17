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

import Combine
import Cocoa

final class NavigationBarController: NSViewController {
    
    // MARK: Public Properties
    
    weak var textView: NSTextView?
    
    var outlineItems: [OutlineItem]? {
        
        didSet {
            if self.isViewShown {
                self.updateOutlineMenu()
            }
        }
    }
    
    
    // MARK: Private Properties
    
    private var splitViewObservers: Set<AnyCancellable> = []
    private var orientationObserver: AnyCancellable?
    private var selectionObserver: AnyCancellable?
    
    @objc private dynamic var showsCloseButton = false
    @objc private dynamic var showsOutlineMenu = false
    @objc private dynamic var isParsingOutline = false
    
    @IBOutlet private weak var leftButton: NSButton?
    @IBOutlet private weak var rightButton: NSButton?
    @IBOutlet private weak var outlineMenu: NSPopUpButton?
    
    @IBOutlet private weak var openSplitButton: NSButton?
    @IBOutlet private var editorSplitMenu: NSMenu?
    
    
    
    // MARK: -
    // MARK: View Controller Methods
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        if #available(macOS 10.16, *) { } else {
            (self.view as? NSVisualEffectView)?.material = .windowBackground
        }
        
        // set accessibility
        self.view.setAccessibilityElement(true)
        self.view.setAccessibilityRole(.group)
        self.view.setAccessibilityLabel("navigation bar".localized)
        
        self.outlineMenu?.setAccessibilityLabel("outline menu".localized)
    }
    
    
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        guard
            let splitViewController = self.splitViewController,
            let textView = self.textView
            else { return assertionFailure() }
        
        splitViewController.$isVertical
            .map { $0 ? #imageLiteral(resourceName: "split.add.vertical") : #imageLiteral(resourceName: "split.add") }
            .assign(to: \.image, on: self.openSplitButton!)
            .store(in: &self.splitViewObservers)
        splitViewController.$canCloseSplitItem
            .sink { [weak self] in self?.showsCloseButton = $0 }
            .store(in: &self.splitViewObservers)
        
        self.orientationObserver = textView.publisher(for: \.layoutOrientation, options: .initial)
            .sink { [weak self] in self?.updateTextOrientation(to: $0) }
        
        self.selectionObserver = NotificationCenter.default.publisher(for: NSTextView.didChangeSelectionNotification, object: textView)
            .map { $0.object as! NSTextView }
            .filter { !$0.hasMarkedText() }
            // avoid updating outline item selection before finishing outline parse
            // -> Otherwise, a wrong item can be selected because of using the outdated outline ranges.
            //    You can ignore text selection change at this time point as the outline selection will be updated when the parse finished.
            .filter { $0.textStorage?.editedMask.contains(.editedCharacters) == false }
            .debounce(for: 0.05, scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.invalidateOutlineMenuSelection() }
        
        self.updateOutlineMenu()
    }
    
    
    override func viewDidDisappear() {
        
        super.viewDidDisappear()
        
        self.splitViewObservers.removeAll()
        self.orientationObserver = nil
        self.selectionObserver = nil
    }
    
    
    
    // MARK: Public Methods
    
    /// Can select the prev item in outline menu?
    var canSelectPrevItem: Bool {
        
        guard let textView = self.textView else { return false }
        
        return self.outlineItems?.previousItem(for: textView.selectedRange) != nil
    }
    
    
    /// Can select the next item in outline menu?
    var canSelectNextItem: Bool {
        
        guard let textView = self.textView else { return false }
        
        return self.outlineItems?.nextItem(for: textView.selectedRange) != nil
    }
    
    
    
    // MARK: Action Messages
    
    /// Select outline menu item from the popup menu.
    @IBAction func selectOutlineMenuItem(_ sender: NSMenuItem) {
        
        guard
            let textView = self.textView,
            let range = sender.representedObject as? NSRange
            else { return assertionFailure() }
        
        textView.select(range: range)
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
    
    
    /// The split view controller managing editor split.
    private var splitViewController: SplitViewController? {
        
        guard let parent = self.parent else { return nil }
        
        return sequence(first: parent, next: \.parent)
            .first { $0 is SplitViewController } as? SplitViewController
    }
    
    
    private var prevButton: NSButton? {
        
        return (self.textView?.layoutOrientation == .vertical) ? self.rightButton : self.leftButton
    }
    
    
    private var nextButton: NSButton? {
        
        return (self.textView?.layoutOrientation == .vertical) ? self.leftButton : self.rightButton
    }
    
    
    /// Build outline menu from `outlineItems`.
    private func updateOutlineMenu() {
        
        self.isParsingOutline = (self.outlineItems == nil)
        self.showsOutlineMenu = (self.outlineItems?.isEmpty == false)
        
        guard let outlineItems = self.outlineItems else { return }
        guard let outlineMenu = self.outlineMenu?.menu else { return assertionFailure() }
        
        outlineMenu.items = outlineItems
            .flatMap { (outlineItem) -> [NSMenuItem] in
                switch outlineItem.title {
                    case .separator:
                        // dummy item to avoid merging sequential separators into a single separator
                        let dummyItem = NSMenuItem()
                        dummyItem.view = NSView()
                        
                        return [.separator(), dummyItem]
                        
                    default:
                        let menuItem = NSMenuItem()
                        menuItem.attributedTitle = outlineItem.attributedTitle(for: outlineMenu.font, attributes: [.paragraphStyle: self.menuItemParagraphStyle])
                        menuItem.representedObject = outlineItem.range
                        
                        return [menuItem]
                }
            }
        
        self.invalidateOutlineMenuSelection()
    }
    
    
    /// Select the proper item in outline menu based on the current selection in the text view.
    private func invalidateOutlineMenuSelection() {
        
        guard
            self.showsOutlineMenu,
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
                self.leftButton?.image = Chevron.up.image
                self.rightButton?.image = Chevron.down.image
            case .vertical:
                self.leftButton?.image = Chevron.left.image
                self.rightButton?.image = Chevron.right.image
            @unknown default:
                fatalError()
        }
        
        self.prevButton?.action = #selector(EditorViewController.selectPrevItemOfOutlineMenu)
        self.prevButton?.target = self.parent
        self.prevButton?.toolTip = "Jump to previous outline item".localized
        self.prevButton?.isEnabled = self.canSelectPrevItem
        
        self.nextButton?.action = #selector(EditorViewController.selectNextItemOfOutlineMenu)
        self.nextButton?.target = self.parent
        self.nextButton?.toolTip = "Jump to next outline item".localized
        self.nextButton?.isEnabled = self.canSelectNextItem
    }
    
}



private enum Chevron: String {
    
    case left
    case right
    case up
    case down
    
    
    var image: NSImage {
        
        let name = "chevron." + self.rawValue
        
        guard #available(macOS 10.16, *) else {
            return NSImage(imageLiteralResourceName: name)
        }
        
        return NSImage(systemSymbolName: name, accessibilityDescription: self.rawValue)!
    }
}
