//
//  MultipleReplaceSplitView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2017-03-17.
//
//  ---------------------------------------------------------------------------
//
//  © 2017-2025 1024jp
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
import OSLog
import Defaults
import TextFind

struct MultipleReplaceSplitView: View {
    
    private let manager: ReplacementManager = .shared
    
    @AppStorage(.selectedMultipleReplaceSettingName) private var selection: String?
    @State private var setting: MultipleReplace = .init()
    @State private var error: (any Error)?
    
    
    var body: some View {
        
        NavigationSplitView {
            MultipleReplaceListView(selection: $selection, manager: self.manager)
                .environment(\.sidebarRowSize, .medium)
                .navigationSplitViewColumnWidth(min: 80, ideal: 200)
        } detail: {
            MultipleReplaceView(setting: $setting) {
                self.setting = $0
                self.saveSetting()
            }
        }
        .onChange(of: self.selection, initial: true) { _, newValue in
            guard let newValue else { return }
            self.changeSetting(to: newValue)
        }
        .task {
            let names = NotificationCenter.default
                .notifications(named: .didUpdateSettingNotification, object: self.manager)
                .compactMap { $0.userInfo?["change"] as? SettingChange }
                .compactMap(\.new)
            
            for await name in names where name == self.selection {
                self.changeSetting(to: name)
            }
        }
    }
    
    
    // MARK: Private Methods
    
    /// Saves the current setting as the current selected name.
    private func saveSetting() {
        
        guard let name = self.selection else { return }
        
        do {
            try self.manager.save(setting: self.setting, name: name)
        } catch {
            Logger.app.error("\(error.localizedDescription)")
        }
    }
    
    
    /// Changes the editor to the setting of the passed-in name.
    ///
    /// - Parameter name: The name of the setting.
    private func changeSetting(to name: String) {
        
        do {
            self.setting = try self.manager.setting(name: name)
        } catch {
            self.error = error
        }
    }
}
