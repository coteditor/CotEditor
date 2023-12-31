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
//  © 2016-2023 1024jp
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

extension NSColor {
    
    static let textHighlighterColor: NSColor = .accent.withAlphaComponent(0.4)
}



extension NSColor {
    
    /// The component-based (such as RGB) color converted from a semantic color.
    final var componentBased: NSColor {
        
        self.usingType(.componentBased) ?? self
    }
    
    
    /// Creates desired number of well distributed colors from the receiver.
    ///
    /// - Parameter number: The required number of colors.
    /// - Returns: An array of created colors.
    final func decompose(into number: Int) -> [NSColor] {
        
        (0..<number)
            .map { Double($0) / Double(number) }
            .map { (self.hueComponent + $0).truncatingRemainder(dividingBy: 1) }
            .map { NSColor(calibratedHue: $0, saturation: self.saturationComponent, brightness: self.brightnessComponent, alpha: self.alphaComponent) }
    }
}



public extension NSColor {
    
    /// The back-deployed version of the `.systemFill`.
    @backDeployed(before: macOS 14)
    static var systemFill: NSColor  { .labelColor.withAlphaComponent(0.50) }
    
    /// The back-deployed version of the `.secondarySystemFill`.
    @backDeployed(before: macOS 14)
    static var secondarySystemFill: NSColor  { .labelColor.withAlphaComponent(0.15) }
    
    /// The back-deployed version of the `.tertiarySystemFill`.
    @backDeployed(before: macOS 14)
    static var tertiarySystemFill: NSColor  { .labelColor.withAlphaComponent(0.10) }
    
    /// The back-deployed version of the `.quaternarySystemFill`.
    @backDeployed(before: macOS 14)
    static var quaternarySystemFill: NSColor  { .labelColor.withAlphaComponent(0.05) }
    
    /// The back-deployed version of the `.quinarySystemFill`.
    @backDeployed(before: macOS 14)
    static var quinarySystemFill: NSColor  { .labelColor.withAlphaComponent(0.03) }
}
