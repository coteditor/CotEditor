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

/// Object invoking the registered block when a specific time interval is passed after the last call.
@MainActor final class Debouncer {
    
    // MARK: Private Properties
    
    private let action: @MainActor @Sendable () -> Void
    private let defaultDelay: ContinuousClock.Duration
    
    private var task: Task<Void, any Error>?
    
    
    // MARK: Lifecycle
    
    /// Returns a new `Debouncer` initialized with given values.
    ///
    /// - Parameters:
    ///   - delay: The default time to wait since last call.
    ///   - action: The action to debounce.
    init(delay: ContinuousClock.Duration = .seconds(0), action: @MainActor @Sendable @escaping () -> Void) {
        
        self.action = action
        self.defaultDelay = delay
    }
    
    
    // MARK: Public Methods
    
    /// Invokes the action after when `delay` time have passed since last call.
    ///
    /// - Parameters:
    ///   - delay: The time to wait for fire. If nil, receiver's default delay is used.
    func schedule(delay: ContinuousClock.Duration? = nil) {
        
        let delay = delay ?? self.defaultDelay
        
        self.task?.cancel()
        self.task = Task {
            try await Task.sleep(for: delay)
            
            self.action()
            self.task = nil
        }
    }
    
    
    /// Performs the action immediately.
    func perform() {
        
        self.cancel()
        self.action()
    }
    
    
    /// Performs the action immediately if scheduled.
    func fireNow() {
        
        guard self.task != nil else { return }
        
        self.cancel()
        self.action()
    }
    
    
    /// Cancels the action if scheduled.
    func cancel() {
        
        self.task?.cancel()
        self.task = nil
    }
}
