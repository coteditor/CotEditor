//
//  Editable.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-06-07.
//
//  ---------------------------------------------------------------------------
//
//  © 2004-2007 nakamuxu
//  © 2014-2018 1024jp
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

protocol Editable: AnyObject {
    
    var textView: NSTextView? { get }
    var lineEnding: LineEnding { get }
    
    /// line ending applied document string
    var string: String { get }
}



extension Editable {
    
    /// line ending applied current selection
    var selectedString: String {
        
        guard let textView = self.textView else { return "" }
        
        let substring = (textView.string as NSString).substring(with: textView.selectedRange)
        
        return substring.replacingLineEndings(with: self.lineEnding)
    }
    
    
    /// selected range in focused text view
    var selectedRange: NSRange {
        
        get {
            guard let textView = self.textView else { return .notFound }
            
            return textView.string.convert(range: textView.selectedRange, from: .lf, to: self.lineEnding)
        }
        
        set {
            guard let textView = self.textView else { return }
            
            textView.selectedRange = textView.string.convert(range: newValue, from: self.lineEnding, to: .lf)
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
        
        self.undoManager?.setActionName("Insert Text".localized)
        
        self.didChangeText()
    }
    
    
    /// insert given string just after current selection and select inserted range
    func insertAfterSelection(string: String) {
        
        let replacementRange = NSRange(location: self.selectedRange.upperBound, length: 0)
        
        guard self.shouldChangeText(in: replacementRange, replacementString: string) else { return }
        
        self.replaceCharacters(in: replacementRange, with: string)
        self.selectedRange = NSRange(location: replacementRange.location, length: string.utf16.count)
        
        self.undoManager?.setActionName("Insert Text".localized)
        
        self.didChangeText()
    }
    
    
    /// swap whole current string with given string and select inserted range
    func replaceAllString(with string: String) {
        
        let replacementRange = self.string.nsRange
        
        guard self.shouldChangeText(in: replacementRange, replacementString: string) else { return }
        
        self.replaceCharacters(in: replacementRange, with: string)
        self.selectedRange = NSRange(location: replacementRange.location, length: string.utf16.count)
        
        self.undoManager?.setActionName("Replace Text".localized)
        
        self.didChangeText()
    }
    
    
    /// append string at the end of the whole string and select inserted range
    func append(string: String) {
        
        let replacementRange = NSRange(location: self.string.utf16.count, length: 0)
        
        guard self.shouldChangeText(in: replacementRange, replacementString: string) else { return }
        
        self.replaceCharacters(in: replacementRange, with: string)
        self.selectedRange = NSRange(location: replacementRange.location, length: string.utf16.count)
        
        self.undoManager?.setActionName("Insert Text".localized)
        
        self.didChangeText()
    }
    
}
