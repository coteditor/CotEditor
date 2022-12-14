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

import SwiftUI
import AppKit


struct HelpButton: NSViewRepresentable {
    
    typealias NSViewType = NSButton
    
    let anchor: String
    
    
    func makeNSView(context: Context) -> NSButton {
        
        let nsView = NSButton(title: "", target: nil, action: #selector(AppDelegate.openHelpAnchor))
        nsView.bezelStyle = .helpButton
        nsView.identifier = .init(self.anchor)
        return nsView
    }
    
    
    func updateNSView(_ nsView: NSButton, context: Context) { }
}
