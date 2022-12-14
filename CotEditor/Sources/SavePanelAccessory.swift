//
//  SavePanelAccessory.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2022-12-11.
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

final class SaveOptions: ObservableObject {
    
    @Published var isExecutable = false
}


struct SavePanelAccessory: View {
    
    @ObservedObject var options: SaveOptions
    
    
    // MARK: View
    
    var body: some View {
        
        Toggle("Give execute permission", isOn: $options.isExecutable)
            .padding(10)
    }
}



// MARK: - Preview

struct SavePanelAccessory_Previews: PreviewProvider {
    
    static var previews: some View {
        
        SavePanelAccessory(options: SaveOptions())
    }
}
