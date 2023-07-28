//
//  EditorTextView+TouchBar.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-10-29.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2023 1024jp
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

private extension NSTouchBar.CustomizationIdentifier {
    
    static let textView = NSTouchBar.CustomizationIdentifier("com.coteditor.CotEditor.touchBar.textView")
}


extension NSTouchBarItem.Identifier {
    
    static let shift = NSTouchBarItem.Identifier("com.coteditor.CotEditor.TouchBarItem.shift")
    static let comment = NSTouchBarItem.Identifier("com.coteditor.CotEditor.TouchBarItem.comment")
    static let textSize = NSTouchBarItem.Identifier("com.coteditor.CotEditor.TouchBarItem.textSize")
}



extension EditorTextView {
    
    override func makeTouchBar() -> NSTouchBar? {
        
        let touchBar = super.makeTouchBar() ?? NSTouchBar()
        
        NSTouchBar.isAutomaticValidationEnabled = true
        
        touchBar.customizationIdentifier = .textView
        touchBar.defaultItemIdentifiers += [.fixedSpaceSmall, .shift, .comment, .textSize, .otherItemsProxy]
        touchBar.customizationAllowedItemIdentifiers += [.shift, .comment, .textSize]
        
        return touchBar
    }
    
    
    override func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        
        switch identifier {
            case .shift:
                let item = NSCustomTouchBarItem(identifier: identifier)
                let leftImage = NSImage(systemSymbolName: "decrease.indent", accessibilityDescription: String(localized: "Shift Left"))!
                let rightImage = NSImage(systemSymbolName: "increase.indent", accessibilityDescription: String(localized: "Shift Right"))!
                item.customizationLabel = String(localized: "Shift", comment: "touch bar item")
                item.view = NSSegmentedControl(images: [leftImage, rightImage],
                                               trackingMode: .momentary,
                                               target: self, action: #selector(shift))
                return item
                
            case .comment:
                let item = NSCustomTouchBarItem(identifier: identifier)
                item.customizationLabel = String(localized: "Comment", comment: "touch bar item")
                item.view = NSButton(image: NSImage(resource: .textCommentout), target: self, action: #selector(toggleComment))
                return item
                
            case .textSize:
                let item = NSPopoverTouchBarItem(identifier: identifier)
                item.customizationLabel = String(localized: "Text Size", comment: "touch bar item")
                item.collapsedRepresentationImage = NSImage(systemSymbolName: "textformat.size", accessibilityDescription: String(localized: "Text Size"))!
                item.popoverTouchBar = TextSizeTouchBar(textView: self)
                item.pressAndHoldTouchBar = TextSizeTouchBar(textView: self, forPressAndHold: true)
                return item
                
            default:
                return super.touchBar(touchBar, makeItemForIdentifier: identifier)
        }
    }
}



extension EditorTextView {
    
    // MARK: NSCandidateListTouchBarItemDelegate
    
    /// tell the delegate that a user has stopped touching candidates in the candidate list item.
    override func candidateListTouchBarItem(_ anItem: NSCandidateListTouchBarItem<AnyObject>, endSelectingCandidateAt index: Int) {
        
        // insert candidate by ourselves to workaround the unwanted behavior about insertion point with a word that starts with a symbol character: e.g. "__init__" in Python (2017-12 macOS 10.13)
        let range = self.rangeForUserCompletion
        
        guard
            let candidate = anItem.candidates[index] as? String,
            self.shouldChangeText(in: range, replacementString: candidate)
        else { return super.candidateListTouchBarItem(anItem, endSelectingCandidateAt: index) }
        
        self.replaceCharacters(in: range, with: candidate)
        self.didChangeText()
    }
}


extension EditorTextViewController {
    
    // MARK: NSTextViewDelegate
    
    /// suggest candidates for automatic text completion
    func textView(_ textView: NSTextView, candidatesForSelectedRange selectedRange: NSRange) -> [Any]? {
        
        var index = 0
        guard
            let candidates = textView.completions(forPartialWordRange: textView.rangeForUserCompletion, indexOfSelectedItem: &index),
            !candidates.isEmpty
        else { return nil }
        
        return candidates
    }
}
