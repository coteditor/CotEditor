//
//  EditorTextView+Scaling.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-07-10.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2021 1024jp
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

import Cocoa

extension EditorTextView {
    
    // MARK: View Methods
    
    /// change scale by pinch gesture
    override func magnify(with event: NSEvent) {
        
        if event.phase.contains(.began) {
            self.deferredMagnification = 0
            self.initialMagnificationScale = self.scale
        }
        
        var scale = self.scale * (1 + event.magnification)
        
        // hold a bit at scale 1.0
        if (self.initialMagnificationScale > 1.0 && scale < 1.0) ||  // zoom-out
            (self.initialMagnificationScale <= 1.0 && scale >= 1.0)  // zoom-in
        {
            self.deferredMagnification += event.magnification
            if abs(self.deferredMagnification) > 0.4 {
                scale = self.scale + self.deferredMagnification / 2
                self.deferredMagnification = 0
                self.initialMagnificationScale = scale
            } else {
                scale = 1.0
            }
        }
        
        // sanitize final scale
        if event.phase.contains(.ended), abs(scale - 1.0) < 0.05 {
            scale = 1.0
        }
        
        guard scale != self.scale else { return }
        
        let center = self.convert(event.locationInWindow, from: nil)
        
        if scale == 1.0 {
            NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
        }
        
        self.setScale(scale, centeredAt: center)
    }
    
    
    /// reset scale by two-finger double tap
    override func smartMagnify(with event: NSEvent) {
        
        let scale = (self.scale == 1.0) ? 1.5 : 1.0
        let center = self.convert(event.locationInWindow, from: nil)
        
        self.setScale(scale, centeredAt: center)
    }
    
    
    
    // MARK: Action Messages
    
    /// change scale from segmented control button
    @IBAction func changeTextSize(_ sender: NSSegmentedControl) {
        
        switch sender.selectedSegment {
            case 0:
                self.smallerFont(sender)
            case 1:
                self.biggerFont(sender)
            default:
                assertionFailure("Segmented text size button must have 2 segments only.")
        }
    }
    
    
    /// scale up
    @IBAction func biggerFont(_ sender: Any?) {
        
        self.setScaleKeepingVisibleArea(self.scale * 1.1)
    }
    
    
    /// scale down
    @IBAction func smallerFont(_ sender: Any?) {
        
        self.setScaleKeepingVisibleArea(self.scale / 1.1)
    }
    
    
    /// reset scale and font to default
    @IBAction func resetFont(_ sender: Any?) {
        
        let name = UserDefaults.standard[.fontName]
        let size = UserDefaults.standard[.fontSize]
        let font = NSFont(name: name, size: size) ?? NSFont.userFont(ofSize: size)
        
        self.font = font
        self.setScaleKeepingVisibleArea(1.0)
    }
}
