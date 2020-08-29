//
//  DefaultKey+Observation.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-12-25.
//
//  ---------------------------------------------------------------------------
//
//  © 2018-2020 1024jp
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

extension UserDefaults {
    
    /// Register the observer object to observe UserDefaults value change.
    ///
    /// You don't need to invalidate the observer in its `deinit` method.
    ///
    /// - Parameters:
    ///   - key: The typed UserDefaults key to obseve the change of its value.
    ///   - queue: The operation queue where to perform the `changeHandler`.
    ///   - initial: If `true`, changeHandler performs immediately, before the observer registration method even returns.
    ///   - changeHandler: The block to be executed when the observerd the observed deafault is updated.
    ///   - value: The new value.
    /// - Returns: An observer object.
    func observe<Value>(key: DefaultKey<Value>, queue: OperationQueue? = .main, initial: Bool = false, changeHandler: @escaping (_ value: Value?) -> Void) -> UserDefaultsObservation {
        
        return UserDefaultsObservation(object: self, key: key.rawValue, queue: queue, initial: initial) { (value) in
            changeHandler(value as? Value)
        }
    }
    
}



final class UserDefaultsObservation: NSObject {
    
    // MARK: Private Properties
    
    private let object: UserDefaults
    private let key: String
    private let queue: OperationQueue?
    private let changeHandler: (Any?) -> Void
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    fileprivate init(object: UserDefaults, key: String, queue: OperationQueue?, initial: Bool = false, changeHandler: @escaping (Any?) -> Void) {
        
        self.object = object
        self.key = key
        self.queue = queue
        self.changeHandler = changeHandler
        
        super.init()
        
        object.addObserver(self, forKeyPath: key, options: initial ? [.initial, .new] : .new, context: nil)
    }
    
    
    deinit {
        self.object.removeObserver(self, forKeyPath: self.key, context: nil)
    }
    
    
    
    // MARK: KVO
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        
        guard
            keyPath == self.key,
            let change = change,
            object as? NSObject == self.object
            else { return }
        
        let new = change[.newKey]
        
        if let queue = self.queue, queue != OperationQueue.current {
            queue.addOperation { [weak self] in
                self?.changeHandler(new)
            }
        } else {
            self.changeHandler(new)
        }
    }
    
}
