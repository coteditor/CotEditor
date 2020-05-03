//
//  UserDefaults.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-07-10.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2020 1024jp
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

import struct CoreGraphics.CGFloat
import class Foundation.UserDefaults

extension UserDefaults {
    
    /// Returns the CGFloat value associated with the specified key.
    ///
    /// - Parameter key: A key in the current user's defaults database.
    /// - Returns: The CGFloat value associated with the specified key. If the key does not exist, this method returns 0.
    func cgFloat(forKey key: String) -> CGFloat {
        
        return CGFloat(self.double(forKey: key))
    }
    
}
