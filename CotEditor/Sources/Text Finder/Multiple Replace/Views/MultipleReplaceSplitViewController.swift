//
//  MultipleReplaceSplitViewController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2017-03-17.
//
//  ---------------------------------------------------------------------------
//
//  © 2017-2024 1024jp
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

final class MultipleReplaceSplitViewController: NSSplitViewController {
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // -> Need to set *both* identifier and autosaveName to make autosaving work.
        self.splitView.identifier = NSUserInterfaceItemIdentifier("MultipleReplaceSplitView")
        self.splitView.autosaveName = "MultipleReplaceSplitView"
        
        let listViewController: NSViewController = NSStoryboard(name: "MultipleReplaceListView", bundle: nil).instantiateInitialController()!
        let detailViewController: NSViewController = NSStoryboard(name: "MultipleReplaceView", bundle: nil).instantiateInitialController()!
        
        self.splitViewItems = [
            NSSplitViewItem(contentListWithViewController: listViewController),
            NSSplitViewItem(viewController: detailViewController),
        ]
    }
}
