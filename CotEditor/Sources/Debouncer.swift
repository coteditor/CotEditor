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
//  © 2017-2024 1024jp
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
    private let defaultDelay: DispatchTimeInterval
    
    private var currentWorkItem: DispatchWorkItem?
    
    
    
    // MARK: Lifecycle
    
    /// Returns a new `Debouncer` initialized with given values.
    ///
    /// - Parameters:
    ///   - delay: The default time to wait since last call.
    ///   - action: The action to debounce.
    init(delay: DispatchTimeInterval = .seconds(0), action: @escaping () -> Void) {
        
        self.action = action
        self.defaultDelay = delay
    }
    
    
    deinit {
        self.cancel()
    }
    
    
    
    // MARK: Public Methods
    
    /// Invokes the action after when `delay` time have passed since last call.
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }
    
    
    /// Performs the action immediately.
    func perform() {
        
        self.currentWorkItem?.cancel()
        DispatchQueue.main.async(execute: self.action)
    }
    
    
    /// Performs the action immediately if scheduled.
    func fireNow() {
        
        self.currentWorkItem?.perform()
    }
    
    
    /// Cancels the action if scheduled.
    func cancel() {
        
        self.currentWorkItem?.cancel()
        self.currentWorkItem = nil
    }
}
