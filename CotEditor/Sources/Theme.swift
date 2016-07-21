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
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Foundation
import AppKit.NSColor


@objc protocol Themable {  // TODO: remove @objc
    
    var theme: Theme? { get }
}


private enum ThemeError: ErrorProtocol {
    
    case novalue
    case invalid
}

class Theme: NSObject {  // TODO: to struct
    
    // MARK: Public Properties
    
    /// name of the theme
    let name: String
    
    // basic colors
    let textColor: NSColor
    let backgroundColor: NSColor
    let invisiblesColor: NSColor
    var selectionColor: NSColor { return self.usesSystemSelectionColor ? .selectedTextBackgroundColor() : _selectionColor }
    let insertionPointColor: NSColor
    let lineHighLightColor: NSColor
    
    /// Is background color dark?
    let isDarkTheme: Bool
    
    /// Is created from a valid theme dict? (Theme itself can be used even invalid since NSColor.grayColor() are substituted for invalid colors.)
    let isValid: Bool
    
    
    // MARK: Private Properties
    
    private let syntaxColors: [SyntaxType: NSColor]
    private let usesSystemSelectionColor: Bool
    private let _selectionColor: NSColor
    
    
    
    // MARK:
    // MARK: Lifecycle
    
    required init?(dictionary: ThemeDictionary, name: String) {
        
        guard !name.isEmpty else { return nil }
        
        var colors = [ThemeKey: NSColor]()
        var isValid = true
        
        func unarchiveColor(subdict: NSMutableDictionary?) throws -> NSColor {
            
            guard let colorCode = subdict?[ThemeKey.Sub.color.rawValue] as? String else { throw ThemeError.novalue }
            
            var type: WFColorCodeType = .invalid
            guard let color = NSColor(colorCode: colorCode, codeType: &type),
                type == .hex || type == .shortHex else { throw ThemeError.invalid }
            
            return color
        }
        
        for key in ThemeKey.basicKeys {
            do {
                colors[key] = try unarchiveColor(subdict: dictionary[key.rawValue])
            } catch {
                colors[key] = .gray()
                isValid = false
            }
        }
        
        // unarchive syntax colors also
        var syntaxColors = [SyntaxType: NSColor]()
        for key in SyntaxType.all {
            do {
                syntaxColors[key] = try unarchiveColor(subdict: dictionary[key.rawValue])
            } catch {
                syntaxColors[key] = .gray()
                isValid = false
            }
        }
        self.syntaxColors = syntaxColors
        
        // set properties
        self.name = name
        self.isValid = isValid
        
        self.textColor = colors[.text]!
        self.backgroundColor = colors[.background]!
        self.invisiblesColor = colors[.invisibles]!
        self._selectionColor = colors[.selection]!
        self.insertionPointColor = colors[.insertionPoint]!
        self.lineHighLightColor = colors[.lineHighlight]!
        
        self.usesSystemSelectionColor = (dictionary[ThemeKey.selection.rawValue]?[ThemeKey.Sub.usesSystemSetting.rawValue] as? Bool) ?? false
        
        // standardize color space to obtain color values safety
        let textColor = self.textColor.usingColorSpaceName(NSDeviceRGBColorSpace)
        let backgroundColor = self.backgroundColor.usingColorSpaceName(NSDeviceRGBColorSpace)
        
        // check if background is dark
        self.isDarkTheme = backgroundColor?.brightnessComponent < textColor?.brightnessComponent
        
        super.init()
    }
    
    
    override var debugDescription: String {
        
        return "<Theme: \(self.name)>"
    }
    
    
    
    // MARK: Public Methods
    
    /// color for syntax type defined in theme
    func syntaxColor(type: String) -> NSColor? {
        
        guard let syntaxType = SyntaxType(rawValue: type) else { return nil }
        
        return self.syntaxColors[syntaxType]
    }
    
    
    /// color for syntax type defined in theme
    func syntaxColor(type: SyntaxType) -> NSColor? {
        
        return self.syntaxColors[type]
    }
    
}
