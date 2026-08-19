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
//  © 2023-2026 1024jp
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
import SyntaxFormat

struct SyntaxMetadataEditView: View {
    
    @Binding var metadata: SyntaxObject.Metadata
    
    
    // MARK: View
    
    var body: some View {
        
        Form {
            TextField(.init("Version:", table: "SyntaxEditor"),
                      text: $metadata.version ?? "")
            TextField(.init("Last Modified:", table: "SyntaxEditor"),
                      text: $metadata.lastModified ?? "")
            LabeledContent(.init("Distribution URL:", table: "SyntaxEditor")) {
                InsetTextField(text: $metadata.distributionURL ?? "")
                    .inset(.trailing, 32)
                    .overlay(alignment: .trailing) {
                        LinkButton(url: self.metadata.distributionURL ?? "")
                            .padding(.trailing, 4)
                    }
            }
            TextField(.init("Author:", table: "SyntaxEditor"),
                      text: $metadata.author ?? "")
            TextField(.init("License:", table: "SyntaxEditor"),
                      text: $metadata.license ?? "")
            TextField(.init("Description:", table: "SyntaxEditor"),
                      text: $metadata.description ?? "", axis: .vertical)
            .lineLimit(5, reservesSpace: true)
        }
        
        Spacer()
        HStack {
            Spacer()
            HelpLink(anchor: "syntax_metadata_settings")
        }
    }
}


// MARK: - Preview

#Preview {
    SyntaxMetadataEditView(metadata: .constant(.init()))
        .scenePadding()
}
