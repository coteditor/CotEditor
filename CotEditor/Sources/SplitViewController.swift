//
//  SplitViewController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by nakamuxu on 2006-03-26.
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

final class SplitViewController: NSSplitViewController {
    
    // MARK: Public Properties
    
    private(set) weak var focusedChild: EditorViewController?
    
    
    // MARK: Public Properties
    
    private var focuedEditorObserver: AnyCancellable?
    
    
    
    // MARK: -
    // MARK: Split View Controller Methods
    
    /// setup view
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.splitView.isVertical = UserDefaults.standard[.splitViewVertical]
        self.invalidateOpenSplitEditorButtons()
        
        // observe focus change
        self.focuedEditorObserver = NotificationCenter.default.publisher(for: EditorTextView.didBecomeFirstResponderNotification)
            .map { $0.object as! EditorTextView }
            .sink { [weak self] textView in
                guard
                    let viewController = self?.children.lazy
                        .compactMap({ $0 as? EditorViewController })
                        .first(where: { $0.textView == textView })
                    else { return }
                
                self?.focusedChild = viewController
            }
    }
    
    
    /// update close split view button state after remove
    override func removeSplitViewItem(_ splitViewItem: NSSplitViewItem) {
        
        super.removeSplitViewItem(splitViewItem)
        
        self.invalidateCloseSplitEditorButtons()
    }
    
    
    /// workaround for crash on macOS 10.12 – macOS 10.15.
    override func splitView(_ splitView: NSSplitView, shouldHideDividerAt dividerIndex: Int) -> Bool {
        
        return false
    }
    
    
    /// apply current state to related menu items
    override func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        
        switch item.action {
            case #selector(toggleSplitOrientation):
                if let item = item as? NSMenuItem {
                    let title = self.splitView.isVertical ? "Stack Editors Horizontally" : "Stack Editors Vertically"
                    item.title = title.localized
                }
                return self.splitViewItems.count > 1
            
            case #selector(focusNextSplitTextView), #selector(focusPrevSplitTextView):
                return self.splitViewItems.count > 1
            
            default: break
        }
        
        return super.validateUserInterfaceItem(item)
    }
    
    
    
    // MARK: Public Methods
    
    /// add subview for given viewController at desired position
    func addSubview(for editorViewController: EditorViewController, relativeTo otherEditorViewController: EditorViewController?) {
        
        let splitViewItem = NSSplitViewItem(viewController: editorViewController)
        splitViewItem.holdingPriority = NSLayoutConstraint.Priority(251)
        
        if let otherEditorViewController = otherEditorViewController {
            guard let baseIndex = self.children.firstIndex(of: otherEditorViewController) else {
                return assertionFailure("The base editor view is not belong to the same window.")
            }
            
            self.insertSplitViewItem(splitViewItem, at: baseIndex + 1)
            
        } else {
            self.addSplitViewItem(splitViewItem)
        }
        
        self.invalidateOpenSplitEditorButtons()
        self.invalidateCloseSplitEditorButtons()
    }
    
    
    /// find viewController for given subview
    func viewController(for subview: NSView) -> EditorViewController? {
        
        return self.children.lazy
            .compactMap { $0 as? EditorViewController }
            .first { $0.splitView == subview }
    }
    
    
    
    // MARK: Action Messages
    
    /// toggle divider orientation
    @IBAction func toggleSplitOrientation(_ sender: Any?) {
        
        self.splitView.isVertical.toggle()
        
        self.invalidateOpenSplitEditorButtons()
    }
    
    
    /// move focus to next text view
    @IBAction func focusNextSplitTextView(_ sender: Any?) {
        
        self.focusSplitTextView(onNext: true)
    }
    
    
    /// move focus to previous text view
    @IBAction func focusPrevSplitTextView(_ sender: Any?) {
        
        self.focusSplitTextView(onNext: false)
    }
    
    
    
    // MARK: Private Methods
    
    /// move focus to next/previous text view
    private func focusSplitTextView(onNext: Bool) {
        
        let count = self.splitViewItems.count
        
        guard count > 1 else { return }
        
        let focusIndex = self.children.firstIndex(of: self.focusedChild!) ?? 0
        let index: Int = {
            switch focusIndex {
                case 0 where !onNext:
                    return count - 1
                case count - 1 where onNext:
                    return 0
                default:
                    return focusIndex + (onNext ? 1 : -1)
            }
        }()
        
        guard let nextEditorViewController = self.children[index] as? EditorViewController else { return }
        
        self.view.window?.makeFirstResponder(nextEditorViewController.textView)
    }
    
    
    /// update "Split Editor" button state
    private func invalidateOpenSplitEditorButtons() {
        
        let isVertical = self.splitView.isVertical
        
        for case let viewController as EditorViewController in self.children {
            viewController.navigationBarController?.isSplitOrientationVertical = isVertical
        }
    }
    
    
    /// update "Close Split Editor" button state
    private func invalidateCloseSplitEditorButtons() {
        
        let isEnabled = self.splitViewItems.count > 1
        
        for case let viewController as EditorViewController in self.children {
            viewController.navigationBarController?.isCloseSplitButtonEnabled = isEnabled
        }
    }
    
}
