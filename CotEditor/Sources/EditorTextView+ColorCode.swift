//
//  EditorTextView+ColorCode.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-06-10.
//
//  ---------------------------------------------------------------------------
//
//  © 2014-2023 1024jp
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

extension EditorTextView: ColorCodeReceiver {
    
    // MARK: Action Messages
    
    /// Show the Color panel with the color code control.
    @IBAction func editColorCode(_ sender: Any?) {
        
        ColorCodePanelController.shared.showWindow(colorCode: self.selectedString)
    }
    
    
    /// Avoid changing text color by the color panel.
    @IBAction override func changeColor(_ sender: Any?) { }
    
    
    
    // MARK: Protocol
    
    /// Insert color code from color code panel.
    ///
    /// - Parameter colorCode: The color code to insert.
    func insertColorCode(_ colorCode: String) {
        
        let range = self.rangeForUserTextChange
        
        guard self.shouldChangeText(in: range, replacementString: colorCode) else { return }
        
        self.replaceCharacters(in: range, with: colorCode)
        self.didChangeText()
        self.undoManager?.setActionName(String(localized: "Insert Color Code"))
        self.selectedRange = NSRange(location: range.location, length: colorCode.length)
        self.scrollRangeToVisible(self.selectedRange)
    }
}
