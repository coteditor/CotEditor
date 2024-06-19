//
//  AppStorage+DefaultKey.swift
//  Defaults
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2022-12-16.
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

import SwiftUI

public extension AppStorage {
    
    /// Creates a property that can read and write to a boolean user default.
    ///
    /// This initializer enables creating an AppStorage property from a DefaultKey with the registered default value.
    ///
    ///     @AppStorage(.foo) var foo: Bool
    ///
    /// - Parameters:
    ///   - key: The DefaultKey to read and write the value to in the user defaults store.
    ///   - store: The user defaults store to read and write to. A value of `nil` will use the user default store from the environment.
    init(_ key: DefaultKey<Value>, store: UserDefaults? = nil) where Value == Bool {
        
        let defaultValue = (store ?? UserDefaults.standard)[initial: key]
        
        self.init(wrappedValue: defaultValue, key.rawValue, store: store)
    }
    
    
    /// Creates a property that can read and write to an integer user default.
    ///
    /// This initializer enables creating an AppStorage property from a DefaultKey with the registered default value.
    ///
    ///     @AppStorage(.foo) var foo: Int
    ///
    /// - Parameters:
    ///   - key: The DefaultKey to read and write the value to in the user defaults store.
    ///   - store: The user defaults store to read and write to. A value of `nil` will use the user default store from the environment.
    init(_ key: DefaultKey<Value>, store: UserDefaults? = nil) where Value == Int {
        
        let defaultValue = (store ?? UserDefaults.standard)[initial: key]
        
        self.init(wrappedValue: defaultValue, key.rawValue, store: store)
    }
    
    
    init(_ key: DefaultKey<Value>, store: UserDefaults? = nil) where Value == Double {
        
        let defaultValue = (store ?? UserDefaults.standard)[initial: key]
        
        self.init(wrappedValue: defaultValue, key.rawValue, store: store)
    }
    
    
    init(_ key: DefaultKey<Value>, store: UserDefaults? = nil) where Value == Double? {
        
        self.init(key.rawValue, store: store)
    }
    
    
    init(_ key: DefaultKey<Value>, store: UserDefaults? = nil) where Value == String {
        
        let defaultValue = (store ?? UserDefaults.standard)[initial: key]
        
        self.init(wrappedValue: defaultValue, key.rawValue, store: store)
    }
    
    
    init(_ key: DefaultKey<Value>, store: UserDefaults? = nil) where Value: RawRepresentable, Value.RawValue == Int {
        
        let defaultValue = (store ?? UserDefaults.standard)[initial: key]
        
        self.init(wrappedValue: defaultValue, key.rawValue, store: store)
    }
    
    
    init(_ key: RawRepresentableDefaultKey<Value>, store: UserDefaults? = nil) where Value: RawRepresentable, Value: DefaultInitializable, Value.RawValue == String {
        
        let defaultValue = (store ?? UserDefaults.standard)[initial: key] ?? .defaultValue
        
        self.init(wrappedValue: defaultValue, key.rawValue, store: store)
    }
    
    
    init(_ key: DefaultKey<Value>, store: UserDefaults? = nil) where Value == Data? {
        
        self.init(key.rawValue, store: store)
    }
}
