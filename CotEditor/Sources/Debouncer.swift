//
//  Debouncer.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2017-02-09.
//
//  ---------------------------------------------------------------------------
//
//  © 2017-2020 1024jp
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

extension DispatchTimeInterval {
    
    static func seconds(_ interval: Double) -> DispatchTimeInterval {
        
        .milliseconds(Int(interval * 1000))
    }
}


/// Object invoking the registered block when a specific time interval is passed after the last call.
final class Debouncer {
    
    // MARK: Private Properties
    
    private let action: () -> Void
    private let queue: DispatchQueue
    private let defaultDelay: DispatchTimeInterval
    
    private var currentWorkItem: DispatchWorkItem?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    /// Returns a new `Debouncer` initialized with given values.
    ///
    /// - Parameters:
    ///   - delay: The default time to wait since last call.
    ///   - queue: The dispatch queue to perform action.
    ///   - action: The action to debounce.
    init(delay: DispatchTimeInterval = .seconds(0), queue: DispatchQueue = .main, action: @escaping () -> Void) {
        
        self.action = action
        self.queue = queue
        self.defaultDelay = delay
    }
    
    
    deinit {
        self.cancel()
    }
    
    
    
    // MARK: Public Methods
    
    /// Invoke the action after when `delay` time have passed since last call.
    ///
    /// - Parameters:
    ///   - delay: The time to wait for fire. If nil, receiver's default delay is used.
    func schedule(delay: DispatchTimeInterval? = nil) {
        
        let delay = delay ?? self.defaultDelay
        let workItem = DispatchWorkItem { [weak self] in
            self?.action()
            self?.currentWorkItem = nil
        }
        
        self.cancel()
        self.currentWorkItem = workItem
        
        self.queue.asyncAfter(deadline: .now() + delay, execute: workItem)
    }
    
    
    /// Perform the action immediately.
    func perform() {
        
        self.currentWorkItem?.cancel()
        self.queue.async(execute: self.action)
    }
    
    
    /// Perform the action immediately if scheduled.
    func fireNow() {
        
        self.currentWorkItem?.perform()
    }
    
    
    /// Cancel the action if scheduled.
    func cancel() {
        
        self.currentWorkItem?.cancel()
        self.currentWorkItem = nil
    }
}
