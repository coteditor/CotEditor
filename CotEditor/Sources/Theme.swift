//
//  Theme.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2014-04-12.
//
//  ---------------------------------------------------------------------------
//
//  © 2014-2018 1024jp
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

import Foundation
import AppKit.NSColor
import ColorCode

protocol Themable: class {
    
    var theme: Theme? { get }
}


struct Theme {
    
    struct Style {
        
        var color: NSColor
        var usesSystemSetting: Bool = false
    }
    
    
    // MARK: Public Properties
    
    /// name of the theme
    var name: String?
    
    // basic colors
    var text: Style
    var background: Style
    var invisibles: Style
    var selection: Style
    var insertionPoint: Style
    var lineHighlight: Style
    
    var keywords: Style
    var commands: Style
    var types: Style
    var attributes: Style
    var variables: Style
    var values: Style
    var numbers: Style
    var strings: Style
    var characters: Style
    var comments: Style
    
    
    // MARK: Private Properties
    
    private static let invalidColor = NSColor.gray.usingColorSpaceName(.calibratedRGB)!
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    init(dictionary: ThemeDictionary, name: String? = nil) {
        
        // unarchive colors
        let styles: [ThemeKey: Style] = ThemeKey.colorKeys.reduce(into: [:]) { (dict, key) in
            let color: NSColor = {
                guard
                    let colorCode = dictionary[key.rawValue]?[ThemeKey.Sub.color.rawValue] as? String,
                    let color = NSColor(colorCode: colorCode)
                    else { return Theme.invalidColor }
                
                return color
            }()
            
            let usesSystemSetting = dictionary[key.rawValue]?[ThemeKey.Sub.usesSystemSetting.rawValue] as? Bool
            
            dict[key] = Style(color: color, usesSystemSetting: usesSystemSetting ?? false)
        }
        
        // set properties
        self.name = name
        
        self.text = styles[.text]!
        self.background = styles[.background]!
        self.invisibles = styles[.invisibles]!
        self.selection = styles[.selection]!
        self.insertionPoint = styles[.insertionPoint]!
        self.lineHighlight = styles[.lineHighlight]!
        
        self.keywords = styles[.keywords]!
        self.commands = styles[.commands]!
        self.types = styles[.types]!
        self.attributes = styles[.attributes]!
        self.variables = styles[.variables]!
        self.values = styles[.values]!
        self.numbers = styles[.numbers]!
        self.strings = styles[.strings]!
        self.characters = styles[.characters]!
        self.comments = styles[.comments]!
    }
    
    
    
    // MARK: Public Methods
    
    /// Is background color dark?
    var isDarkTheme: Bool {
        
        return self.background.color.brightnessComponent < self.text.color.brightnessComponent
    }
    
    
    /// selection color for inactive text view
    var secondarySelectionColor: NSColor? {
        
        return self.selection.usesSystemSetting ? nil : NSColor(calibratedWhite: self.selection.color.brightnessComponent, alpha: 1.0)
    }
    
    
    /// color for syntax type defined in theme
    func style(for type: SyntaxType) -> Style? {
        
        // The syntax key and theme keys must be the same.
        switch type {
        case .keywords: return self.keywords
        case .commands: return self.commands
        case .types: return self.types
        case .attributes: return self.attributes
        case .variables: return self.variables
        case .values: return self.values
        case .numbers: return self.numbers
        case .strings: return self.strings
        case .characters: return self.characters
        case .comments: return self.comments
        }
    }
    
}
