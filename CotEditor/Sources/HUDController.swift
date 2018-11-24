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
//  © 2016-2018 1024jp
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
    
    case wrap
    
    var image: NSImage {
        
        switch self {
        case .wrap:
            return #imageLiteral(resourceName: "WrapTemplate")
        }
    }
}


private extension NSUserInterfaceItemIdentifier {
    
    static let HUD = NSUserInterfaceItemIdentifier("HUD")
}


final class HUDController: NSViewController {
    
    // MARK: Public Properties
    
    var isReversed = false
    var symbol: HUDSymbol = .wrap
    
    
    // MARK: Private Properties
    
    private let cornerRadius: CGFloat = 14.0
    private let defaultDisplayingInterval: TimeInterval = 0.1
    private let fadeDuration: TimeInterval = 0.5
    
    @objc private dynamic var symbolImage: NSImage?
    
    @IBOutlet private weak var symbolView: NSImageView?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    /// setup UI
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        self.view.identifier = .HUD
        self.view.layer?.cornerRadius = self.cornerRadius
        self.view.layer?.opacity = 0.0
        
        self.symbolImage = self.symbol.image
        
        // set rotate symbol
        if self.isReversed {
            self.symbolView?.rotate(byDegrees: 180)
        }
    }
    
    
    
    // MARK: Public Methods
    
    /// show HUD for view
    func show(in clientView: NSView) {
        
        // remove previous HUD
        for subview in clientView.subviews where subview.identifier == .HUD {
            subview.fadeOut(duration: self.fadeDuration / 2.0, delay: 0)  // fade quickly
        }
        
        clientView.addSubview(self.view)
        
        // center
        clientView.addConstraints([NSLayoutConstraint(item: self.view, attribute: .centerX, relatedBy: .equal,
                                                      toItem: clientView, attribute: .centerX, multiplier: 1.0, constant: 0),
                                   NSLayoutConstraint(item: self.view, attribute: .centerY, relatedBy: .equal,
                                                      toItem: clientView, attribute: .centerY, multiplier: 0.8, constant: 0)])  // shift a bit upper
        
        // fade-in
        self.view.fadeIn(duration: self.fadeDuration * 0.8)
        
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
        
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.toValue = 1.0
        animation.duration = duration
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        self.layer?.add(animation, forKey: AnimationIdentifier.fadeIn)
    }
    
    
    /// fade-out view
    func fadeOut(duration: TimeInterval, delay: TimeInterval) {
        
        CATransaction.begin()
        
        CATransaction.setCompletionBlock { [weak self] in
            self?.removeFromSuperview()
        }
        
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.toValue = 0.0
        animation.duration = duration
        animation.beginTime = CACurrentMediaTime() + delay
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        self.layer?.add(animation, forKey: AnimationIdentifier.fadeOut)
        
        CATransaction.commit()
    }
    
}
