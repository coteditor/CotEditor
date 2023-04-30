//
//  NSTextView+ScriptingSupport.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-06-07.
//
//  ---------------------------------------------------------------------------
//
//  © 2004-2007 nakamuxu
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

enum InsertionLocation {
    
    case replaceSelection
    case afterSelection
    case replaceAll
    case afterAll
}


extension NSTextView {
    
    /// Insert string at desired location and select inserted range.
    func insert(string: String, at location: InsertionLocation) {
        
        let replacementRange: NSRange = {
            switch location {
                case .replaceSelection:
                    return self.selectedRange
                case .afterSelection:
                    return NSRange(location: self.selectedRange.upperBound, length: 0)
                case .replaceAll:
                    return self.string.nsRange
                case .afterAll:
                    return NSRange(location: (self.string as NSString).length, length: 0)
            }
        }()
        
        let selectedRange = NSRange(location: replacementRange.location, length: (string as NSString).length)
        
        self.replace(with: string, range: replacementRange, selectedRange: selectedRange,
                     actionName: String(localized: "Insert Text"))
    }
}
