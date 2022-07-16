//
//  CharacterCountOptionsSheetView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2022-07-12.
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

struct CharacterCountOptionsSheetView: View {
    
    weak var parent: NSHostingController<Self>?  // workaround presentationMode.dismiss() doesn't work
    var completionHandler: (Bool) -> Void
    
    
    var body: some View {
        
        VStack {
            CharacterCountOptionsView()
            
            HStack {
                Spacer()
                Button("Cancel") {
                    self.parent?.dismiss(nil)
                    self.completionHandler(false)
                }
                .keyboardShortcut(.cancelAction)
                Button("Start") {
                    self.parent?.dismiss(nil)
                    self.completionHandler(true)
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
    }
}
