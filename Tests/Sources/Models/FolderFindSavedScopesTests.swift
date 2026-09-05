//
//  FolderFindSavedScopesTests.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-09-05.
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
import Defaults
import FolderFind
@testable import CotEditor

@MainActor struct FolderFindSavedScopesTests {
    
    @Test func savedScopesPreserveUndecodableEntries() throws {
        
        let suiteName = "FolderFindSavedScopesTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        
        let scope = FileScope(rules: [.init(target: .fileExtension, comparison: .isEqualTo, value: "swift")])
        let invalidData = Data("invalid".utf8)
        defaults[.folderFindSavedScopes] = ["Invalid": invalidData]
        let model = FolderFindSavedScopes(defaults: defaults)
        model.update(defaults[.folderFindSavedScopes])
        
        #expect(model.scopes.isEmpty)
        #expect(model.sortedNames.isEmpty)
        #expect(model.reservedNames == ["Invalid"])
        
        model.save(scope, name: "Swift")
        #expect(model.scopes == ["Swift": scope])
        #expect(model.sortedNames == ["Swift"])
        #expect(model.reservedNames == ["Invalid", "Swift"])
        #expect(defaults[.folderFindSavedScopes]["Invalid"] == invalidData)
        let savedData = try #require(defaults[.folderFindSavedScopes]["Swift"])
        #expect(try JSONDecoder().decode(FileScope.self, from: savedData) == scope)
        
        model.save(scope, name: "Sources", replacing: "Swift")
        #expect(model.scopes == ["Sources": scope])
        #expect(model.sortedNames == ["Sources"])
        #expect(model.reservedNames == ["Invalid", "Sources"])
        #expect(defaults[.folderFindSavedScopes]["Swift"] == nil)
        
        model.remove(name: "Sources")
        #expect(model.scopes.isEmpty)
        #expect(model.sortedNames.isEmpty)
        #expect(model.reservedNames == ["Invalid"])
        #expect(defaults[.folderFindSavedScopes] == ["Invalid": invalidData])
    }
    
    
    @Test func externalUpdatesRefreshDecodedScopes() throws {
        
        let suiteName = "FolderFindSavedScopesTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        
        let model = FolderFindSavedScopes(defaults: defaults)
        let scope = FileScope(rules: [.init(target: .fileExtension, comparison: .isEqualTo, value: "swift")])
        let data = try JSONEncoder().encode(scope)
        model.update(["Scope 10": data, "Scope 2": data])
        #expect(model.sortedNames == ["Scope 2", "Scope 10"])
        
        let changedScope = FileScope(rules: [.init(target: .filename, comparison: .startsWith, value: "Test")])
        let changedData = try JSONEncoder().encode(changedScope)
        model.update(["Scope 2": changedData])
        #expect(model.scopes == ["Scope 2": changedScope])
        #expect(model.sortedNames == ["Scope 2"])
        #expect(model.reservedNames == ["Scope 2"])
        
        model.update([:])
        #expect(model.scopes.isEmpty)
        #expect(model.sortedNames.isEmpty)
        #expect(model.reservedNames.isEmpty)
    }
}
