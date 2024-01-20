//
//  SettingsWindowController.swift
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

import AppKit

final class SettingsWindowController: NSWindowController {
    
    // MARK: Lifecycle
    
    convenience init() {
        
        let viewController = SettingsTabViewController()
        viewController.tabStyle = .toolbar
        viewController.canPropagateSelectedChildViewControllerTitle = false
        viewController.tabViewItems = SettingsPane.allCases.map(\.tabViewItem)
        
        let window = SettingsWindow(contentViewController: viewController)
        window.styleMask = [.closable, .titled]
        window.hidesOnDeactivate = false
        
        self.init(window: window)
    }
    
    
    // MARK: Public Methods
    
    /// Opens a specific setting pane.
    ///
    /// - Parameter pane: The pane to display.
    func openPane(_ pane: SettingsPane) {
        
        let index = SettingsPane.allCases.firstIndex(of: pane) ?? 0
        (self.contentViewController as? NSTabViewController)?.selectedTabViewItemIndex = index
        
        self.showWindow(nil)
    }
}


// MARK: -

private extension SettingsPane {
    
    private enum ViewType {
        
        case storyboard(NSStoryboard.Name)
        case swiftUI
    }
    
    
    var tabViewItem: NSTabViewItem {
        
        let tabViewItem = NSTabViewItem(viewController: self.viewController)
        tabViewItem.label = self.label
        tabViewItem.image = NSImage(systemSymbolName: self.symbolName, accessibilityDescription: self.label)
        tabViewItem.identifier = self.rawValue
        
        return tabViewItem
    }
    
    
    private var viewController: NSViewController {
        
        switch self.viewType {
            case .storyboard(let name):
                NSStoryboard(name: name, bundle: nil).instantiateInitialController()!
                
            case .swiftUI:
                preconditionFailure()
        }
    }
    
    
    private var viewType: ViewType {
        
        switch self {
            case .general: .storyboard("GeneralPane")
            case .appearance: .storyboard("AppearancePane")
            case .window: .storyboard("WindowPane")
            case .edit: .storyboard("EditPane")
            case .format: .storyboard("FormatPane")
            case .snippets: .storyboard("SnippetsPane")
            case .keyBindings: .storyboard("KeyBindingsPane")
        }
    }
}
