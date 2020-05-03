//
//  AsynchronousOperation.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2020-02-16.
//
//  ---------------------------------------------------------------------------
//
//  © 2020 1024jp
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

import class Foundation.Operation

class AsynchronousOperation: Operation {
    
    private enum State {
        
        case ready
        case executing
        case finished
        
        
        var keyPath: KeyPath<AsynchronousOperation, Bool> {
            
            switch self {
                case .ready: return \.isReady
                case .executing: return \.isExecuting
                case .finished: return \.isFinished
            }
        }
        
    }
    
    
    
    // MARK: Private Properties
    
    private var state: State {
        
        get {
            return self._state.value
        }
        
        set {
            let oldValue = self._state.value
            
            self.willChangeValue(for: oldValue.keyPath)
            self.willChangeValue(for: newValue.keyPath)
            self._state.mutate { $0 = newValue }
            self.didChangeValue(for: oldValue.keyPath)
            self.didChangeValue(for: newValue.keyPath)
        }
    }
    private var _state = Atomic<State>(.ready)
    
    
    
    // MARK: -
    // MARK: Operation Methods
    
    final override var isAsynchronous: Bool {
        
        return true
    }
    
    
    final override var isReady: Bool {
        
        return self.state == .ready && super.isReady
    }
    
    
    final override var isExecuting: Bool {
        
        return self.state == .executing
    }
    
    
    final override var isFinished: Bool {
        
        return self.state == .finished
    }
    
    
    final override func start() {
        
        precondition(self.state == .ready)
        
        guard !self.isCancelled else { return }
        
        self.state = .executing
        
        self.main()
    }
    
    
    
    // MARK: Public Methods
    
    /// Raise manually the `.isFinished` flag.
    final func finish() {
        
        self.state = .finished
    }
    
}
