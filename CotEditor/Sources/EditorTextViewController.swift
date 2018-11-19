//
//  EditorTextViewController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-06-18.
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

final class EditorTextViewController: NSViewController, NSTextViewDelegate {
    
    // MARK: Public Properties
    
    var showsLineNumber: Bool {
        
        get {
            return self.scrollView?.rulersVisible ?? false
        }
        
        set {
            self.scrollView?.rulersVisible = newValue
        }
    }
    
    
    var textView: EditorTextView? {
        
        return self.scrollView?.documentView as? EditorTextView
    }

    
    
    // MARK: -
    // MARK: Text View Delegate
    
    /// text will be edited
    func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
        
        // standardize line endings to LF
        // -> Line endings replacemement on file read is processed in `Document.read(from:ofType:)`
        if let replacementString = replacementString,  // = only attributes changed
            !replacementString.isEmpty,  // = text deleted
            textView.undoManager?.isUndoing != true,  // = undo
            let lineEnding = replacementString.detectedLineEnding,  // = no line endings
            lineEnding != .lf
        {
            return !textView.replace(with: replacementString.replacingLineEndings(with: .lf),
                                     range: affectedCharRange,
                                     selectedRange: nil)
        }
        
        return true
    }
    
    
    /// add script menu to context menu
    func textView(_ view: NSTextView, menu: NSMenu, for event: NSEvent, at charIndex: Int) -> NSMenu? {
        
        // append Script menu
        if let scriptMenu = ScriptManager.shared.contexualMenu {
            let item = NSMenuItem(title: "", action: nil, keyEquivalent: "")
            item.image = #imageLiteral(resourceName: "ScriptTemplate")
            item.toolTip = "Scripts".localized
            item.submenu = scriptMenu
            menu.addItem(item)
        }
        
        return menu
    }
    
    
    
    // MARK: Action Messages
    
    /// show Go To sheet
    @IBAction func gotoLocation(_ sender: Any?) {
        
        guard
            let textView = self.textView,
            let viewController = GoToLineViewController(textView: textView)
            else { return assertionFailure() }
        
        self.presentAsSheet(viewController)
    }
    
    
    
    // MARK: Private Methods
    
    /// cast view to NSScrollView
    private var scrollView: NSScrollView? {
        
        return self.view as? NSScrollView
    }
    
}
