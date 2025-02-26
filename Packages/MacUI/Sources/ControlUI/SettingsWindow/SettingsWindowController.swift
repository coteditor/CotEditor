//
//  SettingsWindowController.swift
//  ControlUI
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2023-01-23.
//
//  ---------------------------------------------------------------------------
//
//  © 2023-2025 1024jp
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
import SwiftUI

public final class SettingsWindowController<Pane: SettingsPane>: NSWindowController {
    
    // MARK: Lifecycle
    
    /// Instantiates a SettingsWindowController.
    ///
    /// - Parameter lastPaneIdentifier: The user default key to store the last opened pane.
    public init(lastPaneIdentifier: String) {
        
        let viewController = SettingsTabViewController(lastPaneIdentifier: lastPaneIdentifier)
        viewController.tabStyle = .toolbar
        viewController.canPropagateSelectedChildViewControllerTitle = false
        viewController.tabViewItems = Pane.allCases.map(\.tabViewItem)
        
        let window = SettingsWindow(contentViewController: viewController)
        window.styleMask = [.closable, .titled]
        
        super.init(window: window)
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: Public Methods
    
    /// Opens a specific pane.
    ///
    /// - Parameter pane: The pane to display.
    public func openPane(_ pane: Pane) {
        
        let index = Pane.allCases.firstIndex { $0.rawValue == pane.rawValue } as? Int ?? 0
        (self.contentViewController as? NSTabViewController)?.selectedTabViewItemIndex = index
        
        self.showWindow(nil)
    }
}
