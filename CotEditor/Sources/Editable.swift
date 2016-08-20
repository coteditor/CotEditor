/*
 
 Editable.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-06-07.
 
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
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

protocol Editable: class {
    
    var textView: NSTextView? { get }
    var lineEnding: LineEnding { get }
}



extension Editable {
    
    /// return string in text view (LF fix)
    var string: String {
        
        return self.textView?.string ?? ""
    }
    
    
    /// return current selection
    var substringWithSelection: String? {
        
        guard let selectedRange = self.textView?.selectedRange else { return nil }
        
        return (self.string as NSString).substring(with: selectedRange)
    }
    
    
    /// selected range in focused text view
    var selectedRange: NSRange {
        
        get {
            guard let textView = self.textView else { return .notFound }
            
            return textView.string!.convert(from: .LF, to: self.lineEnding, range: textView.selectedRange)
        }
        
        set (selectedRange) {
            guard let textView = self.textView else { return }
            
            textView.selectedRange = textView.string!.convert(from: self.lineEnding, to: .LF, range: textView.selectedRange)
        }
    }
    
    
    /// replace selected text with given string and select inserted range
    func insert(string: String) {
        
        self.textView?.insert(string: string)
    }
    
    
    /// insert given string just after current selection and select inserted range
    func insertAfterSelection(string: String) {
        
        self.textView?.insertAfterSelection(string: string)
    }
    
    
    /// swap whole current string with given string and select inserted range
    func replaceAllString(with string: String) {
        
        self.textView?.replaceAllString(with: string)
    }
    
    
    /// append string at the end of the whole string and select inserted range
    func append(string: String) {
        
        self.textView?.append(string: string)
    }
    
}



// MARK: -

private extension NSTextView {
    
    /// treat programmatic text insertion
    func insert(string: String) {
        
        let replacementRange = self.selectedRange
        
        guard self.shouldChangeText(in: replacementRange, replacementString: string) else { return }
        
        self.replaceCharacters(in: replacementRange, with: string)
        self.selectedRange = NSRange(location: replacementRange.location, length: string.utf16.count)
        
        self.undoManager?.setActionName(NSLocalizedString("Insert Text", comment: ""))
        
        self.didChangeText()
    }
    
    
    /// insert given string just after current selection and select inserted range
    func insertAfterSelection(string: String) {
        
        let replacementRange = NSRange(location: self.selectedRange.max, length: 0)
        
        guard self.shouldChangeText(in: replacementRange, replacementString: string) else { return }
        
        self.replaceCharacters(in: replacementRange, with: string)
        self.selectedRange = NSRange(location: replacementRange.location, length: string.utf16.count)
        
        self.undoManager?.setActionName(NSLocalizedString("Insert Text", comment: ""))
        
        self.didChangeText()
    }
    
    
    /// swap whole current string with given string and select inserted range
    func replaceAllString(with string: String) {
        
        let replacementRange = self.string?.nsRange ?? NSRange()
        
        guard self.shouldChangeText(in: replacementRange, replacementString: string) else { return }
        
        self.replaceCharacters(in: replacementRange, with: string)
        self.selectedRange = NSRange(location: replacementRange.location, length: string.utf16.count)
        
        self.undoManager?.setActionName(NSLocalizedString("Replace Text", comment: ""))
        
        self.didChangeText()
    }
    
    
    /// append string at the end of the whole string and select inserted range
    func append(string: String) {
        
        let replacementRange = NSRange(location: self.string?.utf16.count ?? 0, length: 0)
        
        guard self.shouldChangeText(in: replacementRange, replacementString: string) else { return }
        
        self.replaceCharacters(in: replacementRange, with: string)
        self.selectedRange = NSRange(location: replacementRange.location, length: string.utf16.count)
        
        self.undoManager?.setActionName(NSLocalizedString("Insert Text", comment: ""))
        
        self.didChangeText()
    }
    
}
