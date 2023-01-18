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
//  © 2022-2023 1024jp
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
    let completionHandler: () -> Void
    
    
    // MARK: View
    
    var body: some View {
        
        VStack(spacing: 20) {
            CharacterCountOptionsView()
            
            HStack {
                HelpButton(anchor: "howto_count_characters")
                
                Spacer()
                
                SubmitButtonGroup("Start") {
                    self.completionHandler()
                    self.parent?.dismiss(nil)
                } cancelAction: {
                    self.parent?.dismiss(nil)
                }
            }
        }
        .fixedSize()
        .padding()
    }
}



// MARK: - Preview

struct CharacterCountOptionsSheetView_Previews: PreviewProvider {
    
    static var previews: some View {
        
        CharacterCountOptionsSheetView { }
    }
}
