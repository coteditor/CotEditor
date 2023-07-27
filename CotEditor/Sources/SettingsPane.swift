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
    
    
    /// Localized label.
    var label: String {
        
        switch self {
            case .general: String(localized: "General")
            case .window: String(localized: "Window")
            case .appearance: String(localized: "Appearance")
            case .edit: String(localized: "Edit")
            case .format: String(localized: "Format")
            case .snippets: String(localized: "Snippets")
            case .keyBindings: String(localized: "Key Bindings")
            case .print: String(localized: "Print")
        }
    }
    
    
    /// Symbol image name.
    var symbolName: String {
        
        switch self {
            case .general: "gearshape"
            case .window: "uiwindow.split.2x1"
            case .appearance: "eyeglasses"
            case .edit: "square.and.pencil"
            case .format: "doc.text"
            case .snippets: "note.text"
            case .keyBindings: "keyboard"
            case .print: "printer"
        }
    }
}
