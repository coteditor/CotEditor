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
//  © 2016-2024 1024jp
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
    
    /// Synchronously but thread-safely invokes passed-in block on main thread to avoid deadlock.
    ///
    /// - Parameter work: The work item containing the work to perform.
    /// - Returns: The return value of the item in the work parameter.
    static func syncOnMain<T: Sendable>(execute work: @MainActor @Sendable () throws -> T) rethrows -> T {
        
        if Thread.isMainThread {
            try MainActor.assumeIsolated {
                try work()
            }
        } else {
            try DispatchQueue.main.sync {
                try MainActor.assumeIsolated {
                    try work()
                }
            }
        }
    }
}
