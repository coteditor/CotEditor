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

fileprivate extension NSTouchBarCustomizationIdentifier {
    
    static let touchBar = NSTouchBarCustomizationIdentifier("com.coteditor.CotEditor.touchbar")
}


fileprivate extension NSTouchBarItemIdentifier {
    
    static let shift = NSTouchBarItemIdentifier("com.coteditor.CotEditor.TouchBarItem.shift")
    static let comment = NSTouchBarItemIdentifier("com.coteditor.CotEditor.TouchBarItem.comment")
}



@available(macOS 10.12.1, *)
extension EditorTextView {
    
    override func makeTouchBar() -> NSTouchBar? {
        
        let touchBar = super.makeTouchBar() ?? NSTouchBar()
        
        touchBar.customizationIdentifier = .touchBar
        touchBar.defaultItemIdentifiers += [.fixedSpaceSmall, .shift, .comment]
        touchBar.customizationAllowedItemIdentifiers += [.shift, .comment]
        
        return touchBar
    }
    
    
    override func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItemIdentifier) -> NSTouchBarItem? {
        
        let item = NSCustomTouchBarItem(identifier: identifier)
        
        switch identifier {
        case NSTouchBarItemIdentifier.shift:
            item.customizationLabel = NSLocalizedString("Shift", comment: "touch bar item")
            item.view = NSSegmentedControl(images: [#imageLiteral(resourceName: "ShiftLeftTemplate"), #imageLiteral(resourceName: "ShiftRightTemplate")], trackingMode: .momentary,
                                           target: self, action: #selector(shift(_:)))
            
        case NSTouchBarItemIdentifier.comment:
            item.customizationLabel = NSLocalizedString("Comment", comment: "touch bar item")
            item.view = NSButton(image: #imageLiteral(resourceName: "CommentTemplate"), target: self, action: #selector(toggleComment(_:)))
            
        default:
            return super.touchBar(touchBar, makeItemForIdentifier: identifier)
        }
        
        return item
    }
    
}



@available(macOS 10.12.1, *)
extension EditorTextViewController {
    
    /// suggest candidates for automatic text completion
    func textView(_ textView: NSTextView, candidatesForSelectedRange selectedRange: NSRange) -> [Any]? {
        
        var index = 0
        guard let candidates = textView.completions(forPartialWordRange: textView.rangeForUserCompletion, indexOfSelectedItem: &index), !candidates.isEmpty else { return nil }
        
        return candidates
    }
}
