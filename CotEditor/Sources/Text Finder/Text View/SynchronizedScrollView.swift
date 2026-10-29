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
//  © 2018-2026 1024jp
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

final class SynchronizedScrollView: NSScrollView {
    
    // MARK: Public Properties
    
    var focusRingRadius: CGFloat = 0
    
    
    // MARK: Private Properties
    
    private weak var sibling: SynchronizedScrollView?
    
    
    // MARK: Scroll View Methods
    
    override func viewWillDraw() {
        
        super.viewWillDraw()
        
        if self.sibling == nil, let sibling = self.findSibling() {
            self.sibling = sibling
            sibling.sibling = self
        }
    }
    
    
    override func drawFocusRingMask() {
        
        guard self.focusRingRadius > 0 else { return super.drawFocusRingMask() }
        
        NSBezierPath(roundedRect: self.bounds, xRadius: self.focusRingRadius, yRadius: self.focusRingRadius).fill()
    }
    
    
    /// Receives a pinch zoom event.
    override func magnify(with event: NSEvent) {
        
        let lastMagnification = self.magnification
        let magnification = self.magnification * (1 + event.magnification)
        let location = self.contentView.convert(event.locationInWindow, from: nil)
        
        for scrollView in self.siblings {
            scrollView.setMagnification(magnification, centeredAt: location)
        }
        
        if self.magnification == 1.0, lastMagnification != 1.0 {
            NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
        }
    }
    
    
    /// Receives a double-tap event adjusting scale.
    override func smartMagnify(with event: NSEvent) {
        
        for scrollView in self.siblings {
            scrollView.syncedSmartMagnify(with: event)
        }
    }
    
    
    // MARK: Private Methods
    
    /// The receiver and its cached synchronization partner.
    private var siblings: [SynchronizedScrollView] {
        
        [self, self.sibling].compactMap(\.self)
    }
    
    
    /// Finds the other synchronized scroll view in the nearest view controller's view hierarchy.
    ///
    /// - Returns: The synchronization partner, or `nil` if it has not been added yet.
    private func findSibling() -> SynchronizedScrollView? {
        
        guard
            let viewController = sequence(first: self as NSResponder, next: \.nextResponder)
                .first(where: { $0 is NSViewController }) as? NSViewController
        else { return nil }
        
        return self.descendants(in: viewController.view).first { $0 !== self }
    }
    
    
    /// Collects synchronized scroll views without entering child view controllers.
    ///
    /// - Parameter view: The view whose subview hierarchy will be searched.
    /// - Returns: The synchronized scroll views in the given hierarchy.
    private func descendants(in view: NSView) -> [SynchronizedScrollView] {
        
        if let scrollView = view as? SynchronizedScrollView {
            return [scrollView]
        }
        
        return view.subviews
            .filter { !($0.nextResponder is NSViewController) }
            .flatMap(self.descendants(in:))
    }
    
    
    /// Invokes super's `smartMagnify(with:)` without the issue about the cycle invoking.
    ///
    /// - Parameter event: The magnify event.
    private func syncedSmartMagnify(with event: NSEvent) {
        
        super.smartMagnify(with: event)
    }
}


// MARK: Actions

extension SynchronizedScrollView: NSUserInterfaceValidations, TextSizeChanging {
    
    func validateUserInterfaceItem(_ item: any NSValidatedUserInterfaceItem) -> Bool {
        
        switch item.action {
            case #selector(smallerFont):
                return self.magnification > self.minMagnification
            case #selector(biggerFont):
                return self.magnification < self.maxMagnification
            case nil:
                return false
            default:
                return true
        }
    }
    
    
    /// Scales up.
    @IBAction func biggerFont(_ sender: Any?) {
        
        for scrollView in self.siblings {
            scrollView.animator().magnification += 0.2
        }
    }
    
    
    /// Scales down.
    @IBAction func smallerFont(_ sender: Any?) {
        
        for scrollView in self.siblings {
            scrollView.animator().magnification -= 0.2
        }
    }
    
    
    /// Resets the scale to the default.
    @IBAction func resetFont(_ sender: Any?) {
        
        for scrollView in self.siblings {
            scrollView.animator().magnification = 1.0
        }
    }
}
