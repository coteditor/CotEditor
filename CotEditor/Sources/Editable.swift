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
//  © 2014-2019 1024jp
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


enum InsertionLocation {
    
    case replaceSelection
    case afterSelection
    case replaceAll
    case afterAll
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
            guard let textView = self.textView else { return assertionFailure() }
            
            textView.selectedRange = textView.string.convert(range: newValue, from: self.lineEnding, to: .lf)
        }
    }
    
    
    /// insert string at desire location and select inserted range
    func insert(string: String, at location: InsertionLocation) {
        
        guard let textView = self.textView else { return assertionFailure() }
        
        textView.insert(string: string, at: location)
    }
    
}


private extension NSTextView {
    
    /// Insert string at desire location and select inserted range.
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
                     actionName: "Insert Text".localized)
    }
    
}
