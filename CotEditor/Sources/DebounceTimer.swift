/*
 
 DebounceTimer.swift
 
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

final class DebounceTimer {
    
    // MARK: Private Properties
    
    private let delay: TimeInterval
    private let tolerance: Double
    private weak var timer: Timer?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    /// Returns a new `DebounceTimer` initialized with given values.
    ///
    /// - Parameters:
    ///   - delay: The default time to wait since last emission.
    ///   - tolerance: The rate of the timer tolerance to the delay interval.
    init(delay: TimeInterval, tolerance: Double = 0.1) {
        
        self.delay = delay
        self.tolerance = tolerance
    }
    
    
    deinit {
        self.timer?.invalidate()
    }
    
    
    
    // MARK: Public Methods
    
    /// Perform the action after when `delay` seconds have passed since the last emission.
    ///
    /// - Parameters:
    ///   - delay: The time to wait since last emission. If nil, the default delay is used.
    ///   - action: The action to perform after the delay.
    func schedule(after delay: TimeInterval? = nil, action: @escaping () -> Void) {
        
        let delay = delay ?? self.delay
        
        guard delay > 0 else {
            self.timer?.invalidate()
            action()
            return
        }
        
        if let timer = self.timer {
            timer.fireDate = Date(timeIntervalSinceNow: delay)
        } else {
            self.timer = Timer.scheduledTimer(timeInterval: delay,
                                              target: self, selector: #selector(fire),
                                              userInfo: action, repeats: false)
        }
        self.timer?.tolerance = self.tolerance * delay
    }
    
    
    /// Cancel action if scheduled.
    func cancel() {
        
        self.timer?.invalidate()
    }
    
    
    /// Run action immediatly if one scheduled.
    func run() {
        
        guard let timer = self.timer else { return }
        
        self.fire(timer)
    }
    
    
    
    // MARK: Private Methods
    
    @objc private func fire(_ timer: Timer) {
        
        defer {
            self.timer?.invalidate()
        }
        
        guard
            timer.isValid,
            let action = timer.userInfo as? (() -> Void)
            else { return }
        
        action()
    }
    
}
