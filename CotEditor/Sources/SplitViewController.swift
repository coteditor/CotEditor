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
//  © 2014-2023 1024jp
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
    
    @Published private(set) var isVertical = false
    @Published private(set) var canCloseSplitItem = false
    
    
    // MARK: Public Properties
    
    private var focuedEditorObserver: AnyCancellable?
    
    
    
    // MARK: -
    // MARK: Split View Controller Methods
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.splitView.isVertical = UserDefaults.standard[.splitViewVertical]
        self.isVertical = self.splitView.isVertical
        
        // observe focus change
        self.focuedEditorObserver = NotificationCenter.default.publisher(for: EditorTextView.didBecomeFirstResponderNotification)
            .map { $0.object as! EditorTextView }
            .compactMap { [weak self] textView in
                self?.children.lazy
                    .compactMap { $0 as? EditorViewController }
                    .first { $0.textView == textView }
            }
            .sink { [weak self] in self?.focusedChild = $0 }
    }
    
    
    override func removeSplitViewItem(_ splitViewItem: NSSplitViewItem) {
        
        super.removeSplitViewItem(splitViewItem)
        
        self.canCloseSplitItem = self.splitViewItems.count > 1
    }
    
    
    override func validateUserInterfaceItem(_ item: any NSValidatedUserInterfaceItem) -> Bool {
        
        switch item.action {
            case #selector(toggleSplitOrientation):
                (item as? NSMenuItem)?.title = self.splitView.isVertical
                    ? "Stack Editors Horizontally".localized
                    : "Stack Editors Vertically".localized
                
            case #selector(focusNextSplitTextView), #selector(focusPrevSplitTextView):
                return self.splitViewItems.count > 1
                
            default: break
        }
        
        return super.validateUserInterfaceItem(item)
    }
    
    
    
    // MARK: Public Methods
    
    /// add subview for given viewController at desired position
    func addChild(_ editorViewController: EditorViewController, relativeTo otherEditorViewController: EditorViewController?) {
        
        let splitViewItem = NSSplitViewItem(viewController: editorViewController)
        splitViewItem.holdingPriority = NSLayoutConstraint.Priority(251)
        
        if let otherEditorViewController {
            guard let baseIndex = self.children.firstIndex(of: otherEditorViewController) else {
                return assertionFailure("The base editor view is not belong to the same window.")
            }
            
            self.insertSplitViewItem(splitViewItem, at: baseIndex + 1)
            
        } else {
            self.addSplitViewItem(splitViewItem)
        }
        
        self.canCloseSplitItem = true
    }
    
    
    
    // MARK: Action Messages
    
    /// toggle divider orientation
    @IBAction func toggleSplitOrientation(_ sender: Any?) {
        
        self.splitView.isVertical.toggle()
        
        self.isVertical = self.splitView.isVertical
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
    
    /// Move focus to the next/previous text view.
    ///
    /// - Parameter onNext: Move to the next if `true`, otherwise previous.
    private func focusSplitTextView(onNext: Bool) {
        
        let children = self.children.compactMap { $0 as? EditorViewController }
        
        guard children.count > 1 else { return }
        guard let focusedChild = self.focusedChild,
              let focusIndex = children.firstIndex(of: focusedChild),
              let nextChild = onNext
                ? children[safe: focusIndex + 1] ?? children.first
                : children[safe: focusIndex - 1] ?? children.last
        else { return assertionFailure() }
        
        self.view.window?.makeFirstResponder(nextChild.textView)
    }
}
