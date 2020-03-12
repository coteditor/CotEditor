//
//  FourCharCode.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-07-19.
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

import typealias Darwin.FourCharCode

extension FourCharCode {
    
    init(code string: String) {
        
        assert(string.utf16.count == 4, "FourCharCode must be made from 4 ASCII characters.")
        assert(string.utf16.allSatisfy { $0 <= 0xFF }, "FourCharCode must contain only ASCII characters.")
        
        self = string.utf16.reduce(0) { (code, character) in (code << 8) + FourCharCode(character) }
    }
    
}
