//
//  NSWindow+Responder.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-10-13.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2020 1024jp
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

extension NSWindow {
    
    /// end current editing and restore the current responder afterwards
    @discardableResult
    func endEditing() -> Bool {
        
        let responder: NSResponder?
        if let editor = self.firstResponder as? NSTextView, editor.isFieldEditor {
            // -> Regarding field editors, the real first responder is its delegate.
            responder = editor.delegate as? NSResponder
        } else {
            responder = self.firstResponder
        }
        
        let sucsess = self.makeFirstResponder(nil)
        
        // restore current responder
        if sucsess, let responder = responder {
            self.makeFirstResponder(responder)
        }
        
        return sucsess
    }
}



extension NSViewController {
    
    /// end current editing and restore the current responder afterwards
    @discardableResult
    func endEditing() -> Bool {
        
        guard self.isViewLoaded else { return true }
        
        return self.view.window?.endEditing() ?? false
    }
}
