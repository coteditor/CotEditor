//
//  Debug.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2017-01-18.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2022 1024jp
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

/// Debug friendly print with a dog/cow.
///
///  This function works just like `Swift.debugPrint()` function.
///  The advantage is you can know the thread and the function name that invoked this function easily at the same time.
///  A 🐄 icon will be printed at the beginning of the message if it's invoked in a background thead, otherwise a 🐕.
///
/// - Parameters:
///   - items: Zero or more items to print.
///   - function: The name of the function that invoked this function. You never need to set this parameter manually because it's set automatically.
func moof(_ items: Any..., function: String = #function) {
    
    let icon = Thread.isMainThread ? "🐕" : "🐄"
    let prefix = icon + " " + function
    
    if items.isEmpty {
        Swift.print(prefix)
    } else {
        Swift.print(prefix, terminator: " ")
        Swift.debugPrint(items)
    }
}
