//
//  NSViewController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2020-01-21.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2025 1024jp
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

extension NSViewController {
    
    /// A Boolean value indicating whether the view is hidden.
    ///
    /// This computed property avoid unwanted view loading when the view is not yet loaded.
    /// However, it does not check whether the view is actually visible. For that, see the discussion part of `isHiddenOrHasHiddenAncestor`.
    final var isViewShown: Bool {
        
        self.viewIfLoaded?.isHiddenOrHasHiddenAncestor == false
    }
    
    
    /// Presents an error alert as a window modal sheet.
    final func presentErrorAsSheet(_ error: some Error) {
        
        if self.isViewLoaded, let window = self.view.window {
            self.presentError(error, modalFor: window, delegate: nil, didPresent: nil, contextInfo: nil)
        } else {
            self.presentError(error)
        }
    }
    
    
    /// Safely ends the current editing.
    ///
    /// - Returns: `true` when the operation is successful; otherwise, `false`.
    @discardableResult
    final func endEditing() -> Bool {
        
        guard let window = self.viewIfLoaded?.window else { return true }
        
        return window.makeFirstResponder(nil)
    }
}
