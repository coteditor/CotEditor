/*
 
 EditorSplitView.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2014-07-26.
 
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

class EditorSplitView: NSSplitView {
    
    // MARK: Split View Methods
    
    /// change divider style depending on its split orientation
    override var isVertical: Bool {
        
        didSet {
            self.dividerStyle = isVertical ? .thin : .paneSplitter
        }
    }
    
    
    /// override divider color
    override var dividerColor: NSColor {
        
        return .windowFrameColor()
    }
    
}
