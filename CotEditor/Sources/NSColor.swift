/*
 
 NSColor.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-06-27.
 
 ------------------------------------------------------------------------------
 
 © 2016 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 https://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import AppKit.NSColor

extension NSColor {
    
    /// create desired number of colors from itself
    func decomposite(into n: Int) -> [NSColor] {
        
        let baseHue = self.hueComponent
        let saturation = self.saturationComponent
        let brightness = self.brightnessComponent
        let alpha = self.alphaComponent
        
        return (0..<n).map { index in
            let advance = CGFloat(index) / CGFloat(n)
            let (_, hue) = modf(baseHue + advance)
            
            return NSColor(calibratedHue: hue, saturation: saturation, brightness: brightness, alpha: alpha)
        }
    }
    
}
