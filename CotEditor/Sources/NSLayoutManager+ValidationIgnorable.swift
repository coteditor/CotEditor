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
//  © 2019-2023 1024jp
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


extension NSLayoutManager {
    
    /// Perform batch task updating temporary attributes performance efficiently by disabling display validation between each process.
    ///
    /// By using this method, conforming to `ValidationIgnorable` protocol is expected;
    /// otherwise, just run `work` block and no optimization is performed.
    ///
    /// See `LayoutManager.invalidateDisplay(forCharacterRange:)` for the LayoutManager-side implementation.
    /// (2018-12 macOS 10.14)
    ///
    /// - Note:
    ///     According to the implementation of `NSLayoutManager` in GNUstep,
    ///     `invalidateDisplayForCharacterRange:` is invoked every time
    ///     inside of `addTemporaryAttribute:value:forCharacterRange:`.
    ///     Ignoring that process during updating attributes reduces the application time,
    ///     which shows the rainbow cursor because of a main thread task, significantly.
    ///
    ///     Even the temporary attributes are limited to those that do not affect layout,
    ///     invalidating display by a temporary attributes update is yet needed for in case
    ///     that an attribute is applied only to a part of a single glyph.
    ///     Because, in some specific languages, it can cause a change of the glyph shape.
    ///
    /// - Parameter range: The overall range in which temporary attributes are updated.
    /// - Parameter work: The work to do while the display validation is disabled..
    func groupTemporaryAttributesUpdate(in range: NSRange, work: () throws -> Void) rethrows {
        
        guard let self = self as? any ValidationIgnorable else {
            assertionFailure("Conforming to ValidationIgnorable protocol is expected when using groupTemporaryAttributesUpdate(in:work:).")
            return try work()
        }
        
        self.ignoresDisplayValidation = true
        defer {
            self.ignoresDisplayValidation = false
            self.invalidateDisplay(forCharacterRange: range)
        }
        
        try work()
    }
}
