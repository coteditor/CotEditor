//
//  HUDController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-01-13.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2020 1024jp
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
import QuartzCore

enum HUDSymbol {
    
    case wrap(reversed: Bool = false)
    
    
    fileprivate var image: NSImage {
        
        switch self {
            case .wrap(let reversed):
                return reversed ? #imageLiteral(resourceName: "WrapTemplate").rotated(by: 180) : #imageLiteral(resourceName: "WrapTemplate")
        }
    }
    
}


private extension NSUserInterfaceItemIdentifier {
    
    static let hud = NSUserInterfaceItemIdentifier("HUD")
}


final class HUDController: NSViewController {
    
    // MARK: Public Properties
    
    var symbol: HUDSymbol = .wrap() {
        
        didSet {
            self.symbolImage = symbol.image
        }
    }
    
    
    // MARK: Private Properties
    
    private let cornerRadius: CGFloat = 14.0
    private let defaultDisplayingInterval: TimeInterval = 0.1
    private let fadeDuration: TimeInterval = 0.5
    
    @objc private dynamic var symbolImage: NSImage?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.view.identifier = .hud
        
        assert(self.view.layer != nil)
        self.view.layer?.cornerRadius = self.cornerRadius
        self.view.layer?.cornerCurve = .continuous
    }
    
    
    
    // MARK: Public Methods
    
    /// Show HUD in the given view.
    ///
    /// - Parameter clientView: The client view where the HUD appear.
    func show(in clientView: NSView) {
        
        // remove previous HUD if any
        for subview in clientView.subviews where subview.identifier == .hud {
            subview.fadeOut(duration: self.fadeDuration / 2)  // fade quickly
        }
        
        clientView.addSubview(self.view)
        
        // center
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: self.view, attribute: .centerX, relatedBy: .equal,
                               toItem: clientView, attribute: .centerX, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: self.view, attribute: .centerY, relatedBy: .equal,
                               toItem: clientView, attribute: .centerY, multiplier: 0.8, constant: 0),
        ])
        
        // set fade-out with delay
        self.view.fadeOut(duration: self.fadeDuration, delay: self.fadeDuration + self.defaultDisplayingInterval)
    }
    
}



// MARK: -

private enum AnimationIdentifier {
    static let fadeIn = "fadeIn"
    static let fadeOut = "fadeOut"
}


private extension NSView {
    
    /// fade-in view
    func fadeIn(duration: TimeInterval) {
        
        guard let layer = self.layer else { return assertionFailure() }
        
        let animation = CABasicAnimation(keyPath: #keyPath(CALayer.opacity))
        animation.fromValue = 0
        animation.toValue = 1
        animation.duration = duration
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        
        layer.add(animation, forKey: AnimationIdentifier.fadeIn)
    }
    
    
    /// fade-out view
    func fadeOut(duration: TimeInterval, delay: TimeInterval = 0) {
        
        guard let layer = self.layer else { return assertionFailure() }
        
        CATransaction.begin()
        
        CATransaction.setCompletionBlock { [weak self] in
            guard self?.superview != nil else { return }
            
            self?.removeFromSuperview()
        }
        
        let animation = CABasicAnimation(keyPath: #keyPath(CALayer.opacity))
        animation.toValue = 0
        animation.duration = duration
        animation.beginTime = CACurrentMediaTime() + delay
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        
        layer.add(animation, forKey: AnimationIdentifier.fadeOut)
        
        CATransaction.commit()
    }
    
}
