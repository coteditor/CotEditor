//
//  UserDefaultsObservationTests.swift
//  DefaultsTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2019-11-22.
//
//  ---------------------------------------------------------------------------
//
//  © 2019-2024 1024jp
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
import Combine
import Testing
@testable import Defaults

struct UserDefaultsObservationTests {
    
    @Test func observeKey() async {
        
        let key = DefaultKey<Bool>("Test Key")
        defer { UserDefaults.standard.restore(key: key) }
        
        UserDefaults.standard[key] = false
        
        await confirmation("UserDefaults observation for normal key") { confirm in
            let observer = UserDefaults.standard.publisher(for: key)
                .sink { value in
                    #expect(value)
                    confirm()
                }
            
            UserDefaults.standard[key] = true
            
            observer.cancel()
            UserDefaults.standard[key] = false
        }
    }
    
    
    @Test func initialEmit() async {
        
        let key = DefaultKey<Bool>("Initial Emission Test Key")
        defer { UserDefaults.standard.restore(key: key) }
        
        UserDefaults.standard[key] = false
        
        await confirmation("UserDefaults observation for initial emission") { confirm in
            let observer = UserDefaults.standard.publisher(for: key, initial: true)
                .sink { value in
                    #expect(!value)
                    confirm()
                }
            
            observer.cancel()
            UserDefaults.standard[key] = true
        }
    }
    
    
    @Test func optionalKey() async {
        
        let key = DefaultKey<String?>("Optional Test Key")
        defer { UserDefaults.standard.restore(key: key) }
        
        #expect(UserDefaults.standard[key] == nil)
        
        UserDefaults.standard[key] = "cow"
        #expect(UserDefaults.standard[key] == "cow")
        
        await confirmation("UserDefaults observation for optional key") { confirm in
            let observer = UserDefaults.standard.publisher(for: key)
                .sink { value in
                    #expect(value == nil)
                    confirm()
                }
            
            UserDefaults.standard[key] = nil
            
            #expect(UserDefaults.standard[key] == nil)
            
            observer.cancel()
            UserDefaults.standard[key] = "dog"
            #expect(UserDefaults.standard[key] == "dog")
        }
    }
    
    
    @Test func rawRepresentable() async {
        
        enum Clarus: Int  { case dog, cow }
        
        let key = RawRepresentableDefaultKey<Clarus>("Raw Representable Test Key")
        defer { UserDefaults.standard.restore(key: key) }
        
        UserDefaults.standard[key] = .dog
        
        await confirmation("UserDefaults observation for raw representable") { confirm in
            let observer = UserDefaults.standard.publisher(for: key)
                .sink { value in
                    #expect(value == .cow)
                    confirm()
                }
            
            UserDefaults.standard[key] = .cow
            
            observer.cancel()
            UserDefaults.standard[key] = .dog
            #expect(UserDefaults.standard[key] == .dog)
        }
    }
}
