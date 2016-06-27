/*
 
 GoToLineViewController.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-06-07.
 
 ------------------------------------------------------------------------------
 
 © 2016 1024jp
 
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

class GoToLineViewController: NSViewController {
    
    // MARK: Private Properties
    
    private let textView: NSTextView
    private dynamic var location: String = ""
    
    
    
    // MARK:
    // MARK: Lifecycle
    
    required init?(textView: NSTextView) {
        
        self.textView = textView
        
        super.init(nibName: nil, bundle: nil)
        
        let string = (self.textView.string as NSString?) ?? ""
        let lineNumber = string.lineNumber(at: UInt(textView.selectedRange().location))
        let lineCount = (string.substring(with: textView.selectedRange()) as NSString).numberOfLines()
        
        self.location = String(lineNumber)
        if lineCount > 1 {
            self.location += ":" + String(lineCount)
        }
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override var nibName: String? {
        
        return "GoToLineView"
    }
    
    
    
    // MARK: Action Messages
    
    /// apply
    @IBAction func ok(_ sender: AnyObject?) {
        
        guard self.selectLocation() else {
            NSBeep()
            return
        }
        
        self.dismiss(sender)
    }
    
    
    
    // MARK: Private Methods
    
    /// select location in textView
    private func selectLocation() -> Bool {
        
        let loclen = self.location.components(separatedBy: ":")
        
        guard let location = Int(loclen[0]),
              let length = (loclen.count > 1) ? Int(loclen[1]) : 0 else { return false }
        
        let string = (self.textView.string as NSString?) ?? ""
        let range = string.range(forLineLocation: location, length: length)
        
        guard range.location != NSNotFound else { return false }
        
        self.textView.setSelectedRange(range)
        self.textView.scrollRangeToVisible(range)
        self.textView.showFindIndicator(for: range)
        
        return true
    }
    
}
