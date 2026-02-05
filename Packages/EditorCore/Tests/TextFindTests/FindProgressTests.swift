//
//  FindProgressTests.swift
//  TextFindTests
//
//  Created by 1024jp on 2026-02-05.
//
//  ---------------------------------------------------------------------------
//
//  © 2026 1024jp
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


import Testing
@testable import TextFind

struct FindProgressTests {
    
    @Test func initialState() {
        
        let progress = FindProgress(scope: 0..<10)
        
        #expect(progress.state == .ready)
        #expect(progress.count == 0)
        #expect(progress.fractionCompleted == 0)
    }
    
    
    @Test func fractionCompleted() {
        
        let progress = FindProgress(scope: 0..<10)
        
        progress.updateCompletedUnit(to: 3)
        #expect(progress.fractionCompleted == 0.3)
        
        progress.finish()
        #expect(progress.fractionCompleted == 1)
    }
    
    
    @Test func fractionCompletedWithEmptyScope() {
        
        let progress = FindProgress(scope: 0..<0)
        
        #expect(progress.fractionCompleted == 1)
    }
    
    
    @Test func incrementCount() {
        
        let progress = FindProgress(scope: 0..<5)
        
        progress.incrementCount()
        progress.incrementCount(by: 2)
        
        #expect(progress.count == 3)
    }
    
    
    @Test func updateAndIncrementCompletedUnit() {
        
        let progress = FindProgress(scope: 0..<3)
        
        progress.updateCompletedUnit(to: 2)
        #expect(progress.fractionCompleted == 2.0 / 3.0)
        
        progress.incrementCompletedUnit()
        #expect(progress.fractionCompleted == 1)
    }
    
    
    @Test func stateTransitions() {
        
        let progress = FindProgress(scope: 0..<1)
        
        #expect(!progress.state.isTerminated)
        
        progress.finish()
        #expect(progress.state == .finished)
        #expect(progress.state.isTerminated)
        
        let another = FindProgress(scope: 0..<1)
        another.cancel()
        #expect(another.state == .cancelled)
        #expect(another.state.isTerminated)
    }
}
