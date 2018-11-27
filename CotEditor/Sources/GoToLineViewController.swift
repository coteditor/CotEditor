//
//  GoToLineViewController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-06-07.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2018 1024jp
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

final class GoToLineViewController: NSViewController {
    
    // MARK: Public Properties
    
    var textView: NSTextView? {
        
        didSet {
            guard let textView = textView else { return }
            
            let string = textView.string
            let lineNumber = string.lineNumber(at: textView.selectedRange.location)
            let lineCount = (string as NSString).substring(with: textView.selectedRange).numberOfLines
            
            self.location = String(lineNumber)
            if lineCount > 1 {
                self.location += ":" + String(lineCount)
            }
        }
    }
    
    
    // MARK: Private Properties
    
    @objc private dynamic var location: String = ""
    
    
    
    // MARK: -
    // MARK: Action Messages
    
    /// apply
    @IBAction func ok(_ sender: Any?) {
        
        guard self.selectLocation() else {
            NSSound.beep()
            return
        }
        
        self.dismiss(sender)
    }
    
    
    
    // MARK: Private Methods
    
    /// select location in textView
    private func selectLocation() -> Bool {
        
        let loclen = self.location.components(separatedBy: ":").map { Int($0) }
        
        guard
            let location = loclen[0],
            let length = (loclen.count > 1) ? loclen[1] : 0,
            let textView = self.textView,
            let range = textView.string.rangeForLine(location: location, length: length)
            else { return false }
        
        textView.selectedRange = range
        textView.scrollRangeToVisible(range)
        textView.showFindIndicator(for: range)
        
        return true
    }
    
}
