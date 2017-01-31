/*
 
 EditorTextView+TouchBar.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-10-29.
 
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
    
    static let textView = NSTouchBarCustomizationIdentifier("com.coteditor.CotEditor.touchBar.textView")
}


extension NSTouchBarItemIdentifier {
    
    static let shift = NSTouchBarItemIdentifier("com.coteditor.CotEditor.TouchBarItem.shift")
    static let comment = NSTouchBarItemIdentifier("com.coteditor.CotEditor.TouchBarItem.comment")
    static let textSize = NSTouchBarItemIdentifier("com.coteditor.CotEditor.TouchBarItem.textSize")
}



@available(macOS 10.12.2, *)
extension EditorTextView {
    
    override func makeTouchBar() -> NSTouchBar? {
        
        let touchBar = super.makeTouchBar() ?? NSTouchBar()
        
        NSTouchBar.isAutomaticValidationEnabled = true
        
        touchBar.customizationIdentifier = .textView
        touchBar.defaultItemIdentifiers += [.fixedSpaceSmall, .shift, .comment, .textSize, .otherItemsProxy]
        touchBar.customizationAllowedItemIdentifiers += [.shift, .comment, .textSize]
        
        return touchBar
    }
    
    
    override func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItemIdentifier) -> NSTouchBarItem? {
        
        switch identifier {
        case NSTouchBarItemIdentifier.shift:
            let item = NSCustomTouchBarItem(identifier: identifier)
            item.customizationLabel = NSLocalizedString("Shift", comment: "touch bar item")
            item.view = NSSegmentedControl(images: [#imageLiteral(resourceName: "ShiftLeftTemplate"), #imageLiteral(resourceName: "ShiftRightTemplate")], trackingMode: .momentary,
                                           target: self, action: #selector(shift(_:)))
            return item
            
        case NSTouchBarItemIdentifier.comment:
            let item = NSCustomTouchBarItem(identifier: identifier)
            item.customizationLabel = NSLocalizedString("Comment", comment: "touch bar item")
            item.view = NSButton(image: #imageLiteral(resourceName: "CommentTemplate"), target: self, action: #selector(toggleComment(_:)))
            return item
            
        case NSTouchBarItemIdentifier.textSize:
            let item = NSPopoverTouchBarItem(identifier: identifier)
            item.customizationLabel = NSLocalizedString("Text Size", comment: "touch bar item")
            item.collapsedRepresentationImage = #imageLiteral(resourceName: "TextSizeTemplate")
            item.popoverTouchBar = TextSizeTouchBar(textView: self)
            return item
            
        default:
            return super.touchBar(touchBar, makeItemForIdentifier: identifier)
        }
    }
    
}



@available(macOS 10.12.2, *)
extension EditorTextViewController {
    
    /// suggest candidates for automatic text completion
    func textView(_ textView: NSTextView, candidatesForSelectedRange selectedRange: NSRange) -> [Any]? {
        
        var index = 0
        guard let candidates = textView.completions(forPartialWordRange: textView.rangeForUserCompletion, indexOfSelectedItem: &index), !candidates.isEmpty else { return nil }
        
        return candidates
    }
    
}
