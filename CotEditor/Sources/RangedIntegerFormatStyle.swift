//
//  RangedIntegerFormatStyle.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2022-12-18.
//
//  ---------------------------------------------------------------------------
//
//  © 2022 1024jp
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

struct RangedIntegerFormatStyle: ParseableFormatStyle {
    
    var range: ClosedRange<Int>
    var defaultValue: Int?
    
    
    var parseStrategy: RangedIntegerParseStrategy {
        
        RangedIntegerParseStrategy(style: self)
    }
    
    
    func format(_ value: Int) -> String {
        
        String(value.clamped(to: self.range))
    }
}


struct RangedIntegerParseStrategy: ParseStrategy {
    
    let style: RangedIntegerFormatStyle
    
    
    func parse(_ value: String) throws -> Int {
        
        guard let number = Int(value) else {
            return self.style.defaultValue ?? 0.clamped(to: self.style.range)
        }
        
        return number.clamped(to: self.style.range)
    }
}


extension FormatStyle where Self == RangedIntegerFormatStyle {
    
    /// Clamp the value in between the given range.
    ///
    /// - Parameters:
    ///   - range: The condition which the value should be in between.
    ///   - defaultValue: The value used when the input value is invalid.
    /// - Returns: A RangedIntegerFormatStyle.
    static func ranged(_ range: ClosedRange<Int>, defaultValue: Int? = nil) -> RangedIntegerFormatStyle {
        
        assert(defaultValue == nil || range.contains(defaultValue!))
        
        return RangedIntegerFormatStyle(range: range, defaultValue: defaultValue)
    }
}
