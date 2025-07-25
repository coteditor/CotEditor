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
    
    /// Presents an error alert to the user  as a window-modal sheet.
    final func presentErrorAsSheet(_ error: some Error) {
        
        if let window = self.viewIfLoaded?.window {
            self.presentError(error, modalFor: window, delegate: nil, didPresent: nil, contextInfo: nil)
        } else {
            self.presentError(error)
        }
    }
}
