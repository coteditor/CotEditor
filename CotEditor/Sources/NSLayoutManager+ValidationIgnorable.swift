//
//  NSLayoutManager+ValidationIgnorable.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2019-10-27.
//
//  ---------------------------------------------------------------------------
//
//  © 2019 1024jp
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

import Foundation
import AppKit.NSLayoutManager

protocol ValidationIgnorable: NSLayoutManager {
    
    var ignoresDisplayValidation: Bool { get set }
}


extension ValidationIgnorable {
    
    ///  Perform batch task updating temporary attributes performance efficiently by disabling display validation between each process.
    ///
    /// - Parameter range: The overall range in which temporary attributes are updated.
    /// - Parameter work: The work to do while the display validation is disabled.
    ///
    /// - Note:
    ///     According to the implementation of `NSLayoutManager` in GNUstep,
    ///     `invalidateDisplayForCharacterRange:` is invoked every time inside of `addTemporaryAttribute:value:forCharacterRange:`.
    ///     Ignoring that process during updating attributes reduces the application time,
    ///     which shows the rainbow cursor because of a main thread task, significantly.
    ///     See `LayoutManager.invalidateDisplay(forCharacterRange:)` for the LayoutManager-side implementation.
    ///     (2018-12 macOS 10.14)
    func groupTemporaryAttributesUpdate(in range: NSRange, work: () -> Void) {

        self.ignoresDisplayValidation = true
        
        work()
        
        self.ignoresDisplayValidation = false
        self.invalidateDisplay(forCharacterRange: range)
    }
    
}
