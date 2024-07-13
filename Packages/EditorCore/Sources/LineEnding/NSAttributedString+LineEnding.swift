//
//  NSAttributedString+LineEnding.swift
//  LineEnding
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-07-13.
//
//  ---------------------------------------------------------------------------
//
//  © 2014-2024 1024jp
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

public extension NSMutableAttributedString {
    
    /// Replaces all line endings in the receiver with given line endings.
    ///
    /// - Parameters:
    ///     - lineEnding: The line ending type with which to replace the target.
    final func replaceLineEndings(with lineEnding: LineEnding) {
        
        // -> Intentionally avoid replacing characters in the mutableString directly,
        //    because it pots a quantity of small edited notifications,
        //    which costs high. (2023-11, macOS 14)
        self.replaceCharacters(in: NSRange(..<self.length), with: self.string.replacingLineEndings(with: lineEnding))
    }
}
