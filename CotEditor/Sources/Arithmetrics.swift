//
//  Arithmetrics.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2021-09-23.
//
//  ---------------------------------------------------------------------------
//
//  © 2021-2022 1024jp
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

extension Int {
    
    /// Array of digits from the ones place.
    var digits: [Int] {
        
        assert(self >= 0)
        
        if self == 0 { return [0] }
        
        var number = self
        var digits: [Int] = []
        
        while number > 0 {
            digits.append(number % 10)
            number /= 10
        }
        
        return digits
    }
}
