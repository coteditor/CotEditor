/*
 
 Theme.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2014-04-12.
 
 ------------------------------------------------------------------------------
 
 © 2014-2016 1024jp
 
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

import Foundation
import AppKit.NSColor
import ColorCode


protocol Themable: class {
    
    var theme: Theme? { get }
}

struct Theme: CustomDebugStringConvertible {
    
    // MARK: Public Properties
    
    /// name of the theme
    let name: String
    
    // basic colors
    let textColor: NSColor
    let backgroundColor: NSColor
    let invisiblesColor: NSColor
    var selectionColor: NSColor { return self.usesSystemSelectionColor ? .selectedTextBackgroundColor : _selectionColor }
    let insertionPointColor: NSColor
    let lineHighLightColor: NSColor
    
    /// Is background color dark?
    let isDarkTheme: Bool
    
    /// Is created from a valid theme dict? (Theme itself can be used even invalid since NSColor.gray are substituted for invalid colors.)
    let isValid: Bool
    
    
    // MARK: Private Properties
    
    private let syntaxColors: [SyntaxType: NSColor]
    private let usesSystemSelectionColor: Bool
    private let _selectionColor: NSColor
    
    
    
    // MARK:
    // MARK: Lifecycle
    
    init?(dictionary: ThemeDictionary, name: String) {
        
        guard !name.isEmpty else { return nil }
        
        func unarchiveColor(subdict: NSMutableDictionary?) throws -> NSColor {
            
            guard let colorCode = subdict?[ThemeKey.Sub.color.rawValue] as? String else { throw ThemeError.noValue }
            
            var type: ColorCodeType = .invalid
            guard let color = NSColor(colorCode: colorCode, type: &type),
                type == .hex || type == .shortHex else { throw ThemeError.invalid }
            
            return color
        }
        
        var isValid = true
        
        let colors: [ThemeKey: NSColor] = ThemeKey.basicKeys.reduce([:]) { (dict, key) in
            var dict = dict
            do {
                dict[key] = try unarchiveColor(subdict: dictionary[key.rawValue])
            } catch {
                dict[key] = .gray
                isValid = false
            }
            return dict
        }
        
        // unarchive syntax colors also
        self.syntaxColors = SyntaxType.all.reduce([:]) { (dict, key) in
            var dict = dict
            do {
                dict[key] = try unarchiveColor(subdict: dictionary[key.rawValue])
            } catch {
                dict[key] = .gray
                isValid = false
            }
            return dict
        }
        
        // set properties
        self.name = name
        self.isValid = isValid
        
        self.textColor = colors[.text]!
        self.backgroundColor = colors[.background]!
        self.invisiblesColor = colors[.invisibles]!
        self._selectionColor = colors[.selection]!
        self.insertionPointColor = colors[.insertionPoint]!
        self.lineHighLightColor = colors[.lineHighlight]!
        
        self.usesSystemSelectionColor = dictionary[ThemeKey.selection.rawValue]?[ThemeKey.Sub.usesSystemSetting.rawValue] as? Bool ?? false
        
        // standardize color space to obtain color values safety
        let textColor = self.textColor.usingColorSpaceName(NSDeviceRGBColorSpace)!
        let backgroundColor = self.backgroundColor.usingColorSpaceName(NSDeviceRGBColorSpace)!
        
        // check if background is dark
        self.isDarkTheme = backgroundColor.brightnessComponent < textColor.brightnessComponent
    }
    
    
    var debugDescription: String {
        
        return "<Theme: \(self.name)>"
    }
    
    
    
    // MARK: Public Methods
    
    /// color for syntax type defined in theme
    func syntaxColor(type: SyntaxType) -> NSColor? {
        
        return self.syntaxColors[type]
    }
    
}



// MARK: - Error

private enum ThemeError: Error {
    
    case noValue
    case invalid
}
