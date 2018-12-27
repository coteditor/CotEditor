//
//  TextSizeTouchBar.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-11-14.
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

private extension NSTouchBarItem.Identifier {
    
    static let textSizeActual = NSTouchBarItem.Identifier("com.coteditor.CotEditor.TouchBarItem.textSizeActual")
    static let textSizeSlider = NSTouchBarItem.Identifier("com.coteditor.CotEditor.TouchBarItem.textSizeSlider")
}



final class TextSizeTouchBar: NSTouchBar, NSTouchBarDelegate, NSUserInterfaceValidations {
    
    // MARK: Private Properties
    
    private weak var textContainer: NSTextContainer?  // hold textContainer instead of textView, which cannot be weak
    private var scaleObserver: NSKeyValueObservation!
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    init(textView: NSTextView, forPressAndHold: Bool = false) {
        
        self.textContainer = textView.textContainer
        
        super.init()
        
        NSTouchBar.isAutomaticValidationEnabled = true
        
        self.delegate = self
        self.defaultItemIdentifiers = forPressAndHold ? [.textSizeSlider] : [.textSizeActual, .textSizeSlider]
        
        // observe scale for slider
        self.scaleObserver = textView.observe(\.scale) { [weak self] (textView, _) in
            guard let item = self?.item(forIdentifier: .textSizeSlider) as? NSSliderTouchBarItem else { return assertionFailure() }
            
            item.slider.doubleValue = Double(textView.scale)
        }
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    deinit {
        self.scaleObserver.invalidate()
    }
    
    
    
    // MARK: Touch Bar Delegate
    
    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        
        switch identifier {
        case .textSizeActual:
            let item = NSCustomTouchBarItem(identifier: identifier)
            item.view = NSButton(title: "Actual Size".localized,
                                 target: self, action: #selector(resetTextSize(_:)))
            return item
            
        case .textSizeSlider:
            guard let textView = self.textView else { return nil }
            
            let item = NSSliderTouchBarItem(identifier: identifier)
            item.slider.doubleValue = Double(textView.scale)
            item.slider.maxValue = Double(textView.enclosingScrollView?.maxMagnification ?? 5.0)
            item.slider.minValue = Double(textView.enclosingScrollView?.minMagnification ?? 0.2)
            item.minimumValueAccessory = NSSliderAccessory(image: #imageLiteral(resourceName: "SmallTextSizeTemplate"))
            item.maximumValueAccessory = NSSliderAccessory(image: #imageLiteral(resourceName: "LargeTextSizeTemplate"))
            item.target = self
            item.action = #selector(textSizeSliderChanged(_:))
            
            let constraints = NSLayoutConstraint.constraints(withVisualFormat: "[slider(300)]", metrics: nil,
                                                             views: ["slider": item.slider])
            NSLayoutConstraint.activate(constraints)
            
            return item
            
        default:
            return nil
        }
    }
    
    
    
    // MARK: User Interface Validations
    
    func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        
        guard let action = item.action else { return false }
        
        switch action {
        case #selector(resetTextSize(_:)):
            return (self.textView?.scale != 1.0)
            
        default:
            return true
        }
    }
    
    
    
    // MARK: Action Messages
    
    /// text size slider was moved
    @IBAction func textSizeSliderChanged(_ sliderItem: NSSliderTouchBarItem) {
        
        let scale = CGFloat(sliderItem.slider.doubleValue)
        
        self.textView?.setScaleKeepingVisibleArea(scale)
    }
    
    
    /// "Actaul Size" button was pressed
    @IBAction func resetTextSize(_ sender: Any?) {
        
        self.textView?.setScaleKeepingVisibleArea(1.0)
    }
    
    
    
    // MARK: Private Methods
    
    private var textView: NSTextView? {
        
        return self.textContainer?.textView
    }
    
}
