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

private let defaultResultViewHeight: CGFloat = 200

final class FindPanelContentViewController: NSSplitViewController {
    
    // MARK: Private Properties
    
    private var resultSplitViewItem: NSSplitViewItem?
    
    private var isUncollapsing = false
    private var resultObserver: AnyCancellable?
    
    
    
    // MARK: -
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
        
        self.splitView.identifier = NSUserInterfaceItemIdentifier("FindPanelSplitView")
        self.splitView.autosaveName = "FindPanelSplitView"
        
        let fieldViewItem = NSSplitViewItem(viewController: NSStoryboard(name: "FindPanelFieldView").instantiateInitialController()!)
        fieldViewItem.holdingPriority = .init(251)
        
        let resultViewItem = NSSplitViewItem(viewController: NSHostingController(rootView: FindPanelResultView()))
        resultViewItem.isCollapsed = true
        self.resultSplitViewItem = resultViewItem
        
        let buttonViewItem = NSSplitViewItem(viewController: NSHostingController(rootView: FindPanelButtonView()))
        
        self.splitViewItems = [fieldViewItem, resultViewItem, buttonViewItem]
        
        self.resultObserver = NotificationCenter.default.publisher(for: TextFinder.didFindAllNotification)
            .compactMap { $0.object as? TextFinder }
            .sink { [weak self] in self?.didFinishFindAll(in: $0) }
    }
    
    
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        // make sure the result view is closed
        self.setResultShown(false, animate: false)
    }
    
    
    /// collapse result view by dragging divider
    override func splitViewDidResizeSubviews(_ notification: Notification) {
        
        super.splitViewDidResizeSubviews(notification)
        
        guard !self.isUncollapsing else { return }
        
        self.collapseResultViewIfNeeded()
    }
    
    
    /// avoid showing draggable cursor when result view collapsed
    override func splitView(_ splitView: NSSplitView, effectiveRect proposedEffectiveRect: NSRect, forDrawnRect drawnRect: NSRect, ofDividerAt dividerIndex: Int) -> NSRect {
        
        let effectiveRect = super.splitView(splitView, effectiveRect: proposedEffectiveRect, forDrawnRect: drawnRect, ofDividerAt: dividerIndex)
        
        if splitView.isSubviewCollapsed(splitView.subviews[dividerIndex + 1]) || dividerIndex == 1 {
            return .zero
        }
        
        return effectiveRect
    }
    
    
    
    // MARK: Action Messages
    
    /// close opening find result view
    @IBAction func closeResultView(_ sender: Any?) {
        
        self.setResultShown(false, animate: true)
    }
    
    
    
    // MARK: Private Methods
    
    /// The view controller for the result view.
    private var resultViewController: NSHostingController<FindPanelResultView>? {
        
        self.resultSplitViewItem?.viewController as? NSHostingController<FindPanelResultView>
    }
    
    
    /// Completion notification of the Find All command.
    ///
    /// - Parameter textFinder: The TextFinder that did Find All.
    private func didFinishFindAll(in textFinder: TextFinder) {
        
        guard let result = textFinder.findAllResult else { return }
        
        self.resultViewController?.setResult(result, for: textFinder.client)
        
        guard !result.matches.isEmpty else { return }
        
        self.setResultShown(true, animate: true)
        self.splitView.window?.windowController?.showWindow(self)
    }
    
    
    /// toggle result view visibility with/without animation
    private func setResultShown(_ shown: Bool, animate: Bool) {
        
        guard
            let resultViewItem = self.resultSplitViewItem,
            let panel = self.splitView.window
        else { return assertionFailure() }
        
        let resultView = resultViewItem.viewController.view
        let height = resultView.bounds.height
        
        // resize panel frame
        let diff: CGFloat = {
            if shown {
                if resultViewItem.isCollapsed {
                    return defaultResultViewHeight
                } else {
                    return max(defaultResultViewHeight - height, 0)
                }
            } else {
                return -height
            }
        }()
        var panelFrame = panel.frame
        panelFrame.size.height += diff
        panelFrame.origin.y -= diff
        
        // uncollapse if needed
        if shown {
            self.isUncollapsing = true
            resultViewItem.isCollapsed = !shown
            resultView.isHidden = false
        }
        
        panel.setFrame(panelFrame, display: true, animate: animate)
        
        self.isUncollapsing = false
        if !shown {
            self.collapseResultViewIfNeeded()
        }
    }
    
    
    /// collapse result view if closed
    private func collapseResultViewIfNeeded() {
        
        guard
            let resultViewController = self.resultViewController,
            resultViewController.isViewShown,
            resultViewController.view.visibleRect.isEmpty
        else { return }
        
        self.resultSplitViewItem?.isCollapsed = true
        self.splitView.needsDisplay = true
    }
}
