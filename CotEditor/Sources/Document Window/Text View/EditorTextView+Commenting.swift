//
//  EditorTextView+Commenting.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-01-10.
//
//  ---------------------------------------------------------------------------
//
//  © 2014-2024 1024jp
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
import Syntax
import TextEditing

extension EditorTextView: Commenting {
    
    // MARK: Action Messages
    
    /// Toggles the comment state of the selections.
    @IBAction func toggleComment(_ sender: Any?) {
        
        if self.canUncomment(partly: false) {
            self.uncomment()
        } else {
            self.commentOut(types: .both, fromLineHead: true)
        }
    }
    
    
    /// Comments out the selections by appending comment delimiters.
    @IBAction func commentOut(_ sender: Any?) {
        
        self.commentOut(types: .both, fromLineHead: false)
    }
    
    
    /// Comments out the selections by appending block comment delimiters.
    @IBAction func blockCommentOut(_ sender: Any?) {
        
        self.commentOut(types: .block, fromLineHead: false)
    }
    
    
    /// Comments out the selections by appending inline comment delimiters.
    @IBAction func inlineCommentOut(_ sender: Any?) {
        
        self.commentOut(types: .inline, fromLineHead: false)
    }
    
    
    /// Uncomments the selections by removing comment delimiters.
    @IBAction func uncomment(_ sender: Any?) {
        
        self.uncomment()
    }
}


// MARK: - Protocol

@MainActor protocol Commenting: NSTextView {
    
    var commentDelimiters: Syntax.Comment { get }
}


extension Commenting {
    
    /// Comments out the selections by appending comment delimiters.
    ///
    /// - Parameters:
    ///   - types: The type of commenting-out. When, `.both`, inline-style takes priority over block-style.
    ///   - fromLineHead: When `true`, the receiver comments out from the beginning of the line.
    func commentOut(types: CommentTypes, fromLineHead: Bool) {
        
        guard
            let selectedRanges = self.rangesForUserTextChange?.map(\.rangeValue),
            let context = self.string.commentOut(types: types, delimiters: self.commentDelimiters, fromLineHead: fromLineHead, in: selectedRanges)
        else { return }
        
        self.edit(with: context, actionName: String(localized: "Comment Out", table: "MainMenu"))
    }
    
    
    /// Uncomments the selections by removing comment delimiters.
    func uncomment() {
        
        guard
            let selectedRanges = self.rangesForUserTextChange?.map(\.rangeValue),
            let context = self.string.uncomment(delimiters: self.commentDelimiters, in: selectedRanges)
        else { return }
        
        self.edit(with: context, actionName: String(localized: "Uncomment", table: "MainMenu"))
    }
    
    
    /// Returns whether the selected ranges can be uncommented.
    ///
    /// - Parameter partly: When `true`, the method returns `true` when a part of selections is commented-out,
    ///                     otherwise only when the entire selections can be commented out.
    /// - Returns: `true` when selection can be uncommented.
    func canUncomment(partly: Bool) -> Bool {
        
        guard let selectedRanges = self.rangesForUserTextChange?.map(\.rangeValue) else { return false }
        
        return self.string.canUncomment(partly: partly, delimiters: self.commentDelimiters, in: selectedRanges)
    }
}
