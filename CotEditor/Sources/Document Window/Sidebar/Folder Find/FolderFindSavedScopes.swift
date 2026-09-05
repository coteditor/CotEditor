//
//  FolderFindSavedScopes.swift
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
import Defaults
import FolderFind

@MainActor @Observable final class FolderFindSavedScopes {
    
    private(set) var scopes: [String: FileScope] = [:]
    private(set) var sortedNames: [String] = []
    private(set) var reservedNames: Set<String> = []
    
    private var scopesData: [String: Data] = [:]
    private let defaults: UserDefaults
    
    
    /// Initializes saved scope storage.
    ///
    /// - Parameter defaults: The user defaults in which to save scopes.
    init(defaults: UserDefaults = .standard) {
        
        self.defaults = defaults
    }
    
    
    /// Updates the decoded scopes from persisted data.
    ///
    /// - Parameter data: The saved scope data, including entries that cannot be decoded.
    func update(_ data: [String: Data]) {
        
        guard data != self.scopesData else { return }
        
        let decoder = JSONDecoder()
        self.scopesData = data
        self.scopes = data.compactMapValues { try? decoder.decode(FileScope.self, from: $0) }
        self.sortedNames = self.scopes.keys.sorted(using: .localizedStandard)
        self.reservedNames = Set(data.keys)
    }
    
    
    /// Saves a scope, optionally replacing its previous name.
    ///
    /// - Parameters:
    ///   - fileScope: The file scope to save.
    ///   - name: The name under which to save the scope.
    ///   - originalName: The previous name to remove, or `nil` when adding a scope.
    func save(_ fileScope: FileScope, name: String, replacing originalName: String? = nil) {
        
        let encodedScope: Data
        do {
            encodedScope = try JSONEncoder().encode(fileScope)
        } catch {
            assertionFailure("Failed to encode a saved file scope: \(error)")
            return
        }
        
        var data = self.scopesData
        if let originalName {
            data[originalName] = nil
        }
        data[name] = encodedScope
        
        self.persist(data)
    }
    
    
    /// Deletes a saved scope.
    ///
    /// - Parameter name: The name of the scope to delete.
    func remove(name: String) {
        
        var data = self.scopesData
        data[name] = nil
        
        self.persist(data)
    }
    
    
    /// Updates the cached scopes and writes their data to user defaults.
    ///
    /// - Parameter data: The scope data to persist.
    private func persist(_ data: [String: Data]) {
        
        self.update(data)
        self.defaults[.folderFindSavedScopes] = data
    }
}
