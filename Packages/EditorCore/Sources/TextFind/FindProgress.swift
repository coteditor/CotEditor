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
//  © 2022-2024 1024jp
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

import Foundation
import Observation

@Observable public final class FindProgress: @unchecked Sendable {
    
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
    
    
    public private(set) var state: State = .ready
    @ObservationIgnored public private(set) var count = 0
    
    private let scope: Range<Int>
    private var completedUnit = 0
    
    
    /// Instantiates a progress.
    ///
    /// - Parameter scope: The range of progress unit to work with.
    public init(scope: Range<Int>) {
        
        self.scope = scope
    }
    
    
    /// The fraction of task completed in between 0...1.0.
    public var fractionCompleted: Double {
        
        if self.state == .finished || self.scope.isEmpty {
            return 1
        } else {
            return Double(self.completedUnit) / Double(self.scope.count)
        }
    }
    
    
    /// Changes the state to `.cancelled`.
    public func cancel() {
        
        self.state = .cancelled
    }
    
    
    /// Changes the state to `.finished`.
    public func finish() {
        
        self.state = .finished
    }
    
    
    /// Increments count.
    ///
    /// - Parameter count: The amount to increment.
    public func incrementCount(by count: Int = 1) {
        
        self.count += count
    }
    
    
    /// Updates the `completedUnit` to a new value.
    ///
    /// - Parameter unit: The new completed unit.
    public func updateCompletedUnit(to unit: Int) {
        
        self.completedUnit = unit
    }
    
    
    /// Increments the `completedUnit` by one.
    func incrementCompletedUnit() {
        
        self.completedUnit += 1
    }
}
