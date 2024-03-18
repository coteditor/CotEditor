//
//  SyntaxMetadataEditView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2023-01-18.
//
//  ---------------------------------------------------------------------------
//
//  © 2023-2024 1024jp
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

struct SyntaxMetadataEditView: View {
    
    @Binding var metadata: SyntaxObject.Metadata
    
    
    // MARK: View
    
    var body: some View {
        
        Form {
            TextField(String(localized: "Version:", table: "SyntaxEditor", comment: "label"),
                      text: $metadata.version ?? "")
            TextField(String(localized: "Last Modified:", table: "SyntaxEditor", comment: "label"),
                      text: $metadata.lastModified ?? "")
            LabeledContent(String(localized: "Distribution URL:", table: "SyntaxEditor", comment: "label")) {
                InsetTextField(text: $metadata.distributionURL ?? "")
                    .inset(.trailing, 32)
                    .overlay(alignment: .trailing) {
                        LinkButton(url: self.metadata.distributionURL ?? "")
                            .foregroundStyle(.secondary)
                            .padding(.trailing, 4)
                    }
            }
            TextField(String(localized: "Author:", table: "SyntaxEditor", comment: "label"),
                      text: $metadata.author ?? "")
            TextField(String(localized: "License:", table: "SyntaxEditor", comment: "label"),
                      text: $metadata.license ?? "")
            TextField(String(localized: "Description:", table: "SyntaxEditor", comment: "label"),
                      text: $metadata.description ?? "", axis: .vertical)
                .lineLimit(5, reservesSpace: true)
        }
        Spacer()
        HStack {
            Spacer()
            HelpButton(anchor: "syntax_metadata_settings")
        }
    }
}



// MARK: - Preview

#Preview {
    SyntaxMetadataEditView(metadata: .constant(.init()))
        .padding()
}
