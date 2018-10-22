//
//  EditorTextView+Accessibility.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-10-21.
//
//  ---------------------------------------------------------------------------
//
//  © 2018 1024jp
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

extension EditorTextView {
    
    // -> Regard VoiceOver, a line number is 0-based.
    
    
    /// return the line number for the logical line holding the specified character index (the default implementation returns the number of visual lines)
    override func accessibilityLine(for index: Int) -> Int {
        
        return self.string.lineNumber(at: index) - 1
    }
    
    
    /// return the line number for the logical line holding the insertion point.
    override func accessibilityInsertionPointLineNumber() -> Int {
        
        return self.accessibilityLine(for: self.selectedRange.location)
    }
    
    
    /// return range of characters in the logical line (the default implementation returns the range of the visual line)
    override func accessibilityRange(forLine lineNumber: Int) -> NSRange {
        
        return self.string.range(forLine: lineNumber + 1)  // 0-based to 1-based
    }
    
}



// MARK: -

private extension String {
    
    /// chracter range of line at line number (1-based) including newline characters.
    func range(forLine lineNumber: Int) -> NSRange {
        
        var counter = 0
        var lineRagne: NSRange = .notFound
        (self as NSString).enumerateSubstrings(in: self.nsRange, options: [.byLines, .substringNotRequired]) { (_, _, enclosingRange, stop) in
            counter += 1
            
            if counter == lineNumber {
                lineRagne = enclosingRange
                stop.pointee = true
            }
        }
        
        return lineRagne
    }
    
}
