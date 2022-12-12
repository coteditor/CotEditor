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
//  © 2018-2022 1024jp
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
    
    let openPanel: NSOpenPanel
    let encodings: [String.Encoding?]
    
    @State private var showsHiddenFiles = false
    
    
    // MARK: View
    
    var body: some View {
        
        VStack(alignment: .center) {
            Form {
                Picker("Encoding:", selection: $options.encoding) {
                    Text("Automatic").tag(String.Encoding?.none)
                    Divider()
                    
                    ForEach(Array(self.encodings.indices), id: \.self) { index in
                        if let encoding = self.encodings[index] {
                            Text(String.localizedName(of: encoding)).tag(String.Encoding?.some(encoding))
                        } else {
                            Divider()
                        }
                    }
                }
                
                Toggle("Show hidden files", isOn: $showsHiddenFiles)
                    .onChange(of: self.showsHiddenFiles) { shows in
                        self.openPanel.showsHiddenFiles = shows
                        self.openPanel.treatsFilePackagesAsDirectories = shows
                        self.openPanel.validateVisibleColumns()
                    }
            }.fixedSize(horizontal: true, vertical: true)
        }.padding()
    }
    
}



// MARK: - Preview

struct OpenPanelAccessory_Previews: PreviewProvider {
    
    static var previews: some View {
        
        OpenPanelAccessory(options: .init(), openPanel: .init(), encodings: [.utf8])
    }
    
}
