//
//  NSColor+NamedColors.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-06-27.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2018 1024jp
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

import AppKit.NSColor
import AppKit.NSAppearance

extension NSColor {
    
    static let textHighlighterColor = NSColor(calibratedHue: 0.24, saturation: 0.8, brightness: 0.8, alpha: 0.4)
    static let alternateDisabledControlTextColor = NSColor(white: 1.0, alpha: 0.75)
}
    

extension NSColor {
    
    /// Creates a new color object that represents a blend between the current color and the weaken color by considering appearance.
    func darken(level: CGFloat, for appearance: NSAppearance) -> NSColor? {
        
        return appearance.isDark ? self.highlight(withLevel: level) : self.shadow(withLevel: level)
    }
    
    
    /// return well distributed colors to highlight text
    static func textHighlighterColors(count: Int) -> [NSColor] {
        
        return NSColor.textHighlighterColor.decomposite(into: count)
    }
    
    
    
    // MARK: Private Methods
    
    /// create desired number of colors from itself
    private func decomposite(into number: Int) -> [NSColor] {
        
        guard number > 0 else { return [] }
        
        let baseHue = self.hueComponent
        let saturation = self.saturationComponent
        let brightness = self.brightnessComponent
        let alpha = self.alphaComponent
        
        return (0..<number).map { index in
            let advance = CGFloat(index) / CGFloat(number)
            let (_, hue) = modf(baseHue + advance)
            
            return NSColor(calibratedHue: hue, saturation: saturation, brightness: brightness, alpha: alpha)
        }
    }
    
}


extension NSAppearance {
    
    var isDark: Bool {
        
        if self.name == .vibrantDark { return true }
        
        guard #available(macOS 10.14, *) else { return false }
        
        return self.name == .darkAqua
    }
    
}
