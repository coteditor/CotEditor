//
//  NSRange.swift
//  EditedRangeSet
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-07-10.
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
import StringUtils

extension Sequence<NSRange> {
    
    /// The range that contains all ranges.
    var union: NSRange? {
        
        let ranges = self.filter { !$0.isNotFound }
        
        guard
            let lowerBound = ranges.map(\.lowerBound).min(),
            let upperBound = ranges.map(\.upperBound).max()
        else { return nil }
        
        return NSRange(lowerBound..<upperBound)
    }
}
