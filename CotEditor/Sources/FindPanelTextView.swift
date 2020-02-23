//
//  FindPanelTextView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2015-03-04.
//
//  ---------------------------------------------------------------------------
//
//  © 2015-2020 1024jp
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

/// text view that behaves like a NSTextField
class FindPanelTextView: NSTextView {
    
    // MARK: Private Properties
    
    @IBInspectable private var performsActionOnEnter: Bool = false
    
    @objc private dynamic var isEmpty: Bool = true
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    required init?(coder: NSCoder) {
        
        super.init(coder: coder)
        
        // set system font (standard NSTextField behavior)
        self.font = NSFont.systemFont(ofSize: 0)
        
        // set inset a bit like NSTextField (horizontal inset is added in FindPanelTextClipView)
        self.textContainerInset = NSSize(width: 0.0, height: 2.0)
        
        // avoid wrapping
        self.textContainer?.widthTracksTextView = false
        self.textContainer?.size = .infinite
        self.isHorizontallyResizable = true
        
        // disable automatic text substitutions
        self.isAutomaticQuoteSubstitutionEnabled = false
        self.isAutomaticDashSubstitutionEnabled = false
        self.isAutomaticTextReplacementEnabled = false
        self.isAutomaticSpellingCorrectionEnabled = false
        self.smartInsertDeleteEnabled = false
        
        // set subclassed layout manager for invisible characters
        let layoutManager = FindPanelLayoutManager()
        self.textContainer?.replaceLayoutManager(layoutManager)
    }
    
    
    
    // MARK: TextView Methods
    
    /// view is on focus
    override func becomeFirstResponder() -> Bool {
        
        // select whole string on focus (standard NSTextField behavior)
        self.selectedRange = self.string.nsRange
        
        return super.becomeFirstResponder()
    }
    
    
    /// view dismiss focus
    override func resignFirstResponder() -> Bool {
        
        // clear current selection (standard NSTextField behavior)
        self.selectedRange = NSRange(0..<0)
        
        return super.resignFirstResponder()
    }
    
    
    /// content string did update
    override func didChangeText() {
        
        super.didChangeText()
        
        self.isEmpty = self.string.isEmpty
    }
    
    
    /// string did udpate via binding
    override var string: String {
        
        didSet {
            self.isEmpty = string.isEmpty
        }
    }
    
    
    /// perform Find Next with return
    override func insertNewline(_ sender: Any?) {
        
        // perform Find Next in find string field (standard NSTextField behavior)
        if performsActionOnEnter {
            TextFinder.shared.findNext(self)
        }
    }
    
    
    /// jump to the next responder with tab key (standard NSTextField behavior)
    override func insertTab(_ sender: Any?) {
        
        self.window?.makeFirstResponder(self.nextKeyView)
    }
    
    
    /// jump to the previous responder with tab key (standard NSTextField behavior)
    override func insertBacktab(_ sender: Any?) {
        
        self.window?.makeFirstResponder(self.previousKeyView)
    }
    
    
    /// swap '¥' with '\' if needed
    override func insertText(_ string: Any, replacementRange: NSRange) {
        
        // cast input to String
        var string = String(anyString: string)
        
        // swap '¥' with '\' if needed
        if UserDefaults.standard[.swapYenAndBackSlash] {
            switch string {
                case "\\":
                    string = "¥"
                case "¥":
                    string = "\\"
                default: break
            }
        }
        
        super.insertText(string, replacementRange: replacementRange)
    }
    
    
    
    // MARK: Actions
    
    /// clear current text
    @IBAction func clear(_ sender: Any?) {
        
        guard self.shouldChangeText(in: self.string.nsRange, replacementString: "") else { return }
        
        self.window?.makeFirstResponder(self)
        self.string = ""
        
        self.didChangeText()
    }
    
}
