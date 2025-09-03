//
//  BoolComparator.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2025-09-03.
//
//  ---------------------------------------------------------------------------
//
//  © 2025 1024jp
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

struct BoolComparator: SortComparator {
    
    var order: SortOrder = .forward
    
    
    func compare(_ lhs: Bool, _ rhs: Bool) -> ComparisonResult {
        
        switch self.order {
            case .forward: self.result(lhs, rhs)
            case .reverse: self.result(rhs, lhs)
        }
    }
    
    
    private func result(_ lhs: Bool, _ rhs: Bool) -> ComparisonResult {
        
        switch (lhs, rhs) {
            case (true, false): .orderedAscending
            case (false, true): .orderedDescending
            case (true, true), (false, false): .orderedSame
        }
    }
}
