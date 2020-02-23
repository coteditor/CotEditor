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
//  © 2018 1024jp
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
    
    var isDark: Bool {
        
        if self.name == .vibrantDark { return true }
        
        guard #available(macOS 10.14, *) else { return false }
        
        return self.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
    }
    
    
    var isHighContrast: Bool {
        
        guard #available(macOS 10.14, *) else {
            return NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
        }
        
        switch self.name {
            case .accessibilityHighContrastAqua,
                 .accessibilityHighContrastDarkAqua,
                 .accessibilityHighContrastVibrantLight,
                 .accessibilityHighContrastVibrantDark:
                return true
            default:
                return false
        }
    }
    
}
