//
//  NSFontManager.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2020-09-02.
//
//  ---------------------------------------------------------------------------
//
//  © 2020 1024jp
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

extension NSFontManager {
    
    /// Returns a font object whose weight is greater or lesser than that of the given font.
    ///
    /// - Parameters:
    ///   - level: Tne number of levels to increase/decrease the font weight.
    ///   - font: The font whose weight is increased or decreased.
    /// - Returns: A font with matching traits except for the new weight, or aFont if it can’t be converted.
    func convertWeight(level: Int, of font: NSFont) -> NSFont {
        
        guard level != 0 else { return font }
        
        var font = font
        for _ in 0..<abs(level) {
            font = self.convertWeight((level > 0), of: font)
        }
        
        return font
    }
    
}
