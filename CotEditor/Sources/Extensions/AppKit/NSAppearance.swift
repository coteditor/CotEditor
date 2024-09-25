//
//  NSAppearance.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-09-09.
//
//  ---------------------------------------------------------------------------
//
//  © 2018-2024 1024jp
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

import AppKit.NSAppearance

extension NSAppearance {
    
    /// The receiver is in the Dark Mode.
    final var isDark: Bool {
        
        self.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
    }
    
    
    /// The corresponding appearance for the light/dark mode.
    ///
    /// - Parameter isDark: Whether the return value to be for dark mode or not.
    /// - Returns: A new appearance, or `self` if no change required.
    fileprivate final func appearance(for isDark: Bool) -> Self {
        
        if isDark == self.isDark {
            self
        } else {
            Self(named: self.name.name(for: isDark)) ?? self
        }
    }
}


extension NSColor {
    
    /// Forcibly creates the appropriate color for the light/dark mode.
    ///
    /// - Parameter isDark: Whether the return value to be for dark mode or not.
    /// - Returns: A new color.
    final func forDarkMode(_ isDark: Bool) -> NSColor {
        
        guard self.type != .componentBased else { return self }
        
        return NSColor(name: nil) { appearance in
            if isDark == appearance.isDark {
                self
            } else {
                self.solve(for: appearance.appearance(for: isDark))
            }
        }
    }
    
    
    /// Forcibly creates the appropriate color for the given appearance.
    ///
    /// - Parameter appearance: The appearance to match.
    /// - Returns: A new color.
    private final func solve(for appearance: NSAppearance) -> NSColor {
        
        guard self.type != .componentBased else { return self }
        
        var color = self
        appearance.performAsCurrentDrawingAppearance {
            color = NSColor(cgColor: color.cgColor) ?? color
        }
        return color
    }
}


private extension NSAppearance.Name {
    
    /// The corresponding appearance name for the light/dark mode.
    ///
    /// - Parameter isDark: Whether the return value to be for dark mode or not.
    /// - Returns: An appearance name.
    func name(for isDark: Bool) -> Self {
        
        switch self {
            case .aqua, .darkAqua:
                isDark ? .darkAqua : .aqua
            case .vibrantLight, .vibrantDark:
                isDark ? .vibrantDark : .vibrantLight
            case .accessibilityHighContrastAqua, .accessibilityHighContrastDarkAqua:
                isDark ? .accessibilityHighContrastDarkAqua : .accessibilityHighContrastAqua
            case .accessibilityHighContrastVibrantLight, .accessibilityHighContrastVibrantDark:
                isDark ? .accessibilityHighContrastVibrantDark : .accessibilityHighContrastVibrantLight
            default:
                self
        }
    }
}
