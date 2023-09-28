//
//  HelpButton.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2022-06-13.
//
//  ---------------------------------------------------------------------------
//
//  © 2022 1024jp
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

struct HelpButton: NSViewRepresentable {
    
    typealias NSViewType = NSButton
    
    private var anchor: String?
    private var action: (() -> Void)?
    
    
    
    /// Initialize a help button to jump the specific anchor in the system help viewer.
    ///
    /// - Parameter anchor: The help anchor.
    init(anchor: String) {
        
        self.anchor = anchor
    }
    
    
    /// Initialize a help button to perform the action when clicked.
    ///
    /// - Parameter action: The action to perform.
    init(action: @escaping () -> Void) {
        
        self.action = action
    }
    
    
    func makeNSView(context: Context) -> NSButton {
        
        let nsView = NSButton(title: "", target: nil, action: nil)
        nsView.bezelStyle = .helpButton
        
        if let anchor {
            nsView.identifier = .init(anchor)
            nsView.action = #selector(AppDelegate.openHelpAnchor)
        } else if self.action != nil {
            nsView.target = context.coordinator
            nsView.action = #selector(Coordinator.performAction)
        }
        
        return nsView
    }
    
    
    func updateNSView(_ nsView: NSButton, context: Context) { }
    
    
    
    func makeCoordinator() -> Coordinator {
        
        Coordinator(action: self.action)
    }
    
    
    
    final class Coordinator: NSObject {
        
        var action: (() -> Void)?
        
        
        init(action: (() -> Void)?) {
            
            self.action = action
            
            super.init()
        }
        
        
        @objc func performAction(_ sender: NSButton) {
            
            self.action?()
        }
    }
}
