//
//  EditorTextView+SurroundSelection.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2017-03-19.
//
//  ---------------------------------------------------------------------------
//
//  © 2017-2024 1024jp
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
import SwiftUI
import StringUtils

extension EditorTextView {
    
    // MARK: Action Messages
    
    /// Inserts single quotation marks ' around the selections.
    @IBAction func surroundSelectionWithSingleQuotes(_ sender: Any?) {
        
        self.surroundSelections(begin: "'", end: "'")
    }
    
    
    /// Inserts double quotation marks " around the selections.
    @IBAction func surroundSelectionWithDoubleQuotes(_ sender: Any?) {
        
        self.surroundSelections(begin: "\"", end: "\"")
    }
    
    
    /// Inserts pairs of parentheses () around the selections.
    @IBAction func surroundSelectionWithParentheses(_ sender: Any?) {
        
        self.surroundSelections(begin: "(", end: ")")
    }
    
    
    /// Inserts pairs of braces {} around the selections.
    @IBAction func surroundSelectionWithBraces(_ sender: Any?) {
        
        self.surroundSelections(begin: "{", end: "}")
    }
    
    
    /// Inserts square brackets [] around the selections.
    @IBAction func surroundSelectionWithSquareBrackets(_ sender: Any?) {
        
        self.surroundSelections(begin: "[", end: "]")
    }
    
    
    /// Shows the custom surround sheet.
    @IBAction func surroundSelection(_ sender: Any?) {
        
        let view = CustomSurroundView(pair: self.customSurroundPair) { [weak self] pair in
            self?.surroundSelections(begin: pair.begin, end: pair.end)
            self?.customSurroundPair = pair
        }
        let viewController = NSHostingController(rootView: view)
        viewController.rootView.parent = viewController
        
        self.viewControllerForSheet?.presentAsSheet(viewController)
    }
}


extension NSTextView {
    
    /// Inserts strings around selections.
    @discardableResult
    final func surroundSelections(begin: String, end: String) -> Bool {
        
        guard let selectedRanges = self.rangesForUserTextChange?.map(\.rangeValue) else { return false }
        
        let string = self.string as NSString
        
        let replacementStrings = selectedRanges.map { begin + string.substring(with: $0) + end }
        let newSelectedRanges = selectedRanges.enumerated().map { (offset, range) in
            range.shifted(by: (offset + 1) * begin.length + offset * end.length)
        }
        
        return self.replace(with: replacementStrings, ranges: selectedRanges, selectedRanges: newSelectedRanges)
    }
}
