//
//  DebouncerTests.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2020-03-24.
//
//  ---------------------------------------------------------------------------
//
//  © 2020-2026 1024jp
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

import Testing
@testable import CotEditor

struct DebouncerTests {
    
    @MainActor @Test func debounce() async throws {
        
        let delay: ContinuousClock.Duration = .seconds(0.2)
        try await confirmation("Debouncer executed", expectedCount: 1) { confirm in
            let debouncer = Debouncer(delay: delay) {
                confirm()
            }
            
            debouncer.schedule()
            try await Task.sleep(for: .seconds(0.1))
            debouncer.schedule()
            
            try await Task.sleep(for: delay + .seconds(0.2))
        }
    }
    
    
    @MainActor @Test func immediateFire() async throws {
        
        let delay: ContinuousClock.Duration = .seconds(1)
        var value = 0
        let debouncer = Debouncer(delay: delay) {
            value += 1
        }
        
        #expect(0 == value)
        
        debouncer.fireNow()
        #expect(value == 0, "The action is performed only when scheduled.")
        
        debouncer.schedule()
        #expect(value == 0)
        
        debouncer.fireNow()
        #expect(value == 1, "The scheduled action must be performed immediately.")
        
        try await Task.sleep(for: .seconds(0.1))
        #expect(value == 1, "The scheduled task must be canceled after immediate firing.")
    }
    
    
    @MainActor @Test func cancel() async throws {
        
        let delay: ContinuousClock.Duration = .seconds(0.2)
        try await confirmation("Debouncer cancelled", expectedCount: 0) { confirm in
            let debouncer = Debouncer(delay: delay) {
                confirm()
            }
            
            debouncer.schedule()
            debouncer.cancel()
            
            try await Task.sleep(for: delay + .seconds(0.2))
        }
    }
}
