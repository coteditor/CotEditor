/*
 
 AsynchronousOperation.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-10-09.
 
 ------------------------------------------------------------------------------
 
 © 2016-2018 1024jp
 
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

class AsynchronousOperation: Operation {
    
    // MARK: Private Properties
    
    private var isOperationStarted = false
    
    
    private var _executing: Bool = false {
        
        willSet {
            self.willChangeValue(forKey: #keyPath(isExecuting))
        }
        didSet {
            self.didChangeValue(forKey: #keyPath(isExecuting))
        }
    }
    
    
    private var _finished: Bool = false {
        
        willSet {
            self.willChangeValue(forKey: #keyPath(isFinished))
        }
        didSet {
            self.didChangeValue(forKey: #keyPath(isFinished))
        }
    }
    
    
    
    // MARK: -
    // MARK: Operation Methods
    
    final override var isAsynchronous: Bool {
        
        return true
    }
    
    
    final override var isExecuting: Bool {
        
        return _executing
    }
    
    
    final override var isFinished: Bool {
        
        return _finished
    }
    
    
    final override func start() {
        
        self.isOperationStarted = true
        
        if self.isCancelled {
            _finished = true
            return
        }
        
        _executing = true
        
        self.main()
    }
    
    
    
    // MARK: Public Methods
    
    /// invoke this method when operation finished no matter if the operation succeeded or not
    final func finish() {
        
        guard self.isOperationStarted else { return }
        
        _executing = false
        _finished = true
    }
    
}
