//
//  NSSplitViewController+Autosave.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-08-23.
//
//  ---------------------------------------------------------------------------
//
//  © 2018-2019 1024jp
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

extension NSSplitViewController {
    
    /// restore divider positions based on the autosaved data
    func restoreAutosavePositions() {
        
        guard
            let autosaveName = self.splitView.autosaveName,
            let subviewFrames = UserDefaults.standard.stringArray(forKey: "NSSplitView Subview Frames " + autosaveName),
            subviewFrames.count == self.splitViewItems.count
            else { return }
        
        guard subviewFrames.allSatisfy({ !NSRectFromString($0).isEmpty }) else { return }
        
        for (item, frameString) in zip(self.splitViewItems, subviewFrames) {
            // set divider position
            item.viewController.view.frame = NSRectFromString(frameString)
            
            // set visibility
            if let value = frameString.components(separatedBy: ", ")[safe: 4] {
                item.isCollapsed = (value as NSString).boolValue
            }
        }
    }
    
}
