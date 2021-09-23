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
//  © 2021 1024jp
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

import Darwin

extension Int {
    
    /// number of digits
    var numberOfDigits: Int {
        
        guard self > 0 else { return 1 }
        
        return Int(log10(Double(self))) + 1
    }
    
    
    /// number at the desired place
    func number(at place: Int) -> Int {
        
        return (self % Int(pow(10, Double(place + 1)))) / Int(pow(10, Double(place)))
    }
    
}


extension FloatingPoint {
    
    func rounded(interval: Self) -> Self {
        
        return (self / interval).rounded() * interval
    }
}


extension Double {
    
    /// round to decimal places value
    func rounded(to places: Int) -> Double {
        
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
    
}
