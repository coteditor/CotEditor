//
//  LinkButton.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2022-12-24.
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

struct LinkButton: View {
    
    let url: String
    
    @Environment(\.openURL) private var openURL
    
    
    var body: some View {
        
        Button {
            guard let url = URL(string: self.url) else { return NSSound.beep() }
            self.openURL(url)
        } label: {
            Image(systemName: "arrow.forward")
                .symbolVariant(.circle)
                .contentShape(.focusEffect, Circle())
                .accessibilityLabel("Jump to URL")
        }
        .buttonStyle(.borderless)
        .disabled(self.url.isEmpty)
        .help("Jump to URL")
    }
}
