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
//  © 2018-2024 1024jp
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

final class OpenOptions: ObservableObject {
    
    @Published var encoding: String.Encoding?
}


struct OpenPanelAccessory: View {
    
    @ObservedObject var options: OpenOptions
    
    weak var openPanel: NSOpenPanel?
    let fileEncodings: [FileEncoding?]
    
    @State private var showsHiddenFiles = false
    
    
    // MARK: View
    
    var body: some View {
        
        VStack(alignment: .center) {
            Form {
                Picker("Text encoding:", selection: $options.encoding) {
                    Text("Automatic", comment: "menu item title for automatic encoding detection")
                        .tag(String.Encoding?.none)
                    Divider()
                    
                    ForEach(Array(self.fileEncodings.enumerated()), id: \.offset) { (_, fileEncoding) in
                        if let fileEncoding {
                            Text(fileEncoding.localizedName).tag(fileEncoding.encoding)
                        } else {
                            Divider()
                        }
                    }
                }
                
                Toggle("Show invisible files", isOn: $showsHiddenFiles)
                    .onChange(of: self.showsHiddenFiles) { shows in
                        guard let openPanel = self.openPanel else { return }
                        
                        openPanel.showsHiddenFiles = shows
                        openPanel.treatsFilePackagesAsDirectories = shows
                        openPanel.validateVisibleColumns()
                    }
            }.fixedSize()
        }.padding()
    }
}



// MARK: - Preview

#Preview {
    OpenPanelAccessory(options: .init(), fileEncodings: [.utf8])
}
