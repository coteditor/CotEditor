//
//  HoleContentView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2023-08-11.
//
//  ---------------------------------------------------------------------------
//
//  © 2023-2024 1024jp
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
import Combine

final class HoleContentView: NSView {
    
    // MARK: Private Properties
    
    @Invalidating(.display) private var holes: [NSRect] = []
    
    private var windowOpacityObserver: AnyCancellable?
    private var holeViewObserver: AnyCancellable?
    
    
    // MARK: View Methods
    
    override var isOpaque: Bool {
        
        self.holes.isEmpty
    }
    
    
    override func viewWillMove(toWindow newWindow: NSWindow?) {
        
        super.viewWillMove(toWindow: newWindow)
        
        self.holeViewObserver?.cancel()
        self.holeViewObserver = nil
        
        self.windowOpacityObserver?.cancel()
        self.windowOpacityObserver = newWindow?.publisher(for: \.isOpaque, options: .initial)
            .sink { [unowned self] isOpaque in
                self.invalidateHoles(isOpaque: isOpaque)
                
                self.holeViewObserver?.cancel()
                self.holeViewObserver = if isOpaque {
                    nil
                } else {
                    NotificationCenter.default.publisher(for: NSView.frameDidChangeNotification)
                        .map { $0.object as! NSView }
                        .filter { $0 is NSStackView }
                        .filter { $0.isDescendant(of: self) }
                        .sink { [unowned self] _ in self.invalidateHoles(isOpaque: false) }
                }
            }
    }
    
    
    override func draw(_ dirtyRect: NSRect) {
        
        guard self.window?.isOpaque == false else { return super.draw(dirtyRect) }
        
        let fillRect = dirtyRect.intersection(self.bounds)
        
        NSColor.windowBackgroundColor.setFill()
        fillRect.fill()
        
        for hole in self.holes {
            hole.intersection(fillRect).fill(using: .clear)
        }
    }
    
    
    /// Updates the holes.
    ///
    /// - Parameter isOpaque: The opacity of the parent window.
    private func invalidateHoles(isOpaque: Bool) {
        
        if isOpaque {
            self.holes.removeAll()
        } else {
            self.holes = self.descendants(type: NSStackView.self)
                .map { $0.convert($0.frame, to: self) }
                .filter { !$0.isEmpty }
        }
    }
}


private extension NSView {
    
    func descendants<View: NSView>(type: View.Type = NSView.self) -> [View] {
        
        NSView.descendants(of: self) as [View]
    }
    
    
    private class func descendants<View: NSView>(of parenView: NSView) -> [View] {
        
        parenView.subviews.flatMap { subview in
            self.descendants(of: subview) + [subview as? View].compactMap(\.self)
        }
    }
}
