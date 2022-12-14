//
//  Comparable.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-06-25.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2022 1024jp
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

extension Comparable {
    
    /// Return clamped value to min/max values.
    ///
    /// - Parameter range: Condition which receiver should be in between.
    /// - Returns: Processed value.
    func clamped(to range: ClosedRange<Self>) -> Self {
        
        max(range.lowerBound, min(self, range.upperBound))
    }
    
    
    /// Clamp self to min/max values.
    ///
    /// - Parameter range: Condition which receiver should be in between.
    mutating func clamp(to range: ClosedRange<Self>) {
        
        self = self.clamped(to: range)
    }
}
