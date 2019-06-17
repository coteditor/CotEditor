//
//  Atomic.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-12-19.
//
//  ---------------------------------------------------------------------------
//
//  © 2018 1024jp
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

final class Atomic<T> {
    
    // MARK: Private Properties
    
    private let queue: DispatchQueue
    private var _value: T
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    init(_ value: T, attributes: DispatchQueue.Attributes = []) {
        
        self.queue = DispatchQueue(label: "com.coteditor.CotEdiotor.atomic." + String(describing: T.self), attributes: attributes)
        self._value = value
    }
    
    
    
    // MARK: Public Methods
    
    /// thread-safe getter for value
    var value: T {
        
        return self.queue.sync { self._value }
    }
    
    
    /// thread-safe update of value
    func mutate(_ transform: (inout T) -> Void) {
        
        self.queue.sync {
            transform(&self._value)
        }
    }
    
    
    /// thread-safe update of value without blocking the current thread
    func asyncMutate(_ transform: @escaping (inout T) -> Void) {
        
        self.queue.async(flags: .barrier) { [unowned self] in
            transform(&self._value)
        }
    }
    
}
