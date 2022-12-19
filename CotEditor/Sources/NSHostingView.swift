//
//  NSHostingView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2022-12-12.
//
//  ---------------------------------------------------------------------------
//
//  © 2022 1024jp
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

import SwiftUI

extension NSHostingController {
    
    @available(macOS, deprecated: 13, message: "Use .sizingOptions straightforward.")
    func ensureFrameSize() {
        
        // -> Needs to set the size beforehand
        //    to display the popover at the desired position (Xcode 14.0, FB10926162)
        assert(self.view.frame.isEmpty)
        self.view.frame.size = self.view.intrinsicContentSize
    }
}


extension NSHostingView {
    
    @available(macOS, deprecated: 13, message: "Use .sizingOptions straightforward.")
    func ensureFrameSize() {
        
        // -> Needs to set the size beforehand
        //    to display the popover at the desired position (Xcode 14.0, FB10926162)
        assert(self.frame.isEmpty)
        self.frame.size = self.intrinsicContentSize
    }
}
