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
//  © 2018-2022 1024jp
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

import class Dispatch.DispatchQueue

@propertyWrapper
final class Atomic<T> {
    
    // MARK: Public Properties
    
    var projectedValue: Atomic<T>  { self }
    
    
    // MARK: Private Properties
    
    private let queue = DispatchQueue(label: "com.coteditor.CotEdiotor.atomic." + String(describing: T.self))
    private var value: T
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    /// Initializer for proeprtyWrapper.
    init(wrappedValue: T) {
        
        self.value = wrappedValue
    }
    
    
    
    // MARK: Public Methods
    
    /// Thread-safe accessor for value.
    var wrappedValue: T {
        
        get { self.queue.sync { self.value } }
        set { self.queue.sync { self.value = newValue } }
    }
    
    
    /// Thread-safe update of value.
    func mutate(_ transform: (inout T) -> Void) {
        
        self.queue.sync {
            transform(&self.value)
        }
    }
}
