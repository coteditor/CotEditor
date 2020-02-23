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
//  © 2014-2019 1024jp
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


struct Theme: Equatable, Codable {
    
    struct Style: Equatable {
        
        var color: NSColor
    }
    
    
    struct SelectionStyle: Equatable {
        
        var color: NSColor
        var usesSystemSetting: Bool
    }
    
    
    
    enum CodingKeys: String, CodingKey {
        
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
    
    
    
    // MARK: Public Properties
    
    /// name of the theme
    var name: String?
    
    // basic colors
    var text: Style
    var background: Style
    var invisibles: Style
    var selection: SelectionStyle
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
    
    var metadata: Metadata?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    init(contentsOf fileURL: URL) throws {
        
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        
        self = try decoder.decode(Theme.self, from: data)
        
        // -> `.immutable` is a workaround for NSPathStore2 bug (2019-10 Xcode 11.1)
        self.name = fileURL.deletingPathExtension().lastPathComponent.immutable
    }
    
    
    
    // MARK: Public Methods
    
    /// Is background color dark?
    var isDarkTheme: Bool {
        
        return self.background.color.lightnessComponent < self.text.color.lightnessComponent
    }
    
    
    /// selection color for inactive text view
    var secondarySelectionColor: NSColor? {
        
        return self.selection.usesSystemSetting ? nil : NSColor(calibratedWhite: self.selection.color.lightnessComponent, alpha: 1.0)
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



// MARK: - Codable

extension Theme.Style: Codable {
    
    fileprivate static let invalidColor = NSColor.gray.usingColorSpace(.genericRGB)!
    
    private enum CodingKeys: String, CodingKey {
        
        case color
    }
    
    
    init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let colorCode = try container.decode(String.self, forKey: .color)
        self.color = NSColor(colorCode: colorCode) ?? Theme.Style.invalidColor
    }
    
    
    func encode(to encoder: Encoder) throws {
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(self.color.colorCode(type: .hex), forKey: .color)
    }
    
}



extension Theme.SelectionStyle: Codable {
    
    enum CodingKeys: String, CodingKey {
        
        case color
        case usesSystemSetting
    }
    
    
    init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let colorCode = try container.decode(String.self, forKey: .color)
        self.color = NSColor(colorCode: colorCode) ?? Theme.Style.invalidColor
        
        self.usesSystemSetting = try container.decodeIfPresent(Bool.self, forKey: .usesSystemSetting) ?? false
    }
    
    
    func encode(to encoder: Encoder) throws {
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(self.color.colorCode(type: .hex), forKey: .color)
        try container.encode(true, forKey: .usesSystemSetting)
    }
    
}
