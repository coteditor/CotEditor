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
//  © 2015-2023 1024jp
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

final class FindPanelTextClipView: NSClipView {
    
    // MARK: Private Properties
    
    private let leadingPadding: CGFloat = 30  // for history button
    private let trailingPadding: CGFloat = 22  // for clear button
    
    
    
    // MARK: -
    // MARK: View Methods
    
    override var frame: NSRect {
        
        didSet {
            // add paddings
            // -> Just setting .contentInsets doesn't work with the pinch-zoom (macOS 14, 2023-11).
            let leftPadding = self.userInterfaceLayoutDirection == .leftToRight ? self.leadingPadding : self.trailingPadding
            
            guard frame.minX < leftPadding else { return }  // avoid infinity loop
            
            frame.origin.x += leftPadding
            frame.size.width -= self.leadingPadding + self.trailingPadding
        }
    }
}
