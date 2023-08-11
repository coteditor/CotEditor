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
//  © 2023 1024jp
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
    
    @Invalidating(.display) private var holes: [NSRect] = []
    
    private var windowOpacityObserver: AnyCancellable?
    private var holeViewObserver: AnyCancellable?
    
    
    override func viewWillMove(toWindow newWindow: NSWindow?) {
        
        super.viewWillMove(toWindow: newWindow)
        
        self.windowOpacityObserver = newWindow?.publisher(for: \.isOpaque)
            .sink { [unowned self] isOpaque in
                self.holeViewObserver = if isOpaque {
                    nil
                } else {
                    NotificationCenter.default.publisher(for: NSView.frameDidChangeNotification)
                        .map { $0.object as! NSView }
                        .filter { $0 is NSStackView }
                        .filter { $0.isDescendant(of: self) }
                        .sink { [unowned self] _ in
                            self.holes = self.descendants(type: NSStackView.self)
                                .map { $0.convert($0.frame, to: self) }
                        }
                }
            }
    }
    
    
    override func draw(_ dirtyRect: NSRect) {
        
        
        guard self.window?.isOpaque == false else { return super.draw(dirtyRect) }
        
        NSColor.windowBackgroundColor.setFill()
        dirtyRect.fill()
        
        for hole in self.holes {
            hole.intersection(dirtyRect).fill(using: .clear)
        }
    }
}



private extension NSView {
    
    func descendants<View: NSView>(type: View.Type = NSView.self) -> [View] {
        
        NSView.descendants(of: self) as [View]
    }
    
    
    private class func descendants<View: NSView>(of parenView: NSView) -> [View] {
        
        parenView.subviews.flatMap { subview in
            self.descendants(of: subview) + [subview as? View].compactMap({ $0 })
        }
    }
}
