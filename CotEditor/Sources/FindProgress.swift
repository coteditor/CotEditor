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
//  © 2022-2023 1024jp
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

final class FindProgress: ObservableObject {
    
    private(set) var count = 0
    var completedUnit = 0
    
    @Published private(set) var isCancelled = false
    @Published private(set) var isFinished = false
    
    private let scope: Range<Int>
    
    
    /// Instantiates a progress.
    ///
    /// - Parameter scope: The range of progress unit to work with.
    init(scope: Range<Int>) {
        
        self.scope = scope
    }
    
    
    /// The fraction of task completed in between 0...1.0.
    var fractionCompleted: Double {
        
        if self.isFinished || self.scope.isEmpty {
            return 1
        } else {
            return Double(self.completedUnit) / Double(self.scope.count)
        }
    }
    
    
    /// Increments count.
    ///
    /// - Parameter count: The amount to increment.
    func increment(by count: Int = 1) {
        
        self.count += count
    }
    
    
    /// Raise `isCancelled` flag.
    func cancel() {
        
        self.isCancelled = true
    }
    
    
    /// Raise `isFinished` flag.
    func finish() {
        
        self.isFinished = true
    }
}
