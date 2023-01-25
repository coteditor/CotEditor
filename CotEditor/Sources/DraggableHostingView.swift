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
import SwiftUI

private struct Edge {
    
    enum Horizontal {
        
        case left
        case right
    }
    
    
    enum Vertical {
        
        case top
        case bottom
    }
    
    
    var horizontal: Horizontal?
    var vertical: Vertical?
}



final class DraggableHostingView<Content>: NSHostingView<Content> where Content: View {
    
    // MARK: Public Properties
    
    let margin: CGFloat = 10
    
    
    // MARK: Private Properties
    
    private var clickedPoint: NSPoint = .zero
    private var liveResigingEdge: Edge?
    
    
    
    // MARK: -
    // MARK: View Methods
    
    override var frame: NSRect {
        
        didSet {
            guard frame != oldValue else { return }
            
            if frame.width != oldValue.width {
                self.frame.origin.x += oldValue.width - self.frame.width
            }
            self.adjustPosition()
        }
    }
    
    
    override func viewWillStartLiveResize() {
        
        super.viewWillStartLiveResize()
        
        self.liveResigingEdge = self.prefferedEdge
    }
    
    
    override func viewDidEndLiveResize() {
        
        super.viewDidEndLiveResize()
        
        self.liveResigingEdge = nil
    }
    
    
    override func resize(withOldSuperviewSize oldSize: NSSize) {
        
        super.resize(withOldSuperviewSize: oldSize)
        
        guard let superview = self.superview else { return }
        
        // stick to the nearest edge
        if (self.liveResigingEdge ?? self.prefferedEdge)?.horizontal == .right {
            self.frame.origin.x += superview.frame.width - oldSize.width
        }
        if (self.liveResigingEdge ?? self.prefferedEdge)?.vertical == .top {
            self.frame.origin.y += superview.frame.height - oldSize.height
        }
        
        self.adjustPosition()
    }
    
    
    override func mouseDown(with event: NSEvent) {
        
        self.clickedPoint = self.convert(event.locationInWindow, from: nil)
    }
    
    
    override func mouseDragged(with event: NSEvent) {
        
        guard let superview = self.superview else { return }
        
        self.frame.origin = superview.convert(event.locationInWindow, from: nil)
            .offset(by: -self.clickedPoint)
    }
    
    
    
    // MARK: Private Methods
    
    /// The area the receiver located in the superview.
    @MainActor private var prefferedEdge: Edge? {
        
        self.superview.flatMap { (superview) in
            Edge(horizontal: superview.frame.width/2 < self.frame.midX ? .right : .left,
                 vertical: superview.frame.height/2 < self.frame.midY ? .top : .bottom)
        }
    }
    
    
    /// Keep position to be inside of the parent frame.
    @MainActor private func adjustPosition() {
        
        guard let superFrame = self.superview?.frame else { return assertionFailure() }
        
        let maxX = superFrame.width - self.frame.width - self.margin
        if self.margin < maxX {
            self.frame.origin.x.clamp(to: self.margin...maxX)
        }
        
        let maxY = superFrame.height - self.frame.height - self.margin
        if self.margin < maxY {
            self.frame.origin.y.clamp(to: self.margin...maxY)
        }
    }
}
