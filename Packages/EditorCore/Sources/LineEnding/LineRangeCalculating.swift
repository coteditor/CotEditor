//
//  LineRangeCalculating.swift
//  LineEnding
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-07-13.
//
//  ---------------------------------------------------------------------------
//
//  © 2024 1024jp
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
import ValueRange

public protocol LineRangeCalculating {
    
    /// The text contents.
    var string: NSString { get }
    
    /// Line Endings sorted by location.
    var lineEndings: [ValueRange<LineEnding>] { get }
}


public extension LineRangeCalculating {
    
    /// Returns the 1-based line number at the given character index.
    ///
    /// - Parameter characterIndex: The character index.
    /// - Returns: The 1-based line number.
    func lineNumber(at characterIndex: Int) -> Int {
        
        if let index = self.lineEndings.binarySearchedFirstIndex(where: { $0.upperBound > characterIndex }) {
            index + 1
        } else if let last = self.lineEndings.last, last.upperBound <= characterIndex {
            self.lineEndings.endIndex + 1
        } else {
            1
        }
    }
}
