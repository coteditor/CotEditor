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
//  © 2014-2021 1024jp
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

protocol Themable: AnyObject {
    
    var theme: Theme? { get }
}



final class Theme: NSObject {
    
    final class Style: NSObject {
        
        @objc dynamic var color: NSColor
        
        fileprivate static let invalidColor = NSColor.gray.usingColorSpace(.genericRGB)!
        
        
        init(color: NSColor) {
            
            self.color = color
        }
    }
    
    
    final class SelectionStyle: NSObject {
        
        @objc dynamic var color: NSColor
        @objc dynamic var usesSystemSetting: Bool
        
        
        init(color: NSColor, usesSystemSetting: Bool = false) {
            
            self.color = color
            self.usesSystemSetting = usesSystemSetting
        }
    }
    
    
    final class Metadata: NSObject, Codable {
        
        @objc dynamic var author: String?
        @objc dynamic var distributionURL: String?
        @objc dynamic var license: String?
        @objc dynamic var comment: String?
        
        
        var isEmpty: Bool {
            
            return self.author == nil && self.distributionURL == nil && self.license == nil && self.comment == nil
        }
        
        
        enum CodingKeys: String, CodingKey {
            
            case author
            case distributionURL
            case license
            case comment = "description"  // `description` conflicts with NSObject's method.
        }
    }
    
    
    
    // MARK: Public Properties
    
    /// name of the theme
    var name: String?
    
    // basic colors
    @objc dynamic var text: Style
    @objc dynamic var background: Style
    @objc dynamic var invisibles: Style
    @objc dynamic var selection: SelectionStyle
    @objc dynamic var insertionPoint: Style
    @objc dynamic var lineHighlight: Style
    
    @objc dynamic var keywords: Style
    @objc dynamic var commands: Style
    @objc dynamic var types: Style
    @objc dynamic var attributes: Style
    @objc dynamic var variables: Style
    @objc dynamic var values: Style
    @objc dynamic var numbers: Style
    @objc dynamic var strings: Style
    @objc dynamic var characters: Style
    @objc dynamic var comments: Style
    
    var metadata: Metadata?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    init(name: String? = nil) {
        
        self.name = name
        
        self.text = Style(color: .textColor)
        self.background = Style(color: .textBackgroundColor)
        self.invisibles = Style(color: .init(white: 0.7, alpha: 1))
        self.selection = SelectionStyle(color: .selectedTextBackgroundColor, usesSystemSetting: true)
        self.insertionPoint = Style(color: .textColor)
        self.lineHighlight = Style(color: .init(white: 0.95, alpha: 1))
        
        self.keywords = Style(color: .gray)
        self.commands = Style(color: .gray)
        self.types = Style(color: .gray)
        self.attributes = Style(color: .gray)
        self.variables = Style(color: .gray)
        self.values = Style(color: .gray)
        self.numbers = Style(color: .gray)
        self.strings = Style(color: .gray)
        self.characters = Style(color: .gray)
        self.comments = Style(color: .gray)
    }
    
    
    static func theme(contentsOf fileURL: URL) throws -> Theme {
        
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        
        let theme = try decoder.decode(Theme.self, from: data)
        theme.name = fileURL.deletingPathExtension().lastPathComponent
        
        return theme
    }
    
    
    
    // MARK: Public Methods
    
    /// Is background color dark?
    var isDarkTheme: Bool {
        
        guard
            let textColor = self.text.color.usingColorSpace(.genericRGB),
            let backgroundColor = self.background.color.usingColorSpace(.genericRGB)
        else { return false }
        
        return backgroundColor.lightnessComponent < textColor.lightnessComponent
    }
    
    
    /// selection color for inactive text view
    var secondarySelectionColor: NSColor? {
        
        guard
            !self.selection.usesSystemSetting,
            let color = self.selection.color.usingColorSpace(.genericRGB)
        else { return nil }
        
        return NSColor(calibratedWhite: color.lightnessComponent, alpha: 1.0)
    }
    
}



// MARK: - Codable

extension Theme: Codable {
    
    private enum CodingKeys: String, CodingKey {
        
        case text
        case background
        case invisibles
        case selection
        case insertionPoint
        case lineHighlight
        
        case keywords
        case commands
        case types
        case attributes
        case variables
        case values
        case numbers
        case strings
        case characters
        case comments
        
        case metadata
    }
    
}



extension Theme.Style: Codable {
    
    private enum CodingKeys: String, CodingKey {
        
        case color
    }
    
    
    convenience init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let colorCode = try container.decode(String.self, forKey: .color)
        let color = NSColor(colorCode: colorCode) ?? Theme.Style.invalidColor
        
        self.init(color: color)
    }
    
    
    func encode(to encoder: Encoder) throws {
        
        guard let color = self.color.usingColorSpace(.genericRGB) else { throw CocoaError(.coderInvalidValue) }
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(color.colorCode(type: .hex), forKey: .color)
    }
    
}



extension Theme.SelectionStyle: Codable {
    
    private enum CodingKeys: String, CodingKey {
        
        case color
        case usesSystemSetting
    }
    
    
    convenience init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let colorCode = try container.decode(String.self, forKey: .color)
        let color = NSColor(colorCode: colorCode) ?? Theme.Style.invalidColor
        
        let usesSystemSetting = try container.decodeIfPresent(Bool.self, forKey: .usesSystemSetting) ?? false
        
        self.init(color: color, usesSystemSetting: usesSystemSetting)
    }
    
    
    func encode(to encoder: Encoder) throws {
        
        guard let color = self.color.usingColorSpace(.genericRGB) else { throw CocoaError(.coderInvalidValue) }
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(color.colorCode(type: .hex), forKey: .color)
        try container.encode(self.usesSystemSetting, forKey: .usesSystemSetting)
    }
    
}
