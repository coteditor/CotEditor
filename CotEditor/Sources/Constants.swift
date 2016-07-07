/*
 
 Constants.swift
 
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

import AudioToolbox

// labels for system sound ID on AudioToolbox (There are no constants provided by Apple)
extension SystemSoundID {
    static let moveToTrash = SystemSoundID(0x10)
}


extension String {
    /// constant string representing a separator
    static let separator = "-"
    
    /// whole range in NSRange
    var nsRange: NSRange {
        return NSRange(location: 0, length: self.utf16.count)
    }
}

let NotFoundRange = NSRange(location: NSNotFound, length: 0)


/**
 Modify number to be within max/min values.
 
 - Parameters:
    - minimum: Condition which passed-in value should not smaller than.
    - value  : Value to modify.
    - maximum: Condition which passed-in value should not larger than.
 
 - returns: Processed value.
 */ 
func within<T: Comparable>(_ minimum: T, _ value: T, _ maximum: T) -> T {
    return max(minimum, min(value, maximum))
}

/// print a dog for debug.
func Baw() {
    print("🐕")
}
