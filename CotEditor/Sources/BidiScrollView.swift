//
//  BidiScrollView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2022-03-27.
//
//  ---------------------------------------------------------------------------
//
//  © 2022 1024jp
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
final class BidiScrollView: NSScrollView {
    
    // MARK: Public Properties
    
    var scrollerDirection: NSUserInterfaceLayoutDirection = .rightToLeft  { didSet { self.tile() } }
    
    
    
    // MARK: View Methods
    
    override func awakeFromNib() {
        
        assert(self.verticalScroller is BidiScroller)
        assert(self.horizontalScroller is BidiScroller)
        assert(self.userInterfaceLayoutDirection == .leftToRight,
               "Consider if the UI direction is RTL and the scroller direction is LTR.")
        
        super.awakeFromNib()
    }
    
    
    override func tile() {
        
        super.tile()
       
        // add a space for the vertical scroller to the left edge if the style is legacy
        guard
            self.scrollerDirection == .rightToLeft,
            self.scrollerStyle == .legacy,
            self.hasVerticalScroller,
            let scroller = self.verticalScroller,
            !scroller.isHidden
        else { return }
        
        let scrollerThickness = scroller.thickness
        
        if self.contentInsets != .zero, self.contentInsets.right != 0 {
            self.contentView.contentInsets.left += scrollerThickness
            self.contentView.contentInsets.right -= scrollerThickness
            
        } else {
            self.contentView.frame.origin.x = scrollerThickness
        }
    }
}



extension NSEdgeInsets: Equatable {
    
    static let zero = NSEdgeInsetsZero
    
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        
        lhs.left == rhs.left &&
        lhs.top == rhs.top &&
        lhs.right == rhs.right &&
        lhs.bottom == rhs.bottom
    }
}
