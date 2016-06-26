/*
 
 FindPanelContentViewController.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-06-26.
 
 ------------------------------------------------------------------------------
 
 © 2014-2016 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Cocoa

private let DefaultResultViewHeight: CGFloat = 200.0

class FindPanelContentViewController: NSViewController, NSSplitViewDelegate, CETextFinderDelegate {
    
    // MARK: Private Properties
    
    private var isUncollapsing = false
    
    @IBOutlet private weak var splitView: NSSplitView?
    @IBOutlet private var fieldViewController: FindPanelFieldViewController?
    @IBOutlet private var resultViewController: FindPanelResultViewController?
    
    
    
    // MARK:
    // MARK: Creation
    
    deinit {
        self.splitView?.delegate = nil  // NSSplitView's delegate is assign, not weak
    }
    
    
    
    /// setup UI
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        self.setResultShown(false, animate: false)
    }
    
    
    
    // MARK: Split View Delegate
    
    /// collapse result view by dragging divider
     func splitViewDidResizeSubviews(_ notification: Notification) {
        
        guard !self.isUncollapsing else { return }
        
        self.collapseResultViewIfNeeded()
    }
    
    
    /// only result view can collapse
     func splitView(_ splitView: NSSplitView, canCollapseSubview subview: NSView) -> Bool {
        
        return subview == self.resultViewController?.view
    }
    
    
    /// avoid showing draggable cursor when result view collapsed
     func splitView(_ splitView: NSSplitView, effectiveRect proposedEffectiveRect: NSRect, forDrawnRect drawnRect: NSRect, ofDividerAt dividerIndex: Int) -> NSRect {
        
        var effectiveRect = proposedEffectiveRect
        
        if splitView.isSubviewCollapsed(splitView.subviews[dividerIndex + 1]) || dividerIndex == 1 {
            effectiveRect.size = NSZeroSize
        }
        
        return effectiveRect
    }
    
    
    
    // MARK: TextFinder Delegate
    
    /// complemention notification for "Find All"
    func textFinder(_ textFinder: CETextFinder, didFinishFindingAll findString: String, results: [TextFindResult], textView: NSTextView) {
        
        // set to result table
        self.resultViewController?.setResults(results, findString: findString, target: textView)
        
        self.setResultShown(true, animate: true)
        self.view.window?.windowController?.showWindow(self)
    }
    
    
    /// recieve number of found
    func textFinder(_ textFinder: CETextFinder, didFound numberOfFound: Int, textView: NSTextView) {
        
        self.fieldViewController?.updateResultCount(numberOfFound, target: textView)
    }
    
    
    
    // MARK: Action Messages
    
    /// close opening find result view
    @IBAction func closeResultView(_ sender: AnyObject?) {
        
        self.setResultShown(false, animate: true)
    }
    
    
    
    // MARK: Private Methods
    
    /// toggle result view visibility with/without animation
    private func setResultShown(_ shown: Bool, animate: Bool) {
        
        guard let resultView = self.resultViewController?.view,
            let panel = self.view.window else { return }
        
        let height = resultView.bounds.height
        
        guard (shown && resultView.isHidden) || (!shown || height <= DefaultResultViewHeight) else { return }
        
        // uncollapse if needed
        if shown {
            self.isUncollapsing = true
            resultView.isHidden = false
        }
        
        // resize panel frame
        var panelFrame = panel.frame
        let diff = shown ? DefaultResultViewHeight - height : -height
        panelFrame.size.height += diff
        panelFrame.origin.y -= diff
        
        panel.setFrame(panelFrame, display: true, animate: animate)
        
        self.isUncollapsing = false
        if !shown {
            self.collapseResultViewIfNeeded()
        }
    }
    
    
    /// collapse result view if closed
    private func collapseResultViewIfNeeded() {
        
        guard let resultView = self.resultViewController?.view
            where !resultView.isHidden && resultView.visibleRect.isEmpty else { return }
        
        resultView.isHidden = true
        self.splitView!.needsDisplay = true
    }
    
}
