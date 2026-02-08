//
//  SyntaxBuiltInView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-01-28.
//
//  ---------------------------------------------------------------------------
//
//  © 2026 1024jp
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

struct SyntaxBuiltInView: View {
    
    var body: some View {
        
        VStack {
            ContentUnavailableView {
                Label {
                    Text("Managed by the app", tableName: "SyntaxEditor")
                        .font(.system(size: 18))
                        .fontWeight(.semibold)
                } icon: {
                    Image(systemName: "pencil.slash")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 64)
                }
                
            } description: {
                Text(String(localized: "SyntaxBuiltInView.description", defaultValue: "This language uses a structure-based, general-purpose parser called tree-sitter for syntax analysis.\nBecause the extraction rules are managed by the app, you can’t customize them.", table: "SyntaxEditor"))
            }
        }
        .frame(maxHeight: .infinity, alignment: .center)
    }
}


// MARK: - Preview

#Preview {
    SyntaxBuiltInView()
        .padding()
}
