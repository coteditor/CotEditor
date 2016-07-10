/*
 
 CETextView+Scaling.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-07-10.
 
 ------------------------------------------------------------------------------
 
 © 2016 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Cocoa

extension CETextView {
    
    // MARK: View Methods
    
    /// change font size by pinch gesture
    public override func magnify(with event: NSEvent) {
        
        if event.phase.contains(.began) {
            self.initialMagnificationScale = self.scale
        }
        
        var scale = self.scale + event.magnification
        let center = self.convert(event.locationInWindow, from: nil)
        
        // hold a bit at scale 1.0
        if (self.initialMagnificationScale > 1.0 && scale < 1.0) ||  // zoom-out
            (self.initialMagnificationScale <= 1.0 && scale >= 1.0)  // zoom-in
        {
            self.deferredMagnification += event.magnification
            if fabs(self.deferredMagnification) > 0.4 {
                scale = self.scale + self.deferredMagnification / 2
                self.deferredMagnification = 0
                self.initialMagnificationScale = scale
            } else {
                scale = 1.0
            }
        }
        
        // sanitize final scale
        if event.phase.contains(.ended) && fabs(scale - 1.0) < 0.05 {
            scale = 1.0
        }
        
        self.setScale(scale, centeredAt: center)
    }
    
    
    /// reset font size by two-finger double tap
    public override func smartMagnify(with event: NSEvent) {
        
        let scale: CGFloat = (self.scale == 1.0) ? 1.5 : 1.0
        let center = self.convert(event.locationInWindow, from: nil)
        
        self.setScale(scale, centeredAt: center)
    }
    
    
    
    // MARK: Action Messages
    
    /// scale up
    @IBAction func biggerFont(_ sender: AnyObject?) {
        
        self.setScaleKeepingVisibleArea(self.scale * 1.1)
    }
    
    
    /// scale down
    @IBAction func smallerFont(_ sender: AnyObject?) {
        
        self.setScaleKeepingVisibleArea(self.scale / 1.1)
    }
    
    
    /// reset scale and font to default
    @IBAction func resetFont(_ sender: AnyObject?) {
        
        let name = UserDefaults.standard.string(forKey: CEDefaultFontNameKey)!
        let size = UserDefaults.standard.cgFloat(forKey: CEDefaultFontSizeKey)
        self.font = NSFont(name: name, size: size) ?? NSFont.userFont(ofSize: size)
        
        self.setScaleKeepingVisibleArea(1.0)
    }
    
}
