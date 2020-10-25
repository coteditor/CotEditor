//
//  FindPanelTextClipView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2015-03-05.
//
//  ---------------------------------------------------------------------------
//
//  © 2015-2020 1024jp
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

final class FindPanelTextClipView: NSClipView {
    
    // MARK: Private Properties
    
    private let leadingPadding: CGFloat = 30  // for history button
    private let tailingPadding: CGFloat = 22  // for clear button
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    required init?(coder: NSCoder) {
        
        super.init(coder: coder)
        
        // make sure frame to be initialized (Otherwise, input area can be arranged in a wrong place.)
        let frame = self.frame
        self.frame = frame
    }
    
    
    
    // MARK: View Methods
    
    /// add paddings
    override var frame: NSRect {
        
        didSet {
            guard frame.minX < self.leadingPadding else { return }  // avoid infinity loop
            
            frame.origin.x += self.leadingPadding
            frame.size.width -= self.leadingPadding
            frame.size.width -= self.tailingPadding
        }
    }
    
}
