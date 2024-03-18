//
//  SnippetsSettingsView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-02-18.
//
//  ---------------------------------------------------------------------------
//
//  © 2024 1024jp
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

struct SnippetsSettingsView: View {
    
    var body: some View {
        
        VStack {
            TabView {
                VStack(alignment: .leading) {
                    Text("Text to be inserted by a command in the menu or by keyboard shortcut:", tableName: "SnippetsSettings")
                    CommandView()
                }
                .padding(EdgeInsets(top: 4, leading: 10, bottom: 10, trailing: 10))
                .tabItem { Text("Command", tableName: "SnippetsSettings", comment: "tab label") }
                
                VStack(alignment: .leading) {
                    Text("Text to be inserted by dropping files to the editor:", tableName: "SnippetsSettings")
                    FileDropView()
                }
                .padding(EdgeInsets(top: 4, leading: 10, bottom: 10, trailing: 10))
                .tabItem { Text("File Drop", tableName: "SnippetsSettings", comment: "tab label") }
            }.frame(height: 400)
            
            HStack {
                Spacer()
                HelpButton(anchor: "settings_snippets")
            }
        }
        .padding(.top, 10)
        .scenePadding([.horizontal, .bottom])
        .frame(width: 600)
    }
}


private struct CommandView: NSViewControllerRepresentable {
    
    typealias NSViewControllerType = NSViewController
    
    
    func makeNSViewController(context: Context) -> NSViewController {
        
        NSStoryboard(name: "SnippetsPane", bundle: nil).instantiateInitialController()!
    }
    
    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {
        
    }
}


private struct FileDropView: NSViewControllerRepresentable {
    
    typealias NSViewControllerType = NSViewController
    
    
    func makeNSViewController(context: Context) -> NSViewController {
        
        NSStoryboard(name: "SnippetsPane", bundle: nil).instantiateController(identifier: "FileDropView")
    }
    
    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {
        
    }
}



// MARK: - Preview

#Preview {
    SnippetsSettingsView()
}
