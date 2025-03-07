//
//  BidiScrollView.swift
//  BidiScrollView
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2022-03-27.
//
//  ---------------------------------------------------------------------------
//
//  © 2022-2025 1024jp
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

/// A scroll view that allows switching the vertical scroller position regardless of the user interface layout direction.
///
/// The implementation referred a lot to <https://github.com/aiaf/MKKRightToLeftScrollView>. Thank you!
public final class BidiScrollView: NSScrollView {
    
    // MARK: Public Properties
    
    public var scrollerDirection: NSUserInterfaceLayoutDirection = .rightToLeft  { didSet { self.tile() } }
    
    
    // MARK: internal Properties
    
    var isInconsistentScrollerDirection: Bool { self.scrollerDirection != self.userInterfaceLayoutDirection }
    
    
    // MARK: View Methods
    
    public override init(frame frameRect: NSRect) {
        
        super.init(frame: frameRect)
        
        self.verticalScroller = BidiScroller()
        self.horizontalScroller = BidiScroller()
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    public override func tile() {
        
        super.tile()
        
        // add a space for the vertical scroller to the left edge if the style is legacy
        guard
            self.isInconsistentScrollerDirection,
            self.scrollerStyle == .legacy,
            self.hasVerticalScroller,
            let scroller = self.verticalScroller,
            !scroller.isHidden
        else { return }
        
        let scrollerThickness = scroller.thickness
        
        switch self.scrollerDirection {
            case .leftToRight:
                if self.contentInsets.left != 0 {
                    self.contentView.contentInsets.left -= scrollerThickness
                    self.contentView.contentInsets.right += scrollerThickness
                } else {
                    self.contentView.frame.origin.x = 0
                }
            case .rightToLeft:
                if self.contentInsets.right != 0 {
                    self.contentView.contentInsets.left += scrollerThickness
                    self.contentView.contentInsets.right -= scrollerThickness
                } else {
                    self.contentView.frame.origin.x = scrollerThickness
                }
            @unknown default:
                assertionFailure()
        }
    }
}
