//
//  DefaultKey+FontType.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2023-04-29.
//
//  ---------------------------------------------------------------------------
//
//  © 2023 1024jp
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

import AppKit

enum FontType {
    
    case standard
    case monospaced
    
    
    /// Returns the default system font the given font type.
    ///
    /// - Parameter size: The size of the font.
    /// - Returns: An NSFont.
    func systemFont(size: Double = 0) -> NSFont {
        
        switch self {
            case .standard:
                .userFont(ofSize: size)
                ?? .systemFont(ofSize: size)
            case .monospaced:
                .userFixedPitchFont(ofSize: size)
                ?? .monospacedSystemFont(ofSize: size, weight: .regular)
        }
    }
}


extension UserDefaults {
    
    /// Returns the user font for the given font type.
    ///
    /// - Parameter type: The font type.
    /// - Returns: An NSFont.
    final func font(for type: FontType) -> NSFont {
        
        guard
            let data = self[.fontKey(for: type)],
            let descriptor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSFontDescriptor.self, from: data),
            let font = NSFont(descriptor: descriptor, size: 0)
        else { return type.systemFont() }
        
        return font
    }
}


extension NSFont {
    
    /// Keyed archived data of the font descriptor to store.
    final var archivedData: Data {
        
        get throws {
            
            try NSKeyedArchiver.archivedData(withRootObject: self.fontDescriptor, requiringSecureCoding: true)
        }
    }
}


// MARK: DefaultKey

extension DefaultKey<Data?> {
    
    /// Returns the user default key for the font name of the given font type.
    ///
    /// - Parameter type: The font type.
    /// - Returns: An user default key.
    static func fontKey(for type: FontType) -> DefaultKey<Data?> {
        
        switch type {
            case .standard: .font
            case .monospaced: .monospacedFont
        }
    }
}


extension DefaultKey<Bool> {
    
    /// Returns the user default key for whether the antialiasing is enabled for the given font type.
    ///
    /// - Parameter type: The font type.
    /// - Returns: An user default key.
    static func antialias(for type: FontType) -> DefaultKey<Bool> {
        
        switch type {
            case .standard: .shouldAntialias
            case .monospaced: .monospacedShouldAntialias
        }
    }
    
    
    /// Returns the user default key for whether the ligature is enabled for the given font type.
    ///
    /// - Parameter type: The font type.
    /// - Returns: An user default key.
    static func ligature(for type: FontType) -> DefaultKey<Bool> {
        
        switch type {
            case .standard: .ligature
            case .monospaced: .monospacedLigature
        }
    }
}
