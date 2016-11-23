/*
 
 TextSizeTouchBar.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-11-14.
 
 ------------------------------------------------------------------------------
 
 © 2016 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 https://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Cocoa

fileprivate extension NSTouchBarItemIdentifier {
    
    static let textSizeActual = NSTouchBarItemIdentifier("com.coteditor.CotEditor.TouchBarItem.textSizeActual")
    static let textSizeSlider = NSTouchBarItemIdentifier("com.coteditor.CotEditor.TouchBarItem.textSizeSlider")
}



@available(OSX 10.12.1, *)
class TextSizeTouchBar: NSTouchBar, NSTouchBarDelegate {
    
    // MARK: Private Properties
    
    private weak var slider: NSSlider?
    private weak var actualSizeButton: NSButton?
    
    private var textView: NSTextView? {  // NSTextView cannot be weak
        
        get {
            return _textContainer?.textView
        }
        set {
            _textContainer = newValue?.textContainer
        }
    }
    private weak var _textContainer: NSTextContainer?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    init(textView: NSTextView) {
        
        super.init()
        
        self.textView = textView
        
        self.delegate = self
        self.defaultItemIdentifiers = [.textSizeActual, .textSizeSlider]
        
        NotificationCenter.default.addObserver(self, selector: #selector(invalidateActualSizeButton), name: .TextViewDidChangeScale, object: textView)
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    
    // MARK: Touch Bar Delegate
    
    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItemIdentifier) -> NSTouchBarItem? {
        
        switch identifier {
        case NSTouchBarItemIdentifier.textSizeActual:
            let item = NSCustomTouchBarItem(identifier: identifier)
            let button = NSButton(title: NSLocalizedString("Actual Size", comment: ""),
                                  target: self, action: #selector(resetTextSize(_:)))
            self.actualSizeButton = button
            item.view = button
            self.invalidateActualSizeButton()
            return item
            
        case NSTouchBarItemIdentifier.textSizeSlider:
            let item = NSSliderTouchBarItem(identifier: identifier)
            item.slider.doubleValue = Double(self.textView?.scale ?? 1.0)
            item.slider.maxValue = 5.0
            item.slider.minValue = 0.2
            item.minimumValueAccessory = NSSliderAccessory(image: #imageLiteral(resourceName: "SmallTextSizeTemplate"))
            item.maximumValueAccessory = NSSliderAccessory(image: #imageLiteral(resourceName: "LargeTextSizeTemplate"))
            item.target = self
            item.action = #selector(textSizeSliderChanged(_:))
            self.slider = item.slider
            
            let constraints = NSLayoutConstraint.constraints(withVisualFormat: "[slider(300)]", metrics: nil,
                                                             views: ["slider": item.slider])
            NSLayoutConstraint.activate(constraints)
            
            return item
            
        default:
            return nil
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
        
        self.slider?.doubleValue = 1.0
        
        self.textView?.setScaleKeepingVisibleArea(1.0)
    }
    
    
    
    // MARK: Private Methods
    
    func invalidateActualSizeButton() {
        
        let isActualSize = self.textView?.scale == 1.0
        
        self.actualSizeButton?.isEnabled = !isActualSize
    }
    
}
