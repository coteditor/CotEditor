/*
 
 EditorWrapper+Editor.swift
 
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

extension EditorWrapper {
    
    /// return string in text view (LF fix)
    var string: String {
        
        return self.focusedTextView?.string ?? ""
    }
    
    
    /// return current selection
    var substringWithSelection: String? {
        
        guard let selectedRange = self.focusedTextView?.selectedRange else { return nil }
        
        return (self.string as NSString).substring(with: selectedRange)
    }
    
    
    /// replace selected text with given string and select inserted range
    func insert(string: String) {
        
        self.focusedTextView?.insert(string: string)
    }
    
    
    /// insert given string just after current selection and select inserted range
    func insertAfterSelection(string: String) {
        
        self.focusedTextView?.insertAfterSelection(string: string)
    }
    
    
    /// swap whole current string with given string and select inserted range
    func replaceAllString(with string: String) {
        
        self.focusedTextView?.replaceAllString(with: string)
    }
    
    
    /// append string at the end of the whole string and select inserted range
    func append(string: String) {
        
        self.focusedTextView?.append(string: string)
    }
    
    
    /// selected range in focused text view
    var selectedRange: NSRange {
        get {
            guard let textView = self.focusedTextView else { return .notFound }
            
            return textView.string!.convert(from: .LF, to: self.document?.lineEnding ?? .LF,
                                            range: textView.selectedRange)
        }
        set (selectedRange) {
            guard let textView = self.focusedTextView else { return }
            
            textView.selectedRange = textView.string!.convert(from: self.document?.lineEnding ?? .LF, to: .LF,
                                                              range: textView.selectedRange)
        }
    }
    
}
