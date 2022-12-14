//
//  DispatchQueue.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-07-27.
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

import Dispatch
import class Foundation.Thread

extension DispatchQueue {
    
    /// synchronously but thread-safely invoke passed-in block on main thread avoiding deadlock
    final class func syncOnMain(execute block: () -> Void) {
        
        if Thread.isMainThread {
            block()
            
        } else {
            DispatchQueue.main.sync(execute: block)
        }
    }
    
    
    /// synchronously but thread-safely invoke passed-in block on main thread avoiding deadlock
    final class func syncOnMain<T>(execute work: () throws -> T) rethrows -> T {
        
        if Thread.isMainThread {
            return try work()
            
        } else {
            return try DispatchQueue.main.sync(execute: work)
        }
    }
}
