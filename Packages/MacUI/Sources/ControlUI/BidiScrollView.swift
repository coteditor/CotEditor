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
    
    
    // MARK: Lifecycle
    
    public override init(frame frameRect: NSRect) {
        
        super.init(frame: frameRect)
        
        self.contentView = BidiClipView()
    }
    
    
    public required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: View Methods
    
    public override var contentInsets: NSEdgeInsets {
        
        get { super.contentInsets }
        
        set {
            // pin the insets to the stable values
            // -> The automatic content inset adjustment varies insets
            //    depending on the scroll position or the document state,
            //    which can cause an infinite layout loop (2026-07, macOS 27, FB23993752).
            var insets = newValue
            if self.automaticallyAdjustsContentInsets {
                insets = NSEdgeInsets(top: self.safeAreaInsets.top, left: 0,
                                      bottom: self.safeAreaInsets.bottom, right: 0)
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
        
        // update the areas that the clip view carves out of the scroll view bounds
        // -> The standard tile() implementation does not reserve the areas for ruler views,
        //    and shrinking the clip view frame afterward here causes repeated frame changes
        //    that make the document view slightly scroll on every layout pass;
        //    therefore, let the clip view lay itself out on its own (2026-08, macOS 27).
        (self.contentView as? BidiClipView)?.frameInsets = self.clipViewFrameInsets
        
        super.tile()
        
        self.adjustClipViewContentInsets()
        
        if self.isInconsistentContentDirection {
            self.tileScrollers()
        }
        
        self.tileVerticalRulerView()
        self.tileHorizontalRulerView()
    }
    
    
    // MARK: Private Methods
    
    /// Whether the content direction and user interface layout direction are inconsistent.
    private var isInconsistentContentDirection: Bool {
        
        self.contentDirection != self.userInterfaceLayoutDirection
    }
    
    
    /// The areas the clip view should carve out of the scroll view bounds.
    private var clipViewFrameInsets: NSEdgeInsets {
        
        var insets = NSEdgeInsets()
        
        // reserve the areas for the visible ruler views
        if self.rulersVisible {
            if self.hasVerticalRuler, let rulerView = self.verticalRulerView, !rulerView.isHidden {
                switch self.contentDirection {
                    case .leftToRight:
                        insets.left = rulerView.requiredThickness
                    case .rightToLeft:
                        insets.right = rulerView.requiredThickness
                    @unknown default:
                        assertionFailure()
                }
            }
            if self.hasHorizontalRuler, let rulerView = self.horizontalRulerView, !rulerView.isHidden {
                insets.top = rulerView.requiredThickness
            }
        }
        
        // reserve the areas for scrollers with the legacy scroller style
        // -> The `legacy` scroller style is used when the user sets
        //    System Settings > Appearances > Show scroll bars to “Always.” (2025-07, macOS 15)
        if self.scrollerStyle == .legacy {
            if self.hasVerticalScroller, let scroller = self.verticalScroller, !scroller.isHidden {
                switch self.contentDirection {
                    case .leftToRight:
                        insets.right += scroller.thickness
                    case .rightToLeft:
                        insets.left += scroller.thickness
                    @unknown default:
                        assertionFailure()
                }
            }
            if self.hasHorizontalScroller, let scroller = self.horizontalScroller, !scroller.isHidden {
                insets.bottom += scroller.thickness
            }
        }
        
        return insets
    }
    
    
    /// Horizontally flips the scroller drawing if required.
    private func invalidateScrollerFlipState() {
        
        guard let verticalScroller else { return assertionFailure() }
        
        verticalScroller.layer?.sublayerTransform = self.isInconsistentContentDirection
            ? CATransform3DConcat(CATransform3DMakeScale(-1, 1, 1),
                                  CATransform3DMakeTranslation(verticalScroller.bounds.width, 0, 0))
            : CATransform3DIdentity
    }
    
    
    /// Applies the vertical scroll view insets to the clip view.
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
        
        // constrain the scroll position within the new insets
        // -> The scroll position is not re-clamped automatically on inset changes.
        self.contentView.scroll(to: self.contentView.constrainBoundsRect(self.contentView.bounds).origin)
    }
    
    
    /// Lays out the vertical ruler view next to the clip view by taking the content layout direction into the account.
    private func tileVerticalRulerView() {
        
        guard
            self.hasVerticalRuler,
            self.rulersVisible,
            let rulerView = self.verticalRulerView,
            !rulerView.isHidden
        else { return }
        
        let contentFrame = self.contentView.frame
        let originX = (self.contentDirection == .rightToLeft)
            ? contentFrame.maxX
            : contentFrame.minX - rulerView.requiredThickness
        
        guard rulerView.frame.origin.x != originX else { return }
        
        rulerView.frame.origin.x = originX
        rulerView.needsDisplay = true
    }
    
    
    /// Lays out the horizontal ruler view next to the clip view.
    private func tileHorizontalRulerView() {
        
        guard
            self.hasHorizontalRuler,
            self.rulersVisible,
            let rulerView = self.horizontalRulerView,
            !rulerView.isHidden
        else { return }
        
        let originY = self.contentView.frame.minY - rulerView.requiredThickness
        
        guard rulerView.frame.origin.y != originY else { return }
        
        rulerView.frame.origin.y = originY
        rulerView.needsDisplay = true
    }
    
    
    /// Horizontally lays out the scrollers by taking the content layout direction into the account.
    private func tileScrollers() {
        
        assert(self.isInconsistentContentDirection)
        
        guard let verticalScroller else { return }
        
        verticalScroller.frame.origin.x = if self.contentDirection == .leftToRight {
            // move vertical scroller to the right side
            self.frame.width - verticalScroller.thickness
        } else {
            0
        }
        
        guard let horizontalScroller else { return }
        
        horizontalScroller.frame.origin.x = if self.contentDirection == .rightToLeft,
                                               self.scrollerStyle == .legacy,
                                               self.hasVerticalScroller,
                                               !verticalScroller.isHidden
        {
            // give a space for the vertical scroller
            verticalScroller.thickness
        } else {
            0
        }
    }
}


// MARK: -

/// A clip view that lays itself out in the enclosing scroll view on its own
/// by carving the areas for ruler views and legacy style scrollers out of the scroll view bounds.
///
/// Reserving these areas by shrinking the clip view frame instead of by the content insets
/// guarantees that the contents are never drawn behind the ruler views
/// even when the document view is scrollable in the ruler thickness direction
/// or the background is not opaque.
/// In addition, ignoring the frame proposed by the scroll view stabilizes the layout
/// because the standard tile() implementation changes the frame reservation policy
/// depending on the document state (2026-08, macOS 27).
private final class BidiClipView: NSClipView {
    
    /// The insets to carve the clip view area out of the enclosing scroll view bounds.
    var frameInsets = NSEdgeInsets() {
        
        didSet {
            guard frameInsets != oldValue else { return }
            
            // apply the new insets immediately
            // -> The scroll view skips laying out the clip view
            //    when the frame it proposes is the same as the current frame.
            //    Invoke the super's implementations directly to avoid applying the insets twice
            //    because `setFrame(_:)` internally calls `setFrameOrigin(_:)` and `setFrameSize(_:)` of self.
            guard let frame = self.insetFrame else { return }
            
            super.setFrameOrigin(frame.origin)
            super.setFrameSize(frame.size)
        }
    }
    
    
    override func setFrameOrigin(_ newOrigin: NSPoint) {
        
        super.setFrameOrigin(self.insetFrame?.origin ?? newOrigin)
    }
    
    
    override func setFrameSize(_ newSize: NSSize) {
        
        super.setFrameSize(self.insetFrame?.size ?? newSize)
    }
    
    
    /// The frame rect to be placed in the enclosing scroll view.
    private var insetFrame: NSRect? {
        
        guard let scrollView = unsafe self.superview as? NSScrollView else { return nil }
        
        let bounds = scrollView.bounds
        
        // take only the border into account because frameInsets reserves the scroller areas separately
        let contentSize = BidiScrollView.contentSize(forFrameSize: bounds.size, horizontalScrollerClass: nil, verticalScrollerClass: nil, borderType: scrollView.borderType, controlSize: .regular, scrollerStyle: scrollView.scrollerStyle)
        let borderWidth = bounds.width - contentSize.width
        let borderHeight = bounds.height - contentSize.height
        
        return NSRect(x: bounds.minX + borderWidth / 2 + self.frameInsets.left,
                      y: bounds.minY + borderHeight / 2 + self.frameInsets.top,
                      width: max(0, contentSize.width - self.frameInsets.left - self.frameInsets.right),
                      height: max(0, contentSize.height - self.frameInsets.top - self.frameInsets.bottom))
    }
}


private extension NSScroller {
    
    /// The scroller width calculated using the current settings.
    var thickness: CGFloat {
        
        Self.scrollerWidth(for: self.controlSize, scrollerStyle: self.scrollerStyle)
    }
}
