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
//  © 2014-2025 1024jp
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

final class FindPanelContentViewController: NSSplitViewController {
    
    // MARK: Private Properties
    
    private static let defaultResultViewHeight: Double = 200
    
    private let resultModel = FindPanelResultView.Model()
    
    @ViewLoading private var fieldSplitViewItem: NSSplitViewItem
    @ViewLoading private var resultSplitViewItem: NSSplitViewItem
    
    private var resultObservationTask: Task<Void, Never>?
    
    
    // MARK: Lifecycle
    
    deinit {
        self.resultObservationTask?.cancel()
    }
    
    
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
        
        let fieldViewItem = NSSplitViewItem(viewController: NSHostingController(rootView: FindPanelFieldView()))
        self.fieldSplitViewItem = fieldViewItem
        
        let resultViewItem = NSSplitViewItem(viewController: NSHostingController(rootView: FindPanelResultView(model: self.resultModel)))
        resultViewItem.isCollapsed = true
        resultViewItem.collapseBehavior = .preferResizingSplitViewWithFixedSiblings
        self.resultSplitViewItem = resultViewItem
        
        let buttonViewItem = NSSplitViewItem(viewController: NSHostingController(rootView: FindPanelButtonView()))
        
        self.splitViewItems = [fieldViewItem, resultViewItem, buttonViewItem]
        
        self.resultObservationTask = Task { [weak self] in
            for await userInfo in NotificationCenter.default.notifications(named: TextFinder.DidFindAllMessage.name).compactMap({ $0.userInfo }) {
                guard
                    let matches = userInfo["matches"] as? [FindAllMatch],
                    let findString = userInfo["findString"] as? String
                else { continue }
                
                let client = userInfo["client"] as? NSTextView
                self?.didFinishFindAll(matches, for: findString, in: client)
            }
        }
    }
    
    
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        self.fieldSplitViewItem.holdingPriority = .defaultLow + 1
    }
    
    
    override func viewDidDisappear() {
        
        super.viewDidDisappear()
        
        self.fieldSplitViewItem.holdingPriority = .defaultHigh
        self.resultSplitViewItem.isCollapsed = true
    }
    
    
    // MARK: Split View Controller Methods
    
    override func splitViewDidResizeSubviews(_ notification: Notification) {
        
        super.splitViewDidResizeSubviews(notification)
        
        // collapse result view if closed
        let item = self.resultSplitViewItem
        
        if let view = item.viewController.viewIfLoaded,
           view.frame.height < 1
        {
            item.isCollapsed = true
        }
    }
    
    
    override func splitView(_ splitView: NSSplitView, effectiveRect proposedEffectiveRect: NSRect, forDrawnRect drawnRect: NSRect, ofDividerAt dividerIndex: Int) -> NSRect {
        
        // avoid showing draggable cursor when result view collapsed
        self.resultSplitViewItem.isCollapsed ? .zero : proposedEffectiveRect
    }
    
    
    // MARK: Action Messages
    
    /// Closes the find result view.
    @IBAction func closeResultView(_ sender: Any?) {
        
        self.setResultShown(false)
    }
    
    
    // MARK: Private Methods
    
    /// Notifies the completion of the Find All command.
    ///
    /// - Parameters:
    ///   - result: The all found matches.
    ///   - findString: The find string.
    ///   - client: The text view where searched.
    private func didFinishFindAll(_ matches: [FindAllMatch], for findString: String, in client: NSTextView?) {
        
        self.resultModel.matches = matches
        self.resultModel.findString = findString
        self.resultModel.target = client
        
        guard !matches.isEmpty else { return }
        
        self.setResultShown(true)
        self.splitView.window?.windowController?.showWindow(self)
    }
    
    
    /// Toggles the visibility of the result view with animation.
    ///
    /// - Parameter shown: `true` to open the result view; otherwise, `false`.
    private func setResultShown(_ shown: Bool) {
        
        let item = self.resultSplitViewItem
        
        if shown {
            item.viewController.view.frame.size.height.clamp(to: Self.defaultResultViewHeight...(.infinity))
        }
        item.animator().isCollapsed = !shown
    }
}
