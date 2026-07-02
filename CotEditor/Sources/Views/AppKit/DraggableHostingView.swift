//
//  DraggableHostingView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2022-07-22.
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

import AppKit
import SwiftUI

private struct Edge {
    
    enum Horizontal { case left, right }
    enum Vertical { case top, bottom }
    
    var horizontal: Horizontal
    var vertical: Vertical
}


final class DraggableHostingView<Content>: NSHostingView<Content> where Content: View {
    
    // MARK: Private Properties
    
    private var clickedPoint: NSPoint = .zero
    private var liveResizingEdge: Edge?
    
    
    // MARK: View Methods
    
    override var frame: NSRect {
        
        didSet {
            guard frame != oldValue else { return }
            
            var frame = self.frame
            if frame.width != oldValue.width {
                frame.origin.x += oldValue.width - frame.width
            }
            self.setConstrainedFrame(frame)
        }
    }
    
    
    override func viewWillStartLiveResize() {
        
        super.viewWillStartLiveResize()
        
        self.liveResizingEdge = self.nearestEdge
    }
    
    
    override func viewDidEndLiveResize() {
        
        super.viewDidEndLiveResize()
        
        self.liveResizingEdge = nil
    }
    
    
    override func resize(withOldSuperviewSize oldSize: NSSize) {
        
        super.resize(withOldSuperviewSize: oldSize)
        
        guard let superview = self.superview else { return }
        
        var frame = self.frame
        
        // stick to the nearest edge
        if let preferredEdge = self.liveResizingEdge ?? self.nearestEdge {
            if preferredEdge.horizontal == .right {
                frame.origin.x += superview.bounds.width - oldSize.width
            }
            if preferredEdge.vertical == .top {
                frame.origin.y += superview.bounds.height - oldSize.height
            }
        }
        
        self.setConstrainedFrame(frame)
    }
    
    
    override func mouseDown(with event: NSEvent) {
        
        self.clickedPoint = self.convert(event.locationInWindow, from: nil)
    }
    
    
    override func mouseDragged(with event: NSEvent) {
        
        guard let superview = self.superview else { return }
        
        let origin = superview
            .convert(event.locationInWindow, from: nil)
            .offset(by: -self.clickedPoint)
        self.setConstrainedFrame(NSRect(origin: origin, size: self.frame.size))
    }
}


// MARK: Private Extension

private extension NSView {
    
    /// The nearest edge of the superview to the receiver.
    var nearestEdge: Edge? {
        
        self.superview.map { superview in
            Edge(horizontal: superview.bounds.midX < self.frame.midX ? .right : .left,
                 vertical: superview.bounds.midY < self.frame.midY ? .top : .bottom)
        }
    }
    
    
    /// Sets the given frame clamped inside the superview margins.
    ///
    /// - Parameter frame: The frame to set in the superview coordinate system.
    func setConstrainedFrame(_ frame: NSRect) {
        
        guard let superview else { return assertionFailure() }
        
        let insets = superview.edgeInsets(for: .margins())
        let bounds = superview.bounds
        
        var frame = frame
        let minX = bounds.minX + insets.left
        let maxX = bounds.maxX - frame.width - insets.right
        frame.origin.x.clamp(to: minX...max(maxX, minX))
        
        let minY = bounds.minY + insets.bottom
        let maxY = bounds.maxY - frame.height - insets.top
        frame.origin.y.clamp(to: minY...max(maxY, minY))
        
        guard self.frame != frame else { return }
        
        self.frame = frame
    }
}
