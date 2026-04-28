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

@MainActor struct DebouncerTests {
    
    @Test func debounce() async throws {
        
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
    
    
    @Test func rescheduleFromAction() async throws {
        
        let delay: ContinuousClock.Duration = .seconds(0.2)
        let rescheduledDelay: ContinuousClock.Duration = .seconds(1)
        var count = 0
        var didReschedule = false
        let box = DebouncerBox()
        let debouncer = Debouncer(delay: delay) {
            count += 1
            if count == 1 {
                guard let debouncer = box.debouncer else { return }
                
                debouncer.schedule(delay: rescheduledDelay)
                didReschedule = true
            }
        }
        box.debouncer = debouncer
        
        debouncer.schedule()
        let didRescheduleFromAction = await self.waitFor { didReschedule }
        #expect(didRescheduleFromAction, "The action must reschedule itself.")
        #expect(count == 1, "The action can reschedule itself.")
        
        debouncer.cancel()
        try await Task.sleep(for: rescheduledDelay + .seconds(0.2))
        #expect(count == 1, "The rescheduled action must remain cancellable.")
    }
    
    
    @Test func immediateFire() async throws {
        
        let delay: ContinuousClock.Duration = .seconds(1)
        var value = 0
        let debouncer = Debouncer(delay: delay) {
            value += 1
        }
        
        #expect(0 == value)
        
        debouncer.fire()
        #expect(value == 0, "The action is performed only when scheduled.")
        
        debouncer.schedule()
        #expect(value == 0)
        
        debouncer.fire()
        #expect(value == 1, "The scheduled action must be performed immediately.")
        
        try await Task.sleep(for: .seconds(0.1))
        #expect(value == 1, "The scheduled task must be canceled after immediate firing.")
    }
    
    
    @Test func cancel() async throws {
        
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
    
    
    // MARK: Private Methods
    
    private func waitFor(timeout: Duration = .seconds(2), interval: Duration = .milliseconds(20), _ condition: @escaping () -> Bool) async -> Bool {
        
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: timeout)
        
        while clock.now < deadline {
            if condition() { return true }
            try? await Task.sleep(for: interval)
        }
        
        return condition()
    }
}


@MainActor private final class DebouncerBox {
    
    weak var debouncer: Debouncer?
}
