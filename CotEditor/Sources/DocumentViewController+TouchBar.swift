/*
 
 DocumentViewController+TouchBar.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-11-16.
 
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

private extension NSTouchBarCustomizationIdentifier {
    
    static let documentView = NSTouchBarCustomizationIdentifier("com.coteditor.CotEditor.touchBar.documentView")
}

extension NSTouchBarItemIdentifier {
    
    static let invisibles = NSTouchBarItemIdentifier("com.coteditor.CotEditor.TouchBarItem.invisibles")
    static let wrapLines = NSTouchBarItemIdentifier("com.coteditor.CotEditor.TouchBarItem.wrapLines")
    static let share = NSTouchBarItemIdentifier("com.coteditor.CotEditor.TouchBarItem.share")
}



@available(macOS 10.12.2, *)
extension DocumentViewController: NSTouchBarDelegate {
    
    // MARK: View Controller Methods
    
    override func makeTouchBar() -> NSTouchBar? {
        
        let touchBar = NSTouchBar()
        
        NSTouchBar.isAutomaticValidationEnabled = true
        
        touchBar.delegate = self
        touchBar.customizationIdentifier = .documentView
        touchBar.defaultItemIdentifiers = [.otherItemsProxy, .fixedSpaceSmall, .invisibles, .wrapLines]
        touchBar.customizationAllowedItemIdentifiers = [.share, .invisibles, .wrapLines]
        
        return touchBar
    }
    
    
    
    // MARK: Touch Bar Delegate
    
    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItemIdentifier) -> NSTouchBarItem? {
        
        switch identifier {
        case NSTouchBarItemIdentifier.invisibles:
            let item = NSCustomTouchBarItem(identifier: identifier)
            item.customizationLabel = NSLocalizedString("Invisibles", comment: "touch bar item")
            item.view = NSButton(image: #imageLiteral(resourceName: "InvisiblesTemplate"), target: self, action: #selector(toggleInvisibleChars(_:)))
            return item
            
        case NSTouchBarItemIdentifier.wrapLines:
            let item = NSCustomTouchBarItem(identifier: identifier)
            item.customizationLabel = NSLocalizedString("Wrap Lines", comment: "touch bar item")
            item.view = NSButton(image: #imageLiteral(resourceName: "WrapLinesTemplate"), target: self, action: #selector(toggleLineWrap(_:)))
            return item
            
        case NSTouchBarItemIdentifier.share:
            guard let document = self.document else { return nil }
            let item = NSSharingServicePickerTouchBarItem(identifier: identifier)
            item.delegate = document
            item.bind("enabled", to: document, withKeyPath: #keyPath(NSDocument.fileURL),
                      options: [NSValueTransformerNameBindingOption: NSValueTransformerName.isNotNilTransformerName])
            return item
            
        default:
            return nil
        }
    }
    
}


@available(macOS 10.12.2, *)
extension DocumentViewController: TouchBarItemValidations {
    
    func validateTouchBarItem(_ item: NSTouchBarItem) -> Bool {
        
        guard let button = item.view as? NSButton else { return true }
        
        guard let isEnabled: Bool = {
            switch item.identifier {
            case NSTouchBarItemIdentifier.invisibles:
                return self.showsInvisibles
                
            case NSTouchBarItemIdentifier.wrapLines:
                return self.wrapsLines
                
            default: return nil
            }
            }() else { return true }
        
        let color: NSColor? = isEnabled ? nil : .quaternaryLabelColor
        if button.bezelColor != color {
            button.bezelColor = color
            button.needsDisplay = true
        }
        
        return true
    }
    
}



@available(macOS 10.12.2, *)
extension NSDocument: NSSharingServicePickerTouchBarItemDelegate {
    
    public func items(for pickerTouchBarItem: NSSharingServicePickerTouchBarItem) -> [Any] {
        
        guard let fileURL = self.fileURL else { return [] }
        
        return [fileURL]
    }
}
