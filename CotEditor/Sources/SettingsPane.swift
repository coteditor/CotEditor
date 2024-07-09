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
//  © 2023-2024 1024jp
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

import SwiftUI
import AppKit.NSImage
import ControlUI
import Defaults

extension SettingsWindowController<SettingsPane> {
    
    static let shared = SettingsWindowController<SettingsPane>(lastPaneIdentifier: DefaultKeys.lastSettingsPaneIdentifier.rawValue)
}


enum SettingsPane: String, ControlUI.SettingsPane {
    
    case general
    case appearance
    case window
    case edit
    case mode
    case format
    case snippets
    case keyBindings
    case donation
    
    
    /// The localized label.
    var label: String {
        
        switch self {
            case .general:
                String(localized: "SettingsPane.general.label",
                       defaultValue: "General",
                       table: "Settings")
            case .appearance:
                String(localized: "SettingsPane.appearance.label",
                       defaultValue: "Appearance",
                       table: "Settings")
            case .window:
                String(localized: "SettingsPane.window.label",
                       defaultValue: "Window",
                       table: "Settings")
            case .edit:
                String(localized: "SettingsPane.edit.label",
                       defaultValue: "Edit",
                       table: "Settings")
            case .mode:
                String(localized: "SettingsPane.mode.label",
                       defaultValue: "Mode",
                       table: "Settings")
            case .format:
                String(localized: "SettingsPane.format.label",
                       defaultValue: "Format",
                       table: "Settings")
            case .snippets:
                String(localized: "SettingsPane.snippets.label",
                       defaultValue: "Snippets",
                       table: "Settings")
            case .keyBindings:
                String(localized: "SettingsPane.keyBindings.label",
                       defaultValue: "Key Bindings",
                       table: "Settings")
            case .donation:
                String(localized: "SettingsPane.donation.label",
                       defaultValue: "Donation",
                       table: "Settings")
        }
    }
    
    
    /// The image for tab item.
    var image: NSImage {
        
        let symbolName = switch self {
            case .general: "gearshape"
            case .appearance: "eyeglasses"
            case .window: "uiwindow.split.2x1"
            case .edit: "square.and.pencil"
            case .mode: "switch.2"
            case .format: "doc.text"
            case .snippets: "note.text"
            case .keyBindings: "keyboard"
            case .donation: "mug"
        }
        
        return NSImage(systemSymbolName: symbolName, accessibilityDescription: self.label)!
    }
    
    
    /// The content view.
    @MainActor var view: any View {
        
        switch self {
            case .general: GeneralSettingsView()
            case .appearance: AppearanceSettingsView()
            case .window: WindowSettingsView()
            case .edit: EditSettingsView()
            case .mode: ModeSettingsView()
            case .format: FormatSettingsView()
            case .snippets: SnippetsSettingsView()
            case .keyBindings: KeyBindingsSettingsView()
            case .donation: DonationSettingsView()
        }
    }
}
