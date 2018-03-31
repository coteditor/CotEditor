/*
 
 MoreThanOneTransformer.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2017-03-18.
 
 ------------------------------------------------------------------------------
 
 © 2017 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 https://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Foundation

final class MoreThanOneTransformer: ValueTransformer {
    
    // MARK: Public Properties
    
    static let name = NSValueTransformerName("MoreThanOneTransformer")
    
    
    
    // MARK: -
    // MARK: Value Transformer Methods
    
    /// Class of transformed value
    override class func transformedValueClass() -> AnyClass {
        
        return NSNumber.self
    }
    
    
    /// Can reverse transformeation?
    override class func allowsReverseTransformation() -> Bool {
        
        return false
    }
    
    
    /// From color code hex to NSColor (NSNumber -> Bool)
    override func transformedValue(_ value: Any?) -> Any? {
        
        guard let count = value as? Int else { return false }
        
        return count > 1
    }
    
}
