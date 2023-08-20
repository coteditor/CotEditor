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
    
    
    /// Default system font the given font type.
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
    
    /// User font for the given font type.
    ///
    /// - Parameter type: The font type.
    /// - Returns: An NSFont.
    func font(for type: FontType) -> NSFont {
        
        let name = self[.fontName(for: type)]
        let size = self[.fontSize(for: type)]
        
        return NSFont(name: name, size: size) ?? type.systemFont(size: size)
    }
}


// MARK: DefaultKey

extension DefaultKey<String> {
    
    /// The user default key for the font name of the given font type.
    ///
    /// - Parameter type: The font type.
    /// - Returns: An user default key.
    static func fontName(for type: FontType) -> DefaultKey<String> {
        
        switch type {
            case .standard: .fontName
            case .monospaced: .monospacedFontName
        }
    }
}


extension DefaultKey<Double> {
    
    /// The user default key for the font size of the given font type.
    ///
    /// - Parameter type: The font type.
    /// - Returns: An user default key.
    static func fontSize(for type: FontType) -> DefaultKey<Double> {
        
        switch type {
            case .standard: .fontSize
            case .monospaced: .monospacedFontSize
        }
    }
}


extension DefaultKey<Bool> {
    
    /// The user default key for whether the antialiasing is enabled for the given font type.
    ///
    /// - Parameter type: The font type.
    /// - Returns: An user default key.
    static func antialias(for type: FontType) -> DefaultKey<Bool> {
        
        switch type {
            case .standard: .shouldAntialias
            case .monospaced: .monospacedShouldAntialias
        }
    }
    
    
    /// The user default key for whether the ligature is enabled for the given font type.
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
