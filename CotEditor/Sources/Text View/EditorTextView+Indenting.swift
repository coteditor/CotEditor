//
//  EditorTextView+Indenting.swift
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
import TextEditing

extension EditorTextView: Indenting {
    
    // MARK: Action Messages
    
    /// Increases indent level.
    @IBAction func shiftRight(_ sender: Any?) {
        
        if self.baseWritingDirection == .rightToLeft {
            guard self.outdent() else { return }
        } else {
            guard self.indent() else { return }
        }
        
        self.undoManager?.setActionName(String(localized: "Shift Right", table: "MainMenu"))
    }
    
    
    /// Decreases indent level.
    @IBAction func shiftLeft(_ sender: Any?) {
        
        if self.baseWritingDirection == .rightToLeft {
            guard self.indent() else { return }
        } else {
            guard self.outdent() else { return }
        }
        
        self.undoManager?.setActionName(String(localized: "Shift Left", table: "MainMenu"))
    }
    
    
    /// Shifts selection from segmented control button.
    @IBAction func shift(_ sender: NSSegmentedControl) {
        
        switch sender.selectedSegment {
            case 0:
                self.shiftLeft(sender)
            case 1:
                self.shiftRight(sender)
            default:
                assertionFailure("Segmented shift button must have 2 segments only.")
        }
    }
    
    
    /// Standardizes indentation in selection to spaces.
    @IBAction func convertIndentationToSpaces(_ sender: Any?) {
        
        self.convertIndentation(style: .space)
    }
    
    
    /// Standardizes indentation in selection to tabs.
    @IBAction func convertIndentationToTabs(_ sender: Any?) {
        
        self.convertIndentation(style: .tab)
    }
}


// MARK: - Protocol

@MainActor protocol Indenting: NSTextView {
    
    var tabWidth: Int { get }
    var isAutomaticTabExpansionEnabled: Bool { get }
}


extension Indenting {
    
    private var indentStyle: IndentStyle  { self.isAutomaticTabExpansionEnabled ? .space : .tab }
    
    
    /// Increases indent level of the selected ranges.
    @discardableResult
    func indent() -> Bool {
        
        guard
            self.tabWidth > 0,
            let selectedRanges = self.rangesForUserTextChange?.map(\.rangeValue)
        else { return false }
        
        let textEditing = self.string.indent(style: self.indentStyle, indentWidth: self.tabWidth, in: selectedRanges)
        
        return self.edit(with: textEditing)
    }
    
    
    /// Decreases indent level of the selected ranges.
    @discardableResult
    func outdent() -> Bool {
        
        guard
            self.tabWidth > 0,
            let selectedRanges = self.rangesForUserTextChange?.map(\.rangeValue),
            let textEditing = self.string.outdent(style: self.indentStyle, indentWidth: self.tabWidth, in: selectedRanges)
        else { return false }
        
        return self.edit(with: textEditing)
    }
    
    
    /// Standardizes indentation of given ranges in the selected ranges.
    func convertIndentation(style: IndentStyle) {
        
        guard
            self.tabWidth > 0,
            let selectedRanges = self.rangesForUserTextChange?.map(\.rangeValue),
            let textEditing = self.string.convertIndentation(to: self.indentStyle, indentWidth: self.tabWidth, in: selectedRanges)
        else { return }
        
        self.edit(with: textEditing, actionName: String(localized: "Convert Indentation", table: "MainMenu"))
    }
}
