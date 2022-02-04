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
//  © 2014-2022 1024jp
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

final class EditorViewController: NSSplitViewController {
    
    // MARK: Public Properties
    
    var textView: EditorTextView? {
        
        return self.textViewController?.textView
    }
    
    var outlineItems: [OutlineItem]? {
        
        didSet {
            self.navigationBarController?.outlineItems = outlineItems
        }
    }
    
    
    // MARK: Private Properties
    
    @IBOutlet private weak var navigationBarItem: NSSplitViewItem?
    @IBOutlet private weak var textViewItem: NSSplitViewItem?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    deinit {
        // detach layoutManager safely
        guard
            let textStorage = self.textView?.textStorage,
            let layoutManager = self.textView?.layoutManager
            else { return assertionFailure() }
        
        textStorage.removeLayoutManager(layoutManager)
    }
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.navigationBarController?.textView = self.textView
        
        // set accessibility
        self.view.setAccessibilityElement(true)
        self.view.setAccessibilityRole(.group)
        self.view.setAccessibilityLabel("editor".localized)
    }
    
    
    
    // MARK: Split View Controller Methods
    
    /// Avoid showing draggable cursor.
    override func splitView(_ splitView: NSSplitView, effectiveRect proposedEffectiveRect: NSRect, forDrawnRect drawnRect: NSRect, ofDividerAt dividerIndex: Int) -> NSRect {
        
        // -> Super's delegate method must be called anyway.
        super.splitView(splitView, effectiveRect: proposedEffectiveRect, forDrawnRect: drawnRect, ofDividerAt: dividerIndex)
        
        return .zero
    }
    
    
    override func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        
        switch item.action {
            case #selector(openOutlineMenu):
                return self.outlineItems?.isEmpty == false
                
            case #selector(selectPrevItemOfOutlineMenu):
                guard let textView = self.textView else { return false }
                return self.outlineItems?.previousItem(for: textView.selectedRange) != nil
            
            case #selector(selectNextItemOfOutlineMenu):
                guard let textView = self.textView else { return false }
                return self.outlineItems?.nextItem(for: textView.selectedRange) != nil
            
            default: break
        }
        
        return super.validateUserInterfaceItem(item)
    }
    
    
    
    // MARK: Public Methods
    
    /// Whether line number view is visible.
    var showsLineNumber: Bool {
        
        get { self.textViewController?.showsLineNumber ?? false }
        set { self.textViewController?.showsLineNumber = newValue }
    }
    
    
    /// Whether navigation bar is visible.
    var showsNavigationBar: Bool {
        
        get { self.navigationBarItem?.isCollapsed == false }
        set { self.navigationBarItem?.isCollapsed = !newValue }
    }
    
    
    /// Set textStorage to the inner text view.
    ///
    /// - Parameter textStorage: The text storage to set.
    func setTextStorage(_ textStorage: NSTextStorage) {
        
        guard let textView = self.textView else { return assertionFailure() }
        
        textView.layoutManager?.replaceTextStorage(textStorage)
        
        if textView.isAutomaticLinkDetectionEnabled {
            textView.detectLink()
        }
    }
    
    
    /// Apply syntax style to the inner text view.
    ///
    /// - Parameter style: The syntax style to apply.
    func apply(style: SyntaxStyle) {
        
        guard let textView = self.textView else { return assertionFailure() }
        
        textView.inlineCommentDelimiter = style.inlineCommentDelimiter
        textView.blockCommentDelimiters = style.blockCommentDelimiters
        textView.syntaxCompletionWords = style.completionWords
    }
    
    
    
    // MARK: Action Messages
    
    @IBAction func openOutlineMenu(_ sender: Any) {
        
        self.showsNavigationBar = true
        self.navigationBarController?.openOutlineMenu()
    }
    
    /// Select the previous outline menu item.
    @IBAction func selectPrevItemOfOutlineMenu(_ sender: Any?) {
        
        guard
            let textView = self.textView,
            let item = self.outlineItems?.previousItem(for: textView.selectedRange)
        else { return }
        
        textView.select(range: item.range)
    }
    
    
    /// Select the next outline menu item.
    @IBAction func selectNextItemOfOutlineMenu(_ sender: Any?) {
        
        guard
            let textView = self.textView,
            let item = self.outlineItems?.nextItem(for: textView.selectedRange)
        else { return }
        
        textView.select(range: item.range)
    }
    
    
    
    // MARK: Private Methods
    
    private var navigationBarController: NavigationBarController? {
        
        return self.navigationBarItem?.viewController as? NavigationBarController
    }
    
    
    private var textViewController: EditorTextViewController? {
        
        return self.textViewItem?.viewController as? EditorTextViewController
    }
    
}
