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
import Combine

final class SplitViewController: NSSplitViewController {
    
    // MARK: Public Properties
    
    private(set) weak var focusedChild: EditorViewController?
    
    @Published private(set) var canCloseSplitItem = false
    
    
    // MARK: Private Properties
    
    private var focusedEditorObserver: AnyCancellable?
    
    
    
    // MARK: Split View Controller Methods
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.splitView.isVertical = UserDefaults.standard[.splitViewVertical]
        
        // observe focus change
        self.focusedEditorObserver = NotificationCenter.default.publisher(for: EditorTextView.didBecomeFirstResponderNotification)
            .map { $0.object as! EditorTextView }
            .compactMap { [weak self] textView in
                self?.children.lazy
                    .compactMap { $0 as? EditorViewController }
                    .first { $0.textView == textView }
            }
            .sink { [weak self] in self?.focusedChild = $0 }
    }
    
    
    override func insertSplitViewItem(_ splitViewItem: NSSplitViewItem, at index: Int) {
        
        super.insertSplitViewItem(splitViewItem, at: index)
        
        self.canCloseSplitItem = self.splitViewItems.count > 1
    }
    
    
    override func removeChild(at index: Int) {
        
        super.removeChild(at: index)
        
        self.canCloseSplitItem = self.splitViewItems.count > 1
    }
    
    
    override func validateUserInterfaceItem(_ item: any NSValidatedUserInterfaceItem) -> Bool {
        
        switch item.action {
            case #selector(toggleSplitOrientation):
                (item as? NSMenuItem)?.title = self.splitView.isVertical
                    ? String(localized: "Stack Editors Horizontally", table: "MainMenu")
                    : String(localized: "Stack Editors Vertically", table: "MainMenu")
                
            case #selector(focusNextSplitTextView), #selector(focusPrevSplitTextView):
                return self.splitViewItems.count > 1
                
            default: break
        }
        
        return super.validateUserInterfaceItem(item)
    }
    
    
    
    // MARK: Action Messages
    
    /// Toggles divider orientation.
    @IBAction func toggleSplitOrientation(_ sender: Any?) {
        
        self.splitView.isVertical.toggle()
        
        UserDefaults.standard[.splitViewVertical] = self.splitView.isVertical
    }
    
    
    /// Moves focus to the next text view.
    @IBAction func focusNextSplitTextView(_ sender: Any?) {
        
        self.focusSplitTextView(onNext: true)
    }
    
    
    /// Moves focus to the previous text view.
    @IBAction func focusPrevSplitTextView(_ sender: Any?) {
        
        self.focusSplitTextView(onNext: false)
    }
    
    
    
    // MARK: Private Methods
    
    /// Moves focus to the next/previous text view.
    ///
    /// - Parameter onNext: Move to the next if `true`, otherwise previous.
    private func focusSplitTextView(onNext: Bool) {
        
        let children = self.splitViewItems.compactMap { $0.viewController as? EditorViewController }
        
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
