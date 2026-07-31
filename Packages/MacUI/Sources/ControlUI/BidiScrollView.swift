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
//  © 2022-2026 1024jp
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
public final class BidiScrollView: NSScrollView {
    
    // MARK: Public Properties
    
    public var contentDirection: NSUserInterfaceLayoutDirection = .rightToLeft {
        
        didSet {
            self.tile()
            self.invalidateScrollerFlipState()
        }
    }
    
    
    // MARK: Private Properties
    
    /// The number of content inset changes in the current runloop turn.
    private var insetsChangeCount = 0
    
    
    // MARK: View Methods
    
    public override var contentInsets: NSEdgeInsets {
        
        get { super.contentInsets }
        
        set {
            // pin the vertical insets to the safe area
            // -> The automatic content inset adjustment varies insets depending on the scroll position,
            //    which can cause an infinite layout loop (2026-07, macOS 27, FB23993752).
            var insets = newValue
            if self.automaticallyAdjustsContentInsets {
                insets.top = self.safeAreaInsets.top
                insets.bottom = self.safeAreaInsets.bottom
            }
            
            guard insets != super.contentInsets else { return }
            
            // limit the number of inset changes per runloop turn to break an infinite layout loop
            // -> The safe area insets themselves oscillate during the layout pass
            //    for the first window presentation while the window chrome is being resolved
            //    (2026-07, macOS 27, FB23993752).
            self.insetsChangeCount += 1
            if self.insetsChangeCount == 1 {
                DispatchQueue.main.async { [weak self] in
                    self?.insetsChangeCount = 0
                }
            }
            guard self.insetsChangeCount <= 2 else { return }
            
            super.contentInsets = insets
        }
    }
    
    
    public override func tile() {
        
        super.tile()
        
        self.adjustClipViewContentInsets()
        
        if self.isInconsistentContentDirection {
            self.tileScrollers()
            self.adjustContentInsets()
        }
        
        self.tileVerticalRulerView()
        self.tileHorizontalRulerView()
    }
    
    
    // MARK: Private Methods
    
    /// Whether the content direction and user interface layout direction are inconsistent.
    private var isInconsistentContentDirection: Bool {
        
        self.contentDirection != self.userInterfaceLayoutDirection
    }
    
    
    /// Horizontally flips the scroller drawing if required.
    private func invalidateScrollerFlipState() {
        
        guard let verticalScroller else { return assertionFailure() }
        
        verticalScroller.layer?.sublayerTransform = self.isInconsistentContentDirection
            ? CATransform3DConcat(CATransform3DMakeScale(-1, 1, 1),
                                  CATransform3DMakeTranslation(verticalScroller.bounds.width, 0, 0))
            : CATransform3DIdentity
    }
    
    
    /// Applies vertical scroll view insets to the clip view.
    private func adjustClipViewContentInsets() {
        
        guard !self.contentView.automaticallyAdjustsContentInsets else { return }
        
        // apply the safe area insets instead of the content insets
        // -> The automatic content insets vary depending on the visible content position,
        //    and applying them to the clip view moves the content,
        //    which can cause an infinite layout loop (2026-07, macOS 27, FB23993752).
        let insets = NSEdgeInsets(top: self.safeAreaInsets.top, left: 0,
                                  bottom: self.safeAreaInsets.bottom, right: 0)
        
        // avoid dirtying the layout by re-applying the same insets
        guard insets != self.contentView.contentInsets else { return }
        
        self.contentView.contentInsets = insets
    }
    
    
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
    private func tileVerticalRulerView() {
        
        guard
            self.hasVerticalRuler,
            self.rulersVisible,
            let rulerView = self.verticalRulerView,
            !rulerView.isHidden
        else { return }
        
        let rulerThickness = rulerView.requiredThickness
        var contentFrame = self.contentView.frame
        let contentWidth = max(0, contentFrame.width - rulerThickness)
        
        switch self.contentDirection {
            case .leftToRight:
                rulerView.frame.origin.x = contentFrame.minX
                contentFrame.origin.x = contentFrame.maxX - contentWidth
                contentFrame.size.width = contentWidth
            case .rightToLeft:
                rulerView.frame.origin.x = contentFrame.maxX - rulerThickness
                contentFrame.size.width = contentWidth
            @unknown default:
                assertionFailure()
        }
        
        self.contentView.frame = contentFrame
    }
    
    
    /// Lays out the content view for the horizontal ruler view.
    private func tileHorizontalRulerView() {
        
        guard
            self.hasHorizontalRuler,
            self.rulersVisible,
            let rulerView = self.horizontalRulerView,
            !rulerView.isHidden
        else { return }
        
        var contentFrame = self.contentView.frame
        let contentHeight = max(0, contentFrame.height - rulerView.requiredThickness)
        
        contentFrame.origin.y = contentFrame.maxY - contentHeight
        contentFrame.size.height = contentHeight
        
        self.contentView.frame = contentFrame
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


private extension NSScroller {
    
    /// The scroller width calculated using the current settings.
    var thickness: CGFloat {
        
        Self.scrollerWidth(for: self.controlSize, scrollerStyle: self.scrollerStyle)
    }
}
