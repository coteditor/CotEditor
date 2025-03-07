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
//  © 2016-2024 1024jp
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
import ControlUI

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
                item.customizationLabel = String(localized: "Toolbar.invisibles.label", defaultValue: "Invisibles", table: "Document")
                let image = NSImage(systemSymbolName: "paragraphsign", accessibilityDescription: item.customizationLabel)!
                item.view = NSButton(image: image, target: self, action: #selector(toggleInvisibleCharsViaTouchBar))
                return item
                
            case .indentGuides:
                let item = NSCustomTouchBarItem(identifier: identifier)
                item.customizationLabel = String(localized: "Toolbar.indentGuides.label", defaultValue: "Indent Guides", table: "Document")
                let image = NSImage(resource: .textIndentguides)
                item.view = NSButton(image: image, target: self, action: #selector(toggleIndentGuidesViaTouchBar))
                return item
                
            case .wrapLines:
                let item = NSCustomTouchBarItem(identifier: identifier)
                item.customizationLabel = String(localized: "Toolbar.wrapLines.label", defaultValue: "Line Wrapping", table: "Document")
                let image = NSImage(resource: .textWrap)
                item.view = NSButton(image: image, target: self, action: #selector(toggleLineWrapViaTouchBar))
                return item
                
            case .share:
                let item = NSSharingServicePickerTouchBarItem(identifier: identifier)
                item.delegate = self
                return item
                
            default:
                return nil
        }
    }
    
    
    /// Toggles the visibility of invisible characters in the text views.
    @IBAction private func toggleInvisibleCharsViaTouchBar(_ sender: NSButton) {
        
        self.toggleInvisibleChars(sender)
        self.validateUserInterfaceForTouchBarEvent()
    }
    
    
    /// Toggles the visibility of invisible characters in the text views.
    @IBAction private func toggleIndentGuidesViaTouchBar(_ sender: NSButton) {
        
        self.toggleIndentGuides(sender)
        self.validateUserInterfaceForTouchBarEvent()
    }
    
    
    /// Toggles if lines wrap at the window edge.
    @IBAction private func toggleLineWrapViaTouchBar(_ sender: NSButton) {
        
        self.toggleLineWrap(sender)
        self.validateUserInterfaceForTouchBarEvent()
    }
    
    
    // MARK: Private Methods
    
    /// Updates UI manually.
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
        
        guard let isEnabled: Bool = switch item.identifier {
            case .invisibles: self.showsInvisibles
            case .indentGuides: self.showsIndentGuides
            case .wrapLines: self.wrapsLines
            default: nil
        } else { return true }
        
        let color: NSColor? = isEnabled ? nil : .offStateButtonBezelColor
        if button.bezelColor != color {
            button.bezelColor = color
            button.needsDisplay = true
        }
        
        return true
    }
}


extension DocumentViewController: NSSharingServicePickerTouchBarItemDelegate {
    
    public func items(for pickerTouchBarItem: NSSharingServicePickerTouchBarItem) -> [Any] {
        
        [self.document]
    }
}


private extension NSColor {
    
    /// The button bezel color for the off state.
    static let offStateButtonBezelColor = NSColor(white: 0.12, alpha: 1)
}
