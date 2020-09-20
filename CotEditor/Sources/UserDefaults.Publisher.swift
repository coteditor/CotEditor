//
//  UserDefaults.Publisher.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2020-08-29.
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


import Combine
import Foundation

extension UserDefaults {
    
    /// Publish values when the value identified by a default key changes.
    ///
    /// - Parameters:
    ///   - key: The default key of the default value to publish.
    ///   - initial: If `true`, the first output will be send immediately, before the observer registration method even returns.
    /// - Returns: A publisher that emits elements each time the defaults’ value changes.
    func publisher<Value>(for key: DefaultKey<Value>, initial: Bool = false) -> Publisher<Value> {
        
        return Publisher(userDefaults: self, key: key, initial: initial)
    }
    
    
    
    struct Publisher<Value>: Combine.Publisher {
        
        typealias Output = Value
        typealias Failure = Never
        
        
        // MARK: Public Properties
        
        let userDefaults: UserDefaults
        let key: DefaultKey<Value>
        let initial: Bool
        
        
        
        // MARK: Publisher Methods
        
        func receive<S>(subscriber: S) where S: Combine.Subscriber, Failure == S.Failure, Output == S.Input {
            
            let subscription = Subscription(subscriber: subscriber, userDefaults: self.userDefaults, key: self.key)
            
            subscriber.receive(subscription: subscription)
            subscription.register(initial: self.initial)  // regsiter after assigning to subscriber to pass the initial emission
        }
        
    }
    
}



// MARK: -

private extension UserDefaults.Publisher {
    
    final class Subscription<Value, S: Subscriber>: NSObject, Combine.Subscription where S.Input == Value {
        
        // MARK: Private Properties
        
        private var subscriber: S?
        private var userDefaults: UserDefaults?
        private let key: DefaultKey<Value>
        private var demand: Subscribers.Demand = .none
        
        
        
        // MARK: Lifecycle
        
        init(subscriber: S, userDefaults: UserDefaults, key: DefaultKey<Value>) {
            
            self.subscriber = subscriber
            self.userDefaults = userDefaults
            self.key = key
        }
        
        
        deinit {
            self.cancel()
        }
        
        
        
        // MARK: Subscription Methods
        
        func request(_ demand: Subscribers.Demand) {
            
            self.demand += demand
        }
        
        
        func cancel() {
            
            self.userDefaults?.removeObserver(self, forKeyPath: self.key.rawValue)
            self.userDefaults = nil
            self.subscriber = nil
        }
        
        
        
        // MARK: KVO
        
        func register(initial: Bool) {
            
            self.userDefaults?.addObserver(self, forKeyPath: key.rawValue, options: initial ? [.new, .initial] : [.new], context: nil)
        }
        
        
        override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
            
            guard
                keyPath == self.key.rawValue,
                object as? NSObject == self.userDefaults
                else { return super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context) }
            
            guard
                self.demand > 0,
                let subscriber = self.subscriber
                else { return }
            
            let newValue: Value
            do {
                newValue = try self.key.newValue(from: change?[.newKey])
            } catch {
                return assertionFailure("UserDefaults.Publisher.Subscription could not obtain value for '.\(self.key)' key as \(Value.self).")
            }
            
            self.demand -= 1
            self.demand += subscriber.receive(newValue)
        }
        
    }
    
}
