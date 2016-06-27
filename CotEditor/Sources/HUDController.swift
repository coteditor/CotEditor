/*
 
 HUDController.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-01-13.
 
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
import QuartzCore


@objc enum HUDSymbol: Int {
    
    case wrap
    
    var image: NSImage {
        switch self {
        case .wrap:
            return #imageLiteral(resourceName: "WrapTemplate")
        }
    }
}


private let HUDIdentifier = "HUD"

// constants
private let CornerRadius: CGFloat = 14.0
private let DefaultDisplayingInterval: TimeInterval = 0.1
private let FadeDuration: TimeInterval = 0.5


class HUDController: NSViewController {
    
    // MARK: Public Properties
    
    var isReversed = false
    
    
    // MARK: Private Properties
    
    private dynamic let symbolImage: NSImage
    
    @IBOutlet private weak var symbolView: NSImageView?
    
    
    
    // MARK:
    // MARK: Lifecycle
    
    required init?(symbol: HUDSymbol) {
        
        self.symbolImage = symbol.image
        
        super.init(nibName: nil, bundle: nil)
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override var nibName: String? {
        
        return "HUDView"
    }
    
    
    
    // MARK: View Controller Methods
    
    /// setup UI
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.view.identifier = HUDIdentifier
        self.view.layer?.cornerRadius = CornerRadius
        self.view.layer?.opacity = 0.0
        
        // set rotate symbol
        if self.isReversed {
            self.symbolView?.rotate(byDegrees: 180)
        }
    }
    
    
    
    // MARK: Public Methods
    
    /// show HUD for view
    func show(in clientView: NSView) {
        
        // remove previous HUD
        for subview in clientView.subviews {
            if subview.identifier == HUDIdentifier {
                subview.fadeOut(duration: FadeDuration / 2.0, delay: 0)  // fade quickly
            }
        }
        
        clientView.addSubview(self.view)
        
        // center
        clientView.addConstraints([NSLayoutConstraint(item: self.view, attribute: .centerX, relatedBy: .equal,
                                                      toItem: clientView, attribute: .centerX, multiplier: 1.0, constant: 0),
                                   NSLayoutConstraint(item: self.view, attribute: .centerY, relatedBy: .equal,
                                                      toItem: clientView, attribute: .centerY, multiplier: 0.8, constant: 0)])  // shift a bit upper
        
        // fade-in
        self.view.fadeIn(duration: FadeDuration * 0.8)
        
        // set fade-out with delay
        self.view.fadeOut(duration: FadeDuration, delay: FadeDuration + DefaultDisplayingInterval)
    }
    
}



// MARK:

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
        animation.fillMode = kCAFillModeForwards
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
        animation.fillMode = kCAFillModeForwards
        animation.isRemovedOnCompletion = false
        self.layer?.add(animation, forKey: AnimationIdentifier.fadeOut)
        
        CATransaction.completionBlock()
    }
    
}
