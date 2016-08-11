/*
 
 Utilities.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-06-25.
 
 ------------------------------------------------------------------------------
 
 © 2016 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Foundation

extension Comparable {
    
    /**
     Modify number to be within min/max values.
     
     - parameter minimum: Condition which receiver should not smaller than.
     - parameter minimum: Condition which receiver should not larger than.
     
     - returns: Processed value.
     */
    func within(min minimum: Self, max maximum: Self) -> Self {
        
        return max(minimum, min(self, maximum))
    }
}



/// debug friendly print with a dog.
func moof(_ items: Any..., function: String = #function) {
    
    #if DEBUG
        Swift.print("🐕 \(function): ", terminator: "")
        Swift.debugPrint(items)
    #endif
}
