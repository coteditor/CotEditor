//
//  EditorClipView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-11-18.
//
//  ---------------------------------------------------------------------------
//
//  © 2018 1024jp
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

import Cocoa

final class EditorClipView: NSClipView {
    
    override func constrainBoundsRect(_ proposedBounds: NSRect) -> NSRect {
        
        var bounds = super.constrainBoundsRect(proposedBounds)
        
        // avoid that the documentView tucks under the ruler views (2018-11 macOS 10.14)
        // -> This is a super dirty workaround, but no better way.
        if bounds.minX <= 0 {
            bounds.origin.x = -self.contentInsets.left
        }
        if bounds.minY <= 0 {
            bounds.origin.y = -self.contentInsets.top
        }
        
        return bounds
    }
    
}
