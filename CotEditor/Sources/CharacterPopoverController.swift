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
//  © 2014-2018 1024jp
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
    
    @objc private dynamic var glyph: String = ""
    @objc private dynamic var unicodeName: String?
    @objc private dynamic var unicodeBlockName: String?
    @objc private dynamic var unicode: String = ""
    
    @objc private dynamic var characterColor: NSColor = .labelColor
    
    @IBOutlet private weak var unicodeBlockNameField: NSTextField?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    /// setup UI
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // remove group name field if not exists
        if self.unicodeBlockName == nil {
            self.unicodeBlockNameField!.removeFromSuperviewWithoutNeedingDisplay()
        }
    }
    
    
    
    // MARK: Public Methods
    
    /// initialize view with character
    ///
    /// - Parameter character: `character` must be a single character (or a surrogate-pair). If not, throws an error.
    /// - Throws: CharacterInfo.Error
    func setup(character: String) throws {
        
        let info = try CharacterInfo(string: character)
        
        let unicodes = character.unicodeScalars
        
        self.glyph = info.pictureString ?? info.string
        self.unicodeName = info.localizedDescription
        self.unicodeBlockName = info.isComplex ? nil : unicodes.first?.localizedBlockName
        
        // build Unicode code point string
        let codePoints: [String] = unicodes.map { unicode in
            var codePoint = unicode.codePoint
            
            if let surrogates = unicode.surrogateCodePoints {
                codePoint += " (" + surrogates.joined(separator: " ") + ")"
            }
            
            // append Unicode name
            if unicodes.count > 1, let name = unicode.name {
                codePoint += "\t" + name
            }
            return codePoint
        }
        
        self.unicode = codePoints.joined(separator: "\n")
        self.characterColor = (info.pictureString != nil) ? .tertiaryLabelColor : .labelColor
    }
    
    
    /// show popover
    func showPopover(relativeTo positioningRect: NSRect, of parentView: NSView) {
        
        let popover = NSPopover()
        popover.contentViewController = self
        popover.delegate = self
        popover.behavior = .semitransient
        popover.show(relativeTo: positioningRect, of: parentView, preferredEdge: .minY)
        parentView.window?.makeFirstResponder(parentView)
        
        // auto-close popover if selection is changed.
        if let textView = parentView as? NSTextView {
            weak var observer: NSObjectProtocol?
            observer = NotificationCenter.default.addObserver(forName: NSTextView.didChangeSelectionNotification,
                                                              object: textView, queue: .main, using:
                { (note: Notification) in
                    
                    if !popover.isDetached {
                        popover.performClose(nil)
                    }
                    if let observer = observer {
                        NotificationCenter.default.removeObserver(observer)
                    }
            })
        }
    }
    
}



// MARK: Delegate

extension CharacterPopoverController: NSPopoverDelegate {
    
    /// make popover detachable
    func popoverShouldDetach(_ popover: NSPopover) -> Bool {
        
        return true
    }
    
}
