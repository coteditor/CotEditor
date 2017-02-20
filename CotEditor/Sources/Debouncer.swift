/*
 
 Debouncer.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2017-02-09.
 
 ------------------------------------------------------------------------------
 
 © 2017 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 https://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Foundation

/// Object invoking the registered block when a specific time interval is passed after the last call.
final class Debouncer {
    
    // MARK: Private Properties
    
    private let action: () -> Void
    private let delay: TimeInterval
    private let tolerance: Double
    private weak var timer: Timer?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    /// Returns a new `Debouncer` initialized with given values.
    ///
    /// - Parameters:
    ///   - delay: The default time to wait since last call.
    ///   - tolerance: The rate of the timer tolerance to the delay interval.
    ///   - action: The action to debounce.
    init(delay: TimeInterval = 0, tolerance: Double = 0.2, action: @escaping () -> Void) {
        
        self.action = action
        self.delay = delay
        self.tolerance = tolerance
    }
    
    
    deinit {
        self.timer?.invalidate()
    }
    
    
    
    // MARK: Public Methods
    
    /// Invoke the action after when `delay` seconds have passed since last call.
    ///
    /// - Parameters:
    ///   - delay: The time to wait since last call. If nil, receiver's default delay is used.
    func schedule(delay: TimeInterval? = nil) {
        
        let delay = delay ?? self.delay
        
        guard delay > 0 else {
            return self.run()
        }
        
        if let timer = self.timer {
            timer.fireDate = Date(timeIntervalSinceNow: delay)
        } else {
            self.timer = Timer.scheduledTimer(timeInterval: delay,
                                              target: self, selector: #selector(run),
                                              userInfo: nil, repeats: false)
        }
        self.timer?.tolerance = self.tolerance * delay
    }
    
    
    /// Run the action immediately.
    @objc func run() {
        
        self.timer?.invalidate()
        self.action()
    }
    
    
    /// Cancel the action if scheduled.
    func cancel() {
        
        self.timer?.invalidate()
    }
    
}
