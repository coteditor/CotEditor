//
//  LanguageRegistryTests.swift
//  SyntaxTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-02-10.
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
//

import Foundation
import Testing
import StringUtils
import ValueRange
@testable import Syntax

actor LanguageRegistryTests {
    
    private let registry: LanguageRegistry = .shared
    
    
    @Test(arguments: LanguageRegistry.Language.allCases)
    func configuration(for language: LanguageRegistry.Language) throws {
        
        #expect(try self.registry.configuration(for: language) != nil)
    }
}
