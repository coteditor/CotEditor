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
//  © 2016-2022 1024jp
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

import Combine
import Cocoa

private extension NSTouchBarItem.Identifier {
    
    static let textSizeActual = NSTouchBarItem.Identifier("com.coteditor.CotEditor.TouchBarItem.textSizeActual")
    static let textSizeSlider = NSTouchBarItem.Identifier("com.coteditor.CotEditor.TouchBarItem.textSizeSlider")
}



final class TextSizeTouchBar: NSTouchBar, NSTouchBarDelegate, NSUserInterfaceValidations {
    
    // MARK: Private Properties
    
    private weak var textView: NSTextView?
    private var scaleObserver: AnyCancellable?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    init(textView: NSTextView, forPressAndHold: Bool = false) {
        
        self.textView = textView
        
        super.init()
        
        NSTouchBar.isAutomaticValidationEnabled = true
        
        self.delegate = self
        self.defaultItemIdentifiers = forPressAndHold ? [.textSizeSlider] : [.textSizeActual, .textSizeSlider]
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    // MARK: Touch Bar Delegate
    
    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        
        switch identifier {
            case .textSizeActual:
                let item = NSCustomTouchBarItem(identifier: identifier)
                item.view = NSButton(title: "Actual Size".localized, target: self, action: #selector(resetTextSize))
                return item
            
            case .textSizeSlider:
                guard let textView = self.textView else { return nil }
                
                let item = NSSliderTouchBarItem(identifier: identifier)
                item.target = self
                item.action = #selector(textSizeSliderChanged)
                item.doubleValue = textView.scale
                item.slider.maxValue = Double(textView.enclosingScrollView?.maxMagnification ?? 5.0)
                item.slider.minValue = Double(textView.enclosingScrollView?.minMagnification ?? 0.2)
                let minimumValueImage = NSImage(systemSymbolName: "textformat.size.smaller", accessibilityDescription: "Smaller".localized)!
                item.minimumValueAccessory = NSSliderAccessory(image: minimumValueImage)
                let maximumValueImage = NSImage(systemSymbolName: "textformat.size.larger", accessibilityDescription: "larger".localized)!
                item.maximumValueAccessory = NSSliderAccessory(image: maximumValueImage)
                item.maximumSliderWidth = 300
                
                // observe scale
                self.scaleObserver = textView.publisher(for: \.scale)
                    .filter { _ in item.isVisible }
                    .map { Double($0) }
                    .assign(to: \.doubleValue, on: item)
                
                return item
            
            default:
                return nil
        }
    }
    
    
    
    // MARK: User Interface Validations
    
    func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        
        switch item.action {
            case #selector(resetTextSize):
                return (self.textView?.scale != 1.0)
            case nil:
                return false
            default:
                return true
        }
    }
    
    
    
    // MARK: Action Messages
    
    /// text size slider was moved
    @IBAction func textSizeSliderChanged(_ sliderItem: NSSliderTouchBarItem) {
        
        let scale = sliderItem.doubleValue
        
        self.textView?.setScaleKeepingVisibleArea(scale)
    }
    
    
    /// "Actaul Size" button was touched
    @IBAction func resetTextSize(_ sender: Any?) {
        
        self.textView?.setScaleKeepingVisibleArea(1.0)
    }
}
