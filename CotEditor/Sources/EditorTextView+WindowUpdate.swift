//
//  EditorTextView+WindowUpdate.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-12-02.
//
//  ---------------------------------------------------------------------------
//
//  © 2018 1024jp
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

extension EditorTextView {
    
    // MARK: View Methods
    
    /// update layer (called also when system appearance was changed)
    override func updateLayer() {
        
        // -> super dirty workaround to update titlebar's backaround color by considering the real "current" appearance (2018-09 macOS 10.14)
        if #available(macOS 10.14, *) {
            (self.window as? DocumentWindow)?.invalidateTitlebarOpacity()
        }
    }
    
}
