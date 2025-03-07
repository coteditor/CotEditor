//
//  ModeManager.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-03-02.
//
//  ---------------------------------------------------------------------------
//
//  © 2024 1024jp
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
import Syntax

@MainActor final class ModeManager {
    
    typealias Setting = ModeOptions
    
    
    // MARK: Public Properties
    
    static let shared = ModeManager(defaults: .standard)
    
    
    // MARK: Private Properties
    
    private let defaults: UserDefaults
    
    
    // MARK: Lifecycle
    
    private init(defaults: UserDefaults) {
        
        self.defaults = defaults
    }
    
    
    // MARK: Public Methods
    
    /// The user syntax modes currently available.
    var syntaxModes: [Mode] {
        
        self.defaults[.modes].keys
            .sorted(using: .localizedStandard)
            .compactMap(Mode.init(rawValue:))
            .filter { if case .syntax = $0 { true } else { false } }
    }
    
    
    /// Returns the mode corresponding to the given syntax.
    ///
    /// - Parameter syntax: The syntax name.
    /// - Returns: A mode.
    func mode(for syntaxName: String) -> Mode {
        
        if let mode = self.syntaxModes.first(where: { $0 == .syntax(syntaxName) }) {
            mode
        } else if let kind = try? self.syntaxKind(name: syntaxName) {
            .kind(kind)
        } else {
            .kind(.general)
        }
    }
    
    
    /// Returns the setting instance corresponding to the given mode.
    ///
    /// - Parameter mode: The mode.
    /// - Returns: A mode options.
    func setting(for mode: Mode) -> Setting {
        
        if case .syntax = mode, let setting = self.loadSetting(for: mode) {
            return setting
        }
        
        let kind = switch mode {
            case .kind(let kind): kind
            case .syntax(let name): (try? self.syntaxKind(name: name)) ?? .general
        }
        
        return self.loadSetting(for: .kind(kind)) ?? kind.defaultOptions
    }
    
    
    /// Add a syntax-specific setting to the user defaults.
    ///
    /// - Parameter syntaxName: The syntax name for the new setting to add.
    /// - Throws: `SettingFileError`
    func addSetting(for syntaxName: String) throws {
        
        let kind = try self.syntaxKind(name: syntaxName)
        
        self.save(setting: kind.defaultOptions, mode: .syntax(syntaxName))
    }
    
    
    /// Deletes user's setting for the given mode.
    ///
    /// - Parameters:
    ///   - mode: The mode to delete.
    func removeSetting(for mode: Mode) {
        
        // setting for syntax kind can't be removed
        guard case .syntax = mode else { return }

        self.defaults[.modes].removeValue(forKey: mode.rawValue)
    }
    
    
    /// Saves the given setting file.
    ///
    /// - Parameters:
    ///   - setting: The setting to save.
    ///   - mode: The mode of the setting to save.
    func save(setting: Setting, mode: Mode) {
        
        if case .kind(let kind) = mode, setting == kind.defaultOptions {
            self.defaults[.modes].removeValue(forKey: mode.rawValue)
            if self.defaults[.modes].isEmpty {
                self.defaults.restore(key: .modes)
            }
        } else {
            self.defaults[.modes][mode.rawValue] = setting.dictionary
        }
    }
    
    
    // MARK: Private Methods
    
    /// Returns the kind of the syntax with the given name.
    ///
    /// - Parameter name: The name of the syntax.
    /// - Returns: Syntax.Kind.
    nonisolated private func syntaxKind(name: SyntaxManager.SettingName) throws -> Syntax.Kind {
        
        try SyntaxManager.shared.setting(name: name).kind
    }
    
    
    /// Loads setting for the given mode from the user defaults.
    ///
    /// - Parameter mode: The editing mode.
    /// - Returns: The user mode setting if available.
    private func loadSetting(for mode: Mode) -> Setting? {
        
        guard let dictionary = self.defaults[.modes][mode.rawValue] as? [String: AnyHashable] else { return nil }
        
        return ModeOptions(dictionary: dictionary)
    }
}
