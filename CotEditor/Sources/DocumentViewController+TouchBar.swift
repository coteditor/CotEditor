//
//  DocumentViewController+TouchBar.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-11-16.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2021 1024jp
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

private extension NSTouchBar.CustomizationIdentifier {
    
    static let documentView = NSTouchBar.CustomizationIdentifier("com.coteditor.CotEditor.touchBar.documentView")
}


extension NSTouchBarItem.Identifier {
    
    static let invisibles = NSTouchBarItem.Identifier("com.coteditor.CotEditor.TouchBarItem.invisibles")
    static let indentGuides = NSTouchBarItem.Identifier("com.coteditor.CotEditor.TouchBarItem.indentGuides")
    static let wrapLines = NSTouchBarItem.Identifier("com.coteditor.CotEditor.TouchBarItem.wrapLines")
    static let share = NSTouchBarItem.Identifier("com.coteditor.CotEditor.TouchBarItem.share")
}



extension DocumentViewController: NSTouchBarDelegate {
    
    // MARK: View Controller Methods
    
    override func makeTouchBar() -> NSTouchBar? {
        
        let touchBar = NSTouchBar()
        
        NSTouchBar.isAutomaticValidationEnabled = true
        
        touchBar.delegate = self
        touchBar.customizationIdentifier = .documentView
        touchBar.defaultItemIdentifiers = [.otherItemsProxy, .fixedSpaceSmall, .invisibles, .wrapLines, .share]
        touchBar.customizationAllowedItemIdentifiers = [.share, .invisibles, .indentGuides, .wrapLines]
        
        return touchBar
    }
    
    
    
    // MARK: Touch Bar Delegate
    
    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        
        switch identifier {
            case .invisibles:
                let item = NSCustomTouchBarItem(identifier: identifier)
                item.customizationLabel = "Invisibles".localized(comment: "touch bar item")
                let image = NSImage(systemSymbolName: "paragraphsign", accessibilityDescription: "Invisibles".localized)!
                item.view = NSButton(image: image, target: self, action: #selector(toggleInvisibleCharsViaTouchBar))
                return item
            
            case .indentGuides:
                let item = NSCustomTouchBarItem(identifier: identifier)
                item.customizationLabel = "Indent Guides".localized(comment: "touch bar item")
                let image = NSImage(named: "text.indentguides")!
                item.view = NSButton(image: image, target: self, action: #selector(toggleIndentGuidesViaTouchBar))
                return item
            
            case .wrapLines:
                let item = NSCustomTouchBarItem(identifier: identifier)
                item.customizationLabel = "Wrap Lines".localized(comment: "touch bar item")
                let image = NSImage(named: "text.wrap")!
                item.view = NSButton(image: image, target: self, action: #selector(toggleLineWrapViaTouchBar))
                return item
            
            case .share:
                guard let document = self.document else { return nil }
                let item = NSSharingServicePickerTouchBarItem(identifier: identifier)
                item.delegate = document
                return item
            
            default:
                return nil
        }
    }
    
    
    /// toggle visibility of invisible characters in text view
    @IBAction private func toggleInvisibleCharsViaTouchBar(_ sender: NSButton) {
        
        self.toggleInvisibleChars(sender)
        self.validateUserInterfaceForTouchBarEvent()
    }
    
    
    /// toggle visibility of invisible characters in text view
    @IBAction private func toggleIndentGuidesViaTouchBar(_ sender: NSButton) {
        
        self.toggleIndentGuides(sender)
        self.validateUserInterfaceForTouchBarEvent()
    }
    
    
    /// toggle if lines wrap at window edge
    @IBAction private func toggleLineWrapViaTouchBar(_ sender: NSButton) {
        
        self.toggleLineWrap(sender)
        self.validateUserInterfaceForTouchBarEvent()
    }
    
    
    
    // MARK: Private Methods
    
    /// Update UI manually.
    ///
    /// Workaround for the issue where UI doesn't update on a touch bar event. (2017-01 macOS 10.12.2 SDK)
    private func validateUserInterfaceForTouchBarEvent() {
        
        self.view.window?.toolbar?.validateVisibleItems()
        self.touchBar?.validateVisibleItems()
    }
    
}



extension DocumentViewController: TouchBarItemValidations {
    
    func validateTouchBarItem(_ item: NSTouchBarItem) -> Bool {
        
        guard let button = item.view as? NSButton else { return true }
        
        guard let isEnabled: Bool = {
            switch item.identifier {
                case .invisibles:
                    return self.showsInvisibles
                
                case .indentGuides:
                    return self.showsIndentGuides
                
                case .wrapLines:
                    return self.wrapsLines
                
                default: return nil
            }
            }() else { return true }
        
        let color: NSColor? = isEnabled ? nil : .offStateButtonBezelColor
        if button.bezelColor != color {
            button.bezelColor = color
            button.needsDisplay = true
        }
        
        return true
    }
    
}



extension NSDocument: NSSharingServicePickerTouchBarItemDelegate {
    
    public func items(for pickerTouchBarItem: NSSharingServicePickerTouchBarItem) -> [Any] {
        
        return [self]
    }
}



private extension NSColor {
    
    /// button bezel color for off state
    static let offStateButtonBezelColor = NSColor(white: 0.12, alpha: 1)
}
