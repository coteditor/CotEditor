//
//  SynchronizedScrollView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-10-09.
//
//  ---------------------------------------------------------------------------
//
//  © 2018 1024jp
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

final class SynchronizedScrollView: NSScrollView {
    
    // MARK: Scroll View Methods
    
    /// receive pinch zoom event
    override func magnify(with event: NSEvent) {
        
        let magnification = self.magnification + event.magnification
        let location = self.contentView.convert(event.locationInWindow, from: nil)
        
        for scrollView in self.siblings {
            scrollView.setMagnification(magnification, centeredAt: location)
        }
    }
    
    
    /// receive double-tap event adjusting scale
    override func smartMagnify(with event: NSEvent) {
        
        for scrollView in self.siblings {
            scrollView.syncedSmartMagnify(with: event)
        }
    }
    
    
    
    // MARK: Private Methods
    
    /// auto-founded scroll views to sync (including the receiver itself)
    private var siblings: [SynchronizedScrollView] {
        
        return self.superview?.subviews.compactMap { $0 as? SynchronizedScrollView } ?? [self]
    }
    
    
    /// invoking super's `smartMagnify(with:)` without the issue about the cycle invoking
    private func syncedSmartMagnify(with event: NSEvent) {
        
        super.smartMagnify(with: event)
    }
    
}



// MARK: Actions

extension SynchronizedScrollView: NSUserInterfaceValidations {
    
    func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        
        guard let action = item.action else { return false }
        
        switch action {
        case #selector(smallerFont):
            return self.magnification > self.minMagnification
            
        case #selector(biggerFont):
            return self.magnification < self.maxMagnification
            
        default:
            return true
        }
    }
    
    
    /// scale up
    @IBAction func biggerFont(_ sender: Any?) {
        
        for scrollView in self.siblings {
            scrollView.animator().magnification += 0.2
        }
    }
    
    
    /// scale down
    @IBAction func smallerFont(_ sender: Any?) {
        
        for scrollView in self.siblings {
            scrollView.animator().magnification -= 0.2
        }
    }
    
    
    /// reset scale to default
    @IBAction func resetFont(_ sender: Any?) {
        
        for scrollView in self.siblings {
            scrollView.animator().magnification = 1.0
        }
    }
    
}
