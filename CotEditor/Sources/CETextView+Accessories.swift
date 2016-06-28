/*
 
 CETextView+Accessories.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-06-10.
 
 ------------------------------------------------------------------------------
 
 © 2014-2016 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Cocoa

extension CETextView: UnicodeInputReceiver {
    
    // MARK: Action Messages
    
    /// show Unicode input panel
    @IBAction func showUnicodeInputPanel(_ sender: AnyObject?) {
        
        UnicodeInputPanelController.shared.showWindow(self)
    }
    
    
    
    // MARK: Protocol
    
    /// insert an Unicode character from Unicode input panel
    @IBAction func insertUnicodeCharacter(_ sender: UnicodeInputPanelController) {
        
        guard let character = sender.characterString else { return }
        
        let range = self.rangeForUserTextChange
        
        if self.shouldChangeText(in: range, replacementString: character) {
            self.replaceCharacters(in: range, with: character)
            self.didChangeText()
        }
    }
    
}



extension CETextView: ColorCodeReceiver {
    
    // MARK: Action Messages
    
    /// show Unicode input panel
    @IBAction func editColorCode(_ sender: AnyObject?) {
        
        ColorCodePanelController.shared.showWindow(self)
        
        if let selected = (self.string as NSString?)?.substring(with: self.selectedRange()) {
            ColorCodePanelController.shared.setColor(withCode: selected)
        }
    }
    
    
    /// avoid changing text color by color panel
    @IBAction override public func changeColor(_ sender: AnyObject?) { }
    
    
    
    // MARK: Protocol
    
    /// insert color code from color code panel
    @IBAction func insertColorCode(_ sender: ColorCodePanelController) {
        
        guard let colorCode = sender.colorCode else { return }
        
        let range = self.rangeForUserTextChange
        
        if self.shouldChangeText(in: range, replacementString: colorCode) {
            self.replaceCharacters(in: range, with: colorCode)
            self.didChangeText()
            self.undoManager?.setActionName(NSLocalizedString("Insert Color Code", comment: ""))
            self.setSelectedRange(NSRange(location: range.location, length: colorCode.utf16.count))
            self.centerSelectionInVisibleArea(self)
        }
    }
    
}
