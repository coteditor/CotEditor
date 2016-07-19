/*
 
 CEEditorWrapper+Editor.swift
 
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

// MARK: Text Editing
extension CEEditorWrapper {
    
    /// return string in text view (LF fix)
    var string: String {
        
        return self.focusedTextView?.string ?? ""
    }
    
    
    /// return string in passed-in range
    func substring(range: NSRange) -> String {
        
        return (self.string as NSString).substring(with: range)
    }
    
    var substringWithSelection: String? {
        
        guard let selectedRange = self.focusedTextView?.selectedRange() else { return nil }
        
        return (self.string as NSString).substring(with: selectedRange)
    }
    
    
    /// replace selected text with given string and select inserted range
    func insert(string: String) {
        
        self.focusedTextView?.insertString(string)
    }
    
    
    /// insert given string just after current selection and select inserted range
    func insert(stringAfterSelection string: String) {
        
        self.focusedTextView?.insertString(afterSelection: string)
    }
    
    
    /// swap whole current string with given string and select inserted range
    func replaceAllString(with string: String) {
        
        self.focusedTextView?.appendString(string)
    }
    
    
    /// append string at the end of the whole string and select inserted range
    func append(string: String) {
        
        self.focusedTextView?.appendString(string)
    }
    
    
    /// selected range in focused text view
    var selectedRange: NSRange {
        get {
            guard let textView = self.focusedTextView else { return NotFoundRange }
            
            return (textView.string! as NSString).convert(textView.selectedRange(),
                                                          from: .LF, to: self.document?.lineEnding ?? .LF)
        }
        set (selectedRange) {
            guard let textView = self.focusedTextView else { return }
            
            let range = (textView.string! as NSString).convert(textView.selectedRange(),
                                                               from: self.document?.lineEnding ?? .LF, to: .LF)
            
            textView.setSelectedRange(range)
        }
    }
    
}



// MARK: Locating

extension CEEditorWrapper {
    
    // MARK: Public Methods
    
    /// convert minus location/length to NSRange
    func range(location: Int, length: Int) -> NSRange {
        
        let documentString = (self.string as NSString).replacingNewLineCharacers(with: self.document?.lineEnding ?? .LF)
        
        return documentString.range(location: location, length: length)
    }
    
    
    /// select characters in focused textView
    func setSelectedCharacterRange(location: Int, length: Int) {
        
        let range = self.range(location: location, length: length)
        
        guard range.location != NSNotFound else { return }
        
        self.selectedRange = range
    }
    
    
    /// select lines in focused textView
    func setSelectedLineRange(location: Int, length: Int) {
        
        // you can ignore actuall line ending type and directly comunicate with textView, as this handle just lines
        guard let textView = self.focusedTextView, let string = textView.string else { return }
        
        let range = (string as NSString).rangeForLine(location: location, length: length)
        
        
        guard range.location != NSNotFound else { return }
        
        self.selectedRange = range
    }
    
}
