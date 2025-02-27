//
//  FontExtensionTests.swift
//  Tests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-06-10.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2025 1024jp
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

import AppKit.NSFont
import Testing
import Numerics
@testable import CotEditor

struct FontExtensionTests {
    
    @Test func fontSize() throws {
        
        let font = try #require(NSFont(name: "Menlo-Regular", size: 11))
        
        #expect(font.width(of: " ") == 6.62255859375)
    }
    
    
    @Test func fontWeight() throws {
        
        let regularFont = try #require(NSFont(name: "Menlo-Regular", size: 11))
        let boldFont = try #require(NSFont(name: "Menlo-Bold", size: 11))
        
        #expect(regularFont.weight == .regular)
        #expect(boldFont.weight.rawValue.isApproximatelyEqual(to: NSFont.Weight.bold.rawValue, relativeTolerance: 0.00001))
        
        // The const value is (unfortunately) not exact equal...
        #expect(boldFont.weight.rawValue == 0.4)
        #expect(NSFont.Weight.bold.rawValue != 0.4)
    }
    
    
    @Test func namedFont() throws {
        
        let avenirNextCondensed = try #require(NSFont(named: .avenirNextCondensed, weight: .bold, size: 11))
        #expect(avenirNextCondensed == NSFont(name: "AvenirNextCondensed-Bold", size: 11))
        #expect(avenirNextCondensed.weight.rawValue.isApproximatelyEqual(to: NSFont.Weight.bold.rawValue, relativeTolerance: 0.00001))
    }
}
