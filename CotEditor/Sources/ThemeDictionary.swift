/*
 
 ThemeDictionary.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-03-15.
 
 ------------------------------------------------------------------------------
 
 © 2016 1024jp
 
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

//typealias ColorDefinition = [String: [String: Any]]
typealias ThemeDictionary = [String: NSMutableDictionary]  // use NSMutableDictionary for KVO

enum ThemeKey: String {
    
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
    
    /// sub-dictionary keys
    enum Sub: String {
        case color
        case usesSystemSetting
    }
    
    
    static let basicKeys: [ThemeKey] = [.text, .background, .invisibles, .selection, .insertionPoint, .lineHighlight]
    
    static let syntaxKeys: [ThemeKey] = [.keywords, .commands, .types, .attributes, .variables, .values, .numbers, .strings, .characters, .comments]
    static let all: [ThemeKey] = ThemeKey.basicKeys + ThemeKey.syntaxKeys + [.metadata]
    
}
