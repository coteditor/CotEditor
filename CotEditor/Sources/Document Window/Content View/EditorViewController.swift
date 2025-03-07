//
//  EditorViewController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by nakamuxu on 2006-03-18.
//
//  ---------------------------------------------------------------------------
//
//  © 2004-2007 nakamuxu
//  © 2014-2024 1024jp
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
import SwiftUI
import Combine
import Defaults

final class EditorViewController: NSSplitViewController {
    
    // MARK: Public Properties
    
    var textView: EditorTextView?  { self.textViewController.textView }
    
    
    // MARK: Private Properties
    
    private let document: Document
    private let splitState: SplitState
    
    private lazy var outlineNavigator = OutlineNavigator()
    private lazy var textViewController = EditorTextViewController(document: self.document)
    @ViewLoading private var navigationBarItem: NSSplitViewItem
    
    private var observers: Set<AnyCancellable> = []
    
    
    // MARK: Lifecycle
    
    init(document: Document, splitState: SplitState) {
        
        self.document = document
        self.splitState = splitState
        
        super.init(nibName: nil, bundle: nil)
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.splitView.isVertical = false
        
        // setup navigation bar
        self.outlineNavigator.textView = self.textView
        let navigationBar = NavigationBar(outlineNavigator: self.outlineNavigator, splitState: self.splitState)
        self.navigationBarItem = NSSplitViewItem(viewController: NSHostingController(rootView: navigationBar))
        self.navigationBarItem.isCollapsed = !UserDefaults.standard[.showNavigationBar]
        self.addSplitViewItem(self.navigationBarItem)
        
        // setup text view controller
        self.addChild(self.textViewController)
        
        // set accessibility
        self.view.setAccessibilityElement(true)
        self.view.setAccessibilityRole(.group)
        self.view.setAccessibilityLabel(String(localized: "Editor", table: "Document", comment: "accessibility label"))
    }
    
    
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        self.navigationBarItem.isCollapsed = !UserDefaults.standard[.showNavigationBar]
        
        self.outlineNavigator.items = self.document.syntaxParser.outlineItems
        self.textView?.lineEnding = self.document.lineEnding
        self.textView?.mode = ModeManager.shared.setting(for: self.document.mode)
        self.applySyntax()
        
        // observe document and defaults
        self.observers = [
            self.document.syntaxParser.$outlineItems
                .removeDuplicates()
                .receive(on: RunLoop.main)
                .sink { [weak self] in self?.outlineNavigator.items = $0 },
            self.document.$lineEnding
                .receive(on: RunLoop.main)
                .sink { [weak self] in self?.textView?.lineEnding = $0 },
            self.document.didChangeSyntax
                .sink { [weak self] _ in self?.applySyntax() },
            self.document.$mode
                .removeDuplicates()
                .sink { [weak self] in self?.textView?.mode = ModeManager.shared.setting(for: $0) },
            UserDefaults.standard.publisher(for: .showNavigationBar)
                .sink { [weak self] in self?.navigationBarItem.animator().isCollapsed = !$0 },
        ]
    }
    
    
    override func viewDidDisappear() {
        
        super.viewDidDisappear()
        
        self.observers.removeAll()
    }
    
    
    // MARK: Split View Controller Methods
    
    override func splitView(_ splitView: NSSplitView, effectiveRect proposedEffectiveRect: NSRect, forDrawnRect drawnRect: NSRect, ofDividerAt dividerIndex: Int) -> NSRect {
        
        // avoid showing draggable cursor for the navigation bar boundary
        .zero
    }
    
    
    override func validateUserInterfaceItem(_ item: any NSValidatedUserInterfaceItem) -> Bool {
        
        switch item.action {
            case #selector(toggleNavigationBar):
                (item as? NSMenuItem)?.title = !self.navigationBarItem.isCollapsed
                    ? String(localized: "Hide Navigation Bar", table: "MainMenu")
                    : String(localized: "Show Navigation Bar", table: "MainMenu")
                
            case #selector(openOutlineMenu):
                return self.outlineNavigator.items?.isEmpty == false
                
            case #selector(selectPrevItemOfOutlineMenu):
                return self.outlineNavigator.canSelectPreviousItem
                
            case #selector(selectNextItemOfOutlineMenu):
                return self.outlineNavigator.canSelectNextItem
                
            default: break
        }
        
        return super.validateUserInterfaceItem(item)
    }
    
    
    // MARK: Public Methods
    
    /// Whether line number view is visible.
    var showsLineNumber: Bool {
        
        get { self.textViewController.showsLineNumber }
        set { self.textViewController.showsLineNumber = newValue }
    }
    
    
    // MARK: Action Messages
    
    /// Toggles visibility of navigation bar with fancy animation (sync all documents).
    @IBAction func toggleNavigationBar(_ sender: Any?) {
        
        UserDefaults.standard[.showNavigationBar].toggle()
    }
    
    
    /// Shows the menu items of the outline menu in the navigation bar.
    @IBAction func openOutlineMenu(_ sender: Any) {
        
        self.navigationBarItem.isCollapsed = false
        self.outlineNavigator.isOutlinePickerPresented = true
    }
    
    
    /// Selects the previous outline item.
    @IBAction func selectPrevItemOfOutlineMenu(_ sender: Any?) {
        
        self.outlineNavigator.selectPreviousItem()
    }
    
    
    /// Selects the next outline item.
    @IBAction func selectNextItemOfOutlineMenu(_ sender: Any?) {
        
        self.outlineNavigator.selectNextItem()
    }
    
    
    // MARK: Private Methods
    
    /// Applies syntax to the inner text view.
    private func applySyntax() {
        
        guard let textView = self.textView else { return assertionFailure() }
        
        let parser = self.document.syntaxParser
        textView.syntaxName = parser.name
        textView.commentDelimiters = parser.syntax.commentDelimiters
        textView.syntaxCompletionWords = parser.syntax.completionWords
    }
}
