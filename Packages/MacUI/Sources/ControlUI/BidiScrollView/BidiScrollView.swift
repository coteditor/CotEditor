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

public import AppKit

/// A scroll view that allows switching the vertical scroller position regardless of the user interface layout direction.
///
/// The implementation referred a lot to <https://github.com/aiaf/MKKRightToLeftScrollView>. Thank you!
public final class BidiScrollView: NSScrollView {
    
    // MARK: Public Properties
    
    public var contentDirection: NSUserInterfaceLayoutDirection = .rightToLeft  { didSet { self.tile() } }
    
    
    // MARK: Internal Properties
    
    var isInconsistentContentDirection: Bool { self.contentDirection != self.userInterfaceLayoutDirection }
    
    
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
        
        guard self.isInconsistentContentDirection else { return }
        
        self.tileScrollers()
        self.adjustContentInsets()
        self.tileRulerView()
    }
    
    
    // MARK: Private Methods
    
    /// Adjusts the content insets by taking the preserved scroller area for the legacy scroll style into the account.
    ///
    /// - Note: The `legacy` scroller style is used when the user sets System Settings > Appearances > Show scroll bars to “Always.” (2025-07, macOS 15)
    private func adjustContentInsets() {
        
        assert(self.isInconsistentContentDirection)
        
        guard
            self.scrollerStyle == .legacy,
            self.hasVerticalScroller,
            let scroller = self.verticalScroller,
            !scroller.isHidden
        else { return }
        
        let thickness = scroller.thickness
        
        switch self.contentDirection {
            case .leftToRight:
                if self.contentInsets.left != 0 {
                    self.contentView.contentInsets.left -= thickness
                    self.contentView.contentInsets.right += thickness
                } else {
                    self.contentView.frame.origin.x = 0
                }
            case .rightToLeft:
                if self.contentInsets.right != 0 {
                    self.contentView.contentInsets.left += thickness
                    self.contentView.contentInsets.right -= thickness
                } else {
                    self.contentView.frame.origin.x = thickness
                }
            @unknown default:
                break
        }
    }
    
    
    /// Lays out the vertical ruler view by taking the content layout direction into the account.
    private func tileRulerView() {
        
        assert(self.isInconsistentContentDirection)
        
        guard
            self.hasVerticalRuler,
            self.rulersVisible,
            let rulerView = self.verticalRulerView,
            !rulerView.isHidden
        else { return }
        
        switch self.contentDirection {
            case .leftToRight:
                rulerView.frame.origin.x = 0
                self.contentView.contentInsets.right = 0
            case .rightToLeft:
                rulerView.frame.origin.x = self.frame.maxX - rulerView.requiredThickness
                self.contentView.contentInsets.left = 0
            @unknown default:
                assertionFailure()
        }
    }
    
    
    /// Horizontally lays out the scrollers by taking the content layout direction into the account.
    private func tileScrollers() {
        
        assert(self.isInconsistentContentDirection)
        
        guard let verticalScroller else { return }
        
        let inset = self.contentInsets.left + self.scrollerInsets.left
        
        verticalScroller.frame.origin.x = if self.contentDirection == .leftToRight {
            // move vertical scroller to the right side
            self.frame.width - verticalScroller.thickness
        } else {
            inset
        }
        
        guard let horizontalScroller else { return }
        
        horizontalScroller.frame.origin.x = if self.contentDirection == .rightToLeft,
                                               self.scrollerStyle == .legacy,
                                               self.hasVerticalScroller,
                                               !verticalScroller.isHidden
        {
            // give a space for the vertical scroller
            inset + verticalScroller.thickness
        } else {
            inset
        }
    }
}
