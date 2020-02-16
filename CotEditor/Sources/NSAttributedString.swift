//
//  NSAttributedString.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-07-20.
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

import Foundation

extension NSAttributedString {
    
    /// whole range
    var range: NSRange {
        
        return NSRange(location: 0, length: self.length)
    }
    
    
    /// concatenate attributed strings
    static func + (lhs: NSAttributedString, rhs: NSAttributedString) -> NSAttributedString {
        
        let result = NSMutableAttributedString()
        result.append(lhs)
        result.append(rhs)
        
        return result.copy() as! NSAttributedString
    }
    
    
    /// concatenate attributed strings
    static func += (lhs: inout NSAttributedString, rhs: NSAttributedString) {
        
        let result = NSMutableAttributedString()
        result.append(lhs)
        result.append(rhs)
        
        lhs = result.copy() as! NSAttributedString
    }
    
}
