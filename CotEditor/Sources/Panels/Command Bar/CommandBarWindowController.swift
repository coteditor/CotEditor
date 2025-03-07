//
//  CommandBarWindowController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2023-11-20.
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
import SwiftUI

final class CommandBarWindowController: NSWindowController {
    
    // MARK: Public Properties
    
    static let shared = CommandBarWindowController()
    
    
    // MARK: Private Properties
    
    private let model = CommandBarView.Model()
    
    
    // MARK: Lifecycle
    
    init() {
        
        let panel = CommandBarPanel(contentRect: .zero, styleMask: [.titled, .fullSizeContentView], backing: .buffered, defer: false)
        let hostingView = NSHostingView(rootView: CommandBarView(model: self.model, parent: panel))
        hostingView.safeAreaRegions = []
        
        panel.contentView = hostingView
        panel.title = String(localized: "Quick Actions", table: "CommandBar")  // for VoiceOver
        panel.animationBehavior = .utilityWindow
        panel.collectionBehavior.insert(.fullScreenAuxiliary)
        panel.isFloatingPanel = true
        panel.isMovableByWindowBackground = true
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.standardWindowButton(.closeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        
        panel.setContentSize(hostingView.intrinsicContentSize)
        panel.center()
        
        super.init(window: panel)
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func showWindow(_ sender: Any?) {
        
        // update action candidates
        // -> Needs to update before the bar becomes key window.
        if self.window?.isVisible != true {
            self.model.commands = NSApp.actionCommands
        }
        
        super.showWindow(sender)
    }
}


// MARK: - Private Classes

private final class CommandBarPanel: NSPanel {
    
    override func cancelOperation(_ sender: Any?) {
        
        // -> Needs to close manually when a panel does not have a close button.
        self.close()
    }
    
    
    override func resignKey() {
        
        super.resignKey()
        
        self.close()
    }
}
