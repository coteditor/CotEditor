//
//  WarningInspectorView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2022-04-11.
//
//  ---------------------------------------------------------------------------
//
//  © 2022-2024 1024jp
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

final class WarningInspectorViewController: NSHostingController<WarningInspectorView>, DocumentOwner {
    
    private let incompatibleCharactersModel: IncompatibleCharactersView.Model
    private let inconsistentLineEndingsModel: InconsistentLineEndingsView.Model
    
    
    // MARK: Public Properties
    
    var document: Document {
        
        didSet {
            self.incompatibleCharactersModel.document = self.document
            self.inconsistentLineEndingsModel.document = self.document
        }
    }
    
    
    // MARK: Lifecycle
    
    init(document: Document) {
        
        self.incompatibleCharactersModel = .init(document: document)
        self.inconsistentLineEndingsModel = .init(document: document)
        
        self.document = document
        
        super.init(rootView: WarningInspectorView(
            incompatibleCharactersModel: self.incompatibleCharactersModel,
            inconsistentLineEndingsModel: self.inconsistentLineEndingsModel)
        )
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        self.incompatibleCharactersModel.isAppeared = true
        self.inconsistentLineEndingsModel.isAppeared = true
    }
    
    
    override func viewDidDisappear() {
        
        super.viewDidDisappear()
        
        self.incompatibleCharactersModel.isAppeared = false
        self.inconsistentLineEndingsModel.isAppeared = false
    }
}


struct WarningInspectorView: View {
    
    @ObservedObject var incompatibleCharactersModel: IncompatibleCharactersView.Model
    @ObservedObject var inconsistentLineEndingsModel: InconsistentLineEndingsView.Model
    
    
    var body: some View {
        
        VSplitView {
            IncompatibleCharactersView(model: self.incompatibleCharactersModel)
                .padding(.top, 8)
                .padding(.bottom, 12)
            InconsistentLineEndingsView(model: self.inconsistentLineEndingsModel)
                .padding(.top, 8)
                .padding(.bottom, 12)
        }
        .padding(.horizontal, 12)
        .accessibilityLabel(Text("Warnings", tableName: "Inspector"))
    }
}



// MARK: - Preview

@available(macOS 14, *)
#Preview(traits: .fixedLayout(width: 240, height: 300)) {
    let document = Document()
    document.textStorage.replaceContent(with: "  \r \n \r")
    
    return WarningInspectorView(
        incompatibleCharactersModel: .init(document: document),
        inconsistentLineEndingsModel: .init(document: document)
    )
}
