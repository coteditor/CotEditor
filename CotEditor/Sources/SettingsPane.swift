//
//  SettingsPane.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2023-01-23.
//
//  ---------------------------------------------------------------------------
//
//  © 2023 1024jp
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

enum SettingsPane: String, CaseIterable {
    
    case general
    case window
    case appearance
    case edit
    case format
    case snippets
    case keyBindings
    case print
    
    
    var label: String {
        
        switch self {
            case .general:
                return "General"
            case .window:
                return "Window"
            case .appearance:
                return "Appearance"
            case .edit:
                return "Edit"
            case .format:
                return "Format"
            case .snippets:
                return "Snippets"
            case .keyBindings:
                return "Key Bindings"
            case .print:
                return "Print"
        }
    }
    
    
    var symbolName: String {
        
        switch self {
            case .general:
                return "gearshape"
            case .window:
                return "uiwindow.split.2x1"
            case .appearance:
                return "eyeglasses"
            case .edit:
                return "square.and.pencil"
            case .format:
                return "doc.text"
            case .snippets:
                return "note.text"
            case .keyBindings:
                return "keyboard"
            case .print:
                return "printer"
        }
    }
}
