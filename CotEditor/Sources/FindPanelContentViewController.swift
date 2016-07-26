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

class FindPanelContentViewController: NSSplitViewController, CETextFinderDelegate {
    
    // MARK: Private Properties
    
    private var isUncollapsing = false
    
    @IBOutlet private var fieldSplitViewItem: NSSplitViewItem?
    @IBOutlet private var resultSplitViewItem: NSSplitViewItem?
    
    
    
    // MARK:
    // MARK: Split View Controller Methods
    
    /// set delegate
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        CETextFinder.shared().delegate = self
    }
    
    
    /// setup UI
    override func viewDidDisappear() {
        
        super.viewDidDisappear()
        
        self.setResultShown(false, animate: false)
    }
    
    
    /// collapse result view by dragging divider
     override func splitViewDidResizeSubviews(_ notification: Notification) {
        
        guard !self.isUncollapsing else { return }
        
        self.collapseResultViewIfNeeded()
    }
    
    
    /// avoid showing draggable cursor when result view collapsed
     override func splitView(_ splitView: NSSplitView, effectiveRect proposedEffectiveRect: NSRect, forDrawnRect drawnRect: NSRect, ofDividerAt dividerIndex: Int) -> NSRect {
        
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
        self.fieldViewController?.updateResultCount(results.count, target: textView)
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
    
    /// unwrap viewController from split view item
    private var fieldViewController: FindPanelFieldViewController? {
        
        return self.fieldSplitViewItem?.viewController as? FindPanelFieldViewController
    }
    
    
    /// unwrap viewController from split view item
    private var resultViewController: FindPanelResultViewController? {
        
        return self.resultSplitViewItem?.viewController as? FindPanelResultViewController
    }
    
    
    /// toggle result view visibility with/without animation
    private func setResultShown(_ shown: Bool, animate: Bool) {
        
        guard let resultView = self.resultViewController?.view,
              let panel = self.view.window else { return }
        
        let height = resultView.bounds.height
        
        guard (shown && resultView.isHidden) || (!shown || height <= DefaultResultViewHeight) else { return }
        
        // resize panel frame
        var panelFrame = panel.frame
        let diff: CGFloat = {
            if shown {
                if self.resultSplitViewItem!.isCollapsed {
                    return DefaultResultViewHeight
                } else {
                    return DefaultResultViewHeight - height
                }
            } else {
                return  -height
            }
        }()
        panelFrame.size.height += diff
        panelFrame.origin.y -= diff
        
        // uncollapse if needed
        if shown {
            self.isUncollapsing = true
            self.resultSplitViewItem?.isCollapsed = !shown
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
        
        guard let resultView = self.resultViewController?.view,
            !resultView.isHidden && resultView.visibleRect.isEmpty else { return }
        
        self.resultSplitViewItem?.isCollapsed = true
    }
    
}
