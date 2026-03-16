//
//  FindProgress.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2022-12-11.
//
//  ---------------------------------------------------------------------------
//
//  © 2022-2026 1024jp
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

public import Observation
import Foundation
import Synchronization

@Observable public final class FindProgress: Sendable {
    
    public enum State: Equatable, Sendable {
        
        case ready
        case processing
        case finished
        case cancelled
        
        
        /// Whether the progress is terminated.
        public var isTerminated: Bool {
            
            switch self {
                case .ready, .processing: false
                case .finished, .cancelled: true
            }
        }
    }
    
    
    // MARK: Private Properties
    
    private let _state: Mutex<State> = .init(.ready)
    private let _count: Mutex<Int> = .init(0)
    private let completedUnit: Mutex<Int> = .init(0)
    private let scope: Range<Int>
    
    
    // MARK: Lifecycle
    
    /// Instantiates a progress.
    ///
    /// - Parameter scope: The range of progress unit to work with.
    public init(scope: Range<Int>) {
        
        self.scope = scope
    }
    
    
    // MARK: Public Methods
    
    /// The current progress state.
    public var state: State {
        
        access(keyPath: \.state)
        return self._state.withLock(\.self)
    }
    
    
    /// The number of items completed.
    public var count: Int  {
        
        self._count.withLock(\.self)
    }
    
    
    /// The fraction of task completed in between 0...1.0.
    public var fractionCompleted: Double {
        
        if self.state == .finished || self.scope.isEmpty {
            1
        } else {
            Double(self.completedUnit.withLock(\.self)) / Double(self.scope.count)
        }
    }
    
    
    /// Changes the state to `.cancelled`.
    public func cancel() {
        
        withMutation(keyPath: \.state) {
            self._state.withLock { $0 = .cancelled }
        }
    }
    
    
    /// Changes the state to `.finished`.
    public func finish() {
        
        withMutation(keyPath: \.state) {
            self._state.withLock { $0 = .finished }
        }
    }
    
    
    /// Increments count.
    ///
    /// - Parameter count: The amount to increment.
    public func incrementCount(by count: Int = 1) {
        
        self._count.withLock { $0 += count }
    }
    
    
    /// Updates the `completedUnit` to a new value.
    ///
    /// - Parameter unit: The new completed unit.
    public func updateCompletedUnit(to unit: Int) {
        
        self.completedUnit.withLock { $0 = unit }
    }
    
    
    // MARK: Internal Methods
    
    /// Increments the `completedUnit` by one.
    func incrementCompletedUnit() {
        
        self.completedUnit.withLock { $0 += 1 }
    }
}
