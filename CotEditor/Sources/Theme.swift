/*
 
 Theme.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2014-04-12.
 
 ------------------------------------------------------------------------------
 
 © 2014-2017 1024jp
 
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


struct Theme {
    
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
    
    private static let invalidColor = NSColor.gray.usingColorSpaceName(NSCalibratedRGBColorSpace)!
    
    private let syntaxColors: [SyntaxType: NSColor]
    private let usesSystemSelectionColor: Bool
    private let _selectionColor: NSColor
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    init?(dictionary: ThemeDictionary, name: String) {
        
        guard !name.isEmpty else { return nil }
        
        // unarchive colors
        var isValid = true
        let colors: [ThemeKey: NSColor] = ThemeKey.colorKeys.flatDictionary { (key) in
            guard
                let colorCode = dictionary[key.rawValue]?[ThemeKey.Sub.color.rawValue] as? String,
                let color = NSColor(colorCode: colorCode)
                else {
                    isValid = false
                    return (key, Theme.invalidColor)
            }
            
            return (key, color)
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
        
        self.syntaxColors = ThemeKey.syntaxKeys.flatDictionary { (SyntaxType(rawValue: $0.rawValue)!, colors[$0]!) }  // The syntax key and theme keys must be the same.
        
        self.usesSystemSelectionColor = dictionary[ThemeKey.selection.rawValue]?[ThemeKey.Sub.usesSystemSetting.rawValue] as? Bool ?? false
        self.isDarkTheme = self.backgroundColor.brightnessComponent < self.textColor.brightnessComponent
    }
    
    
    
    // MARK: Public Methods
    
    /// color for syntax type defined in theme
    func syntaxColor(type: SyntaxType) -> NSColor? {
        
        return self.syntaxColors[type]
    }
    
}


extension Theme: CustomStringConvertible {
    
    var description: String {
        
        return "<Theme: \(self.name)>"
    }
    
}
