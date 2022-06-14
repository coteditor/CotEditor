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

struct HelpButton: View {
    
    var anchor: String
    
    private let bookName = Bundle.main.object(forInfoDictionaryKey: "CFBundleHelpBookName") as! String
    
    
    var body: some View {
        
        Button {
            NSHelpManager.shared.openHelpAnchor(self.anchor, inBook: self.bookName)
            
        } label: {
            ZStack {
                Circle()
                    .fill(Color(NSColor.controlColor))
                    .shadow(color: Color(NSColor.shadowColor).opacity(0.3), radius: 0.8, y: 0.5)
                    .frame(width: 20, height: 20)
                Text("?").font(.system(size: 16))
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
}



// MARK: - Preview

struct HelpButton_Previews: PreviewProvider {
    
    static var previews: some View {
        
        HelpButton(anchor: "moof")
    }
    
}
