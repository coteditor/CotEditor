/*
 
 FindPanelTextView.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2015-03-04.
 
 ------------------------------------------------------------------------------
 
 © 2015-2016 1024jp
 
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

/// text view that behaves like a NSTextField
final class FindPanelTextView: NSTextView {
    
    // MARK: Private Properties
    
    @IBInspectable var performsActionOnEnter: Bool = false
    
    
    
    // MARK:
    // MARK: Lifecycle
    
    required init?(coder: NSCoder) {
        
        super.init(coder: coder)
        
        // set system font (standard NSTextField behavior)
        self.font = NSFont.systemFont(ofSize: NSFont.systemFontSize())
        
        // set inset a bit like NSTextField (horizontal inset is added in FindPanelTextClipView)
        self.textContainerInset = NSSize(width: 0.0, height: 2.0)
        
        // avoid wrapping
        self.textContainer?.widthTracksTextView = false
        self.textContainer?.containerSize = NSSize.infinite
        self.isHorizontallyResizable = true
        
        // disable automatic text substitutions
        self.isAutomaticQuoteSubstitutionEnabled = false
        self.isAutomaticDashSubstitutionEnabled = false
        self.isAutomaticTextReplacementEnabled = false
        self.isAutomaticSpellingCorrectionEnabled = false
        self.smartInsertDeleteEnabled = false
        
        // set subclassed layout manager for invisible characters
        let layoutManager = FindPanelLayoutManager()
        layoutManager.usesScreenFonts = true
        self.textContainer?.replaceLayoutManager(layoutManager)
    }
    
    
    
    // MARK: TextView Methods
    
    /// view is on focus
    override func becomeFirstResponder() -> Bool {
        
        // select whole string on focus (standard NSTextField behavior)
        self.selectedRange = self.string?.nsRange ?? .notFound
        
        return super.becomeFirstResponder()
    }
    
    
    /// view dismiss focus
    override func resignFirstResponder() -> Bool {
        
        // clear current selection (standard NSTextField behavior)
        self.selectedRange = NSRange(location: 0, length: 0)
        
        return super.resignFirstResponder()
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
    
    
    /// swap '¥' with '\' if needed
    override func insertText(_ string: Any, replacementRange: NSRange) {
        
        // cast input to String
        var str: String = {
            if let string = string as? NSAttributedString {
                return string.string
            }
            return string as! String
        }()
        
        // swap '¥' with '\' if needed
        if Defaults[.swapYenAndBackSlash] {
            switch str {
            case "\\":
                str = "¥"
            case "¥":
                str = "\\"
            default: break
            }
        }
        
        super.insertText(str, replacementRange: replacementRange)
    }
    
}
