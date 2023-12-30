//
//  FindPanelContentViewController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-06-26.
//
//  ---------------------------------------------------------------------------
//
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

import AppKit
import SwiftUI
import Combine

final class FindPanelContentViewController: NSSplitViewController {
    
    // MARK: Private Properties
    
    private static let defaultResultViewHeight: Double = 200
    
    private var fieldSplitViewItem: NSSplitViewItem?
    private var resultSplitViewItem: NSSplitViewItem?
    
    private var resultObserver: AnyCancellable?
    
    
    
    // MARK: Split View Controller Methods
    
    override func loadView() {
        
        self.splitView = FindPanelSplitView()
        self.splitView.isVertical = false
        self.splitView.dividerStyle = .thin
        
        self.view = NSView()
        self.view.addSubview(self.splitView)
        
        self.splitView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.view.topAnchor.constraint(equalTo: self.splitView.topAnchor),
            self.view.bottomAnchor.constraint(equalTo: self.splitView.bottomAnchor),
            self.view.leadingAnchor.constraint(equalTo: self.splitView.leadingAnchor),
            self.view.trailingAnchor.constraint(equalTo: self.splitView.trailingAnchor),
        ])
    }
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        let fieldViewItem = NSSplitViewItem(viewController: NSHostingController(rootView: FindPanelMainView()))
        self.fieldSplitViewItem = fieldViewItem
        
        let resultViewItem = NSSplitViewItem(viewController: FindPanelResultViewController())
        resultViewItem.isCollapsed = true
        resultViewItem.collapseBehavior = .preferResizingSplitViewWithFixedSiblings
        self.resultSplitViewItem = resultViewItem
        
        let buttonViewItem = NSSplitViewItem(viewController: NSHostingController(rootView: FindPanelButtonView()))
        
        self.splitViewItems = [fieldViewItem, resultViewItem, buttonViewItem]
        
        self.resultObserver = NotificationCenter.default.publisher(for: TextFinder.didFindAllNotification)
            .compactMap { $0.object as? TextFinder }
            .sink { [weak self] in self?.didFinishFindAll(in: $0) }
    }
    
    
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        self.fieldSplitViewItem?.holdingPriority = .defaultLow + 1
        
    }
    
    
    override func viewWillDisappear() {
        
        super.viewWillDisappear()
        
        self.fieldSplitViewItem?.holdingPriority = .defaultHigh
        self.resultSplitViewItem?.isCollapsed = true
    }
    
    
    override func splitViewDidResizeSubviews(_ notification: Notification) {
        
        super.splitViewDidResizeSubviews(notification)
        
        // collapse result view if closed
        if let item = self.resultSplitViewItem,
           item.viewController.isViewShown,
           item.viewController.view.frame.height < 1
        {
            item.isCollapsed = true
        }
    }
    
    
    override func splitView(_ splitView: NSSplitView, effectiveRect proposedEffectiveRect: NSRect, forDrawnRect drawnRect: NSRect, ofDividerAt dividerIndex: Int) -> NSRect {
        
        // avoid showing draggable cursor when result view collapsed
        (self.resultSplitViewItem?.isCollapsed == true) ? .zero : proposedEffectiveRect
    }
    
    
    
    // MARK: Action Messages
    
    /// Closes the find result view.
    @IBAction func closeResultView(_ sender: Any?) {
        
        self.setResultShown(false)
    }
    
    
    
    // MARK: Private Methods
    
    /// The view controller for the result view.
    private var resultViewController: FindPanelResultViewController? {
        
        self.resultSplitViewItem?.viewController as? FindPanelResultViewController
    }
    
    
    /// Notifies the completion of the Find All command.
    ///
    /// - Parameter textFinder: The TextFinder that did Find All.
    private func didFinishFindAll(in textFinder: TextFinder) {
        
        guard let result = textFinder.findAllResult else { return }
        
        self.resultViewController?.setResult(result, for: textFinder.client)
        
        guard !result.matches.isEmpty else { return }
        
        self.setResultShown(true)
        self.splitView.window?.windowController?.showWindow(self)
    }
    
    
    /// Toggles the visibility of the result view with animation.
    ///
    /// - Parameter shown: `true` to open the result view; otherwise, `false`.
    private func setResultShown(_ shown: Bool) {
        
        guard let item = self.resultSplitViewItem else { return assertionFailure() }
        
        if shown {
            item.viewController.view.frame.size.height.clamp(to: Self.defaultResultViewHeight...(.infinity))
        }
        item.animator().isCollapsed = !shown
    }
}
