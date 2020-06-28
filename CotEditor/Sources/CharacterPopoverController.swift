//
//  CharacterPopoverController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2014-05-01.
//
//  ---------------------------------------------------------------------------
//
//  © 2014-2020 1024jp
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

final class CharacterPopoverController: NSViewController {
    
    // MARK: Private Properties
    
    private var closingCueObserver: NotificationObservation?
    
    @objc private dynamic var glyph: String?
    @objc private dynamic var unicodeName: String?
    @objc private dynamic var unicodeBlockName: String?
    @objc private dynamic var unicodeCategoryName: String?
    @objc private dynamic var unicode: String = ""
    
    @objc private dynamic var characterColor: NSColor = .labelColor
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    /// Instantinate proper view controller for the given character info.
    ///
    /// - Parameter info: The CharacterInfo instance to display.
    static func instantiate(for info: CharacterInfo) -> Self {
        
        let identifier: NSStoryboard.SceneIdentifier? = info.isComplex ? "ComplexCharacterPopoverController" : nil
        
        let instance = self.instantiate(storyboard: "CharacterPopover", identifier: identifier)
        instance.setup(characterInfo: info)
        
        return instance
    }
    
    
    
    // MARK: Public Methods
    
    /// Show the popover anchored to the specified view.
    ///
    /// - Parameters:
    ///   - parentView: The view relative to which the popover should be positioned.
    /// - Returns: A popover instance.
    func showPopover(relativeTo positioningRect: NSRect, of parentView: NSView) {
        
        assert(self.glyph != nil)
        
        let popover = NSPopover()
        popover.contentViewController = self
        popover.delegate = self
        popover.behavior = .semitransient
        popover.show(relativeTo: positioningRect, of: parentView, preferredEdge: .minY)
        
        // auto-close popover if selection is changed
        if let textView = parentView as? NSTextView {
            self.closingCueObserver?.invalidate()
            self.closingCueObserver = NotificationCenter.default.addObserver(forName: NSTextView.didChangeSelectionNotification, object: textView, queue: .main) { [weak popover] _ in
                popover?.performClose(nil)
            }
        }
    }
    
    
    
    // MARK: Private Methods
    
    /// Initialize view with character info.
    ///
    /// - Parameter info: The CharacterInfo instance to display.
    private func setup(characterInfo info: CharacterInfo) {
        
        let unicodes = info.string.unicodeScalars
        
        self.glyph = info.pictureString ?? info.string
        self.unicodeName = info.localizedDescription
        self.unicodeBlockName = info.isComplex ? nil : unicodes.first?.localizedBlockName
        self.unicodeCategoryName = {
            guard !info.isComplex,
                let category = unicodes.first?.properties.generalCategory
                else { return nil }
            
            return "\(category.longName) (\(category.shortName))"
        }()
        
        // build Unicode code point string
        let isMultiple = unicodes.count > 1
        let codePoints: [String] = unicodes.map { unicode in
            var codePoint = unicode.codePoint
            
            if !isMultiple, let surrogates = unicode.surrogateCodePoints {
                codePoint += " (" + surrogates.joined(separator: " ") + ")"
            }
            
            // append Unicode name
            if isMultiple, let name = unicode.name {
                codePoint += "\t" + name
            }
            
            return codePoint
        }
        
        self.unicode = codePoints.joined(separator: "\n")
        self.characterColor = (info.pictureString != nil) ? .tertiaryLabelColor : .labelColor
    }
    
}



// MARK: Delegate

extension CharacterPopoverController: NSPopoverDelegate {
    
    /// make popover detachable
    func popoverShouldDetach(_ popover: NSPopover) -> Bool {
        
        // remove selection change observer
        self.closingCueObserver?.invalidate()
        self.closingCueObserver = nil
        
        guard let parentWindow = popover.contentViewController?.view.window?.parent else {
            assertionFailure("Failed obtaining the parent window for character info popover.")
            return false
        }
        
        // close popover when the window of the parent editor is closed
        // -> Otherwise, a zombie window appears again when clicking somewhere after closing the window,
        //    as NSPopover seems to retain the parent window somehow. (2020 macOS 10.15)
        self.closingCueObserver = NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: parentWindow, queue: .main) { [weak popover] _ in
            popover?.close()
        }
        
        return true
    }
    
}
