//
//  Data.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2017-10-29.
//
//  ---------------------------------------------------------------------------
//
//  © 2017-2018 1024jp
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

extension Data {
    
    /// Split receiver into buffer sized chunks
    ///
    /// - Parameter length: The buffer size to split.
    /// - Returns: Split subsequences.
    func components(length: Int) -> [SubSequence] {
        
        return stride(from: 0, to: self.count, by: length).map {
            let start = self.index(self.startIndex, offsetBy: $0)
            let end = self.index(start, offsetBy: length, limitedBy: self.endIndex) ?? self.endIndex
            
            return self[start..<end]
        }
    }
    
}
