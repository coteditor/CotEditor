//
//  OpenPanelAccessory.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-02-24.
//
//  ---------------------------------------------------------------------------
//
//  © 2018-2026 1024jp
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
import AppKit.NSOpenPanel
import FileEncoding

@Observable final class OpenPanelModel: NSObject, NSOpenSavePanelDelegate {
    
    var options: OpenOptions
    let fileEncodings: [FileEncoding?]
    
    fileprivate var selectsOnlyDirectories: Bool = false
    
    
    init(options: OpenOptions = .init(), fileEncodings: [FileEncoding?]) {
        
        self.options = options
        self.fileEncodings = fileEncodings
    }
    
    
    func panelSelectionDidChange(_ sender: Any?) {
        
        guard let panel = sender as? NSOpenPanel else { return }
        
        let urls = panel.urls
        self.selectsOnlyDirectories = !urls.isEmpty && urls.allSatisfy(\.hasDirectoryPath)
    }
}


struct OpenPanelAccessory: View {
    
    @State var model: OpenPanelModel
    weak var openPanel: NSOpenPanel?
    
    @State private var showsHiddenFiles = false
    
    
    // MARK: View
    
    var body: some View {
        
        VStack(alignment: .center) {
            Form {
                Picker(String(localized: "Text encoding:", table: "OpenPanelAccessory"), selection: $model.options.encoding) {
                    Text("Automatic", tableName: "OpenPanelAccessory", comment: "menu item title for automatic encoding detection")
                        .tag(String.Encoding?.none)
                    Divider()
                    
                    ForEach(self.model.fileEncodings.enumerated(), id: \.offset) { _, fileEncoding in
                        if let fileEncoding {
                            Text(fileEncoding.localizedName)
                                .tag(String.Encoding?.some(fileEncoding.encoding))
                        } else {
                            Divider()
                        }
                    }
                }
                .disabled(self.model.selectsOnlyDirectories)
                
                Toggle(String(localized: "Open as read-only", table: "OpenPanelAccessory", comment: "toggle button label"), isOn: $model.options.isReadOnly)
                    .disabled(self.model.selectsOnlyDirectories)
                    .onChange(of: self.model.selectsOnlyDirectories) { _, newValue in
                        if newValue {
                            self.model.options.isReadOnly = false
                        }
                    }
                
                Toggle(String(localized: "Show invisible files", table: "OpenPanelAccessory", comment: "toggle button label"), isOn: $showsHiddenFiles)
                    .onChange(of: self.showsHiddenFiles) { _, newValue in
                        guard let openPanel = self.openPanel else { return }
                        
                        openPanel.showsHiddenFiles = newValue
                        openPanel.treatsFilePackagesAsDirectories = newValue
                        openPanel.validateVisibleColumns()
                    }
            }
        }
        .padding()
    }
}


// MARK: - Preview

#Preview {
    @Previewable @State var model = OpenPanelModel(fileEncodings: [.utf8])
    
    OpenPanelAccessory(model: model)
}
