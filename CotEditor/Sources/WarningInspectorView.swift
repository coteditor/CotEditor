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
    
    // MARK: Public Properties
    
    var document: Document {
        
        didSet {
            if self.isViewShown {
                self.model.document = document
            }
        }
    }
    
    
    // MARK: Private Properties
    
    private let model = WarningInspectorView.Model()
    
    
    
    // MARK: Lifecycle
    
    required init(document: Document) {
        
        self.document = document
        
        super.init(rootView: WarningInspectorView(model: self.model))
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        self.model.document = self.document
    }
    
    
    override func viewDidDisappear() {
        
        super.viewDidDisappear()
        
        self.model.document = nil
    }
}


struct WarningInspectorView: View {
    
    @MainActor final class Model: ObservableObject {
        
        var document: Document? {
            
            didSet {
                self.incompatibleCharactersModel.document = document
                self.inconsistentLineEndingsModel.document = document
            }
        }
        
        let incompatibleCharactersModel = IncompatibleCharactersView.Model()
        let inconsistentLineEndingsModel = InconsistentLineEndingsView.Model()
    }
    
    
    @ObservedObject var model: Model
    
    
    var body: some View {
        
        VSplitView {
            IncompatibleCharactersView(model: self.model.incompatibleCharactersModel)
                .padding(.bottom, 12)
            InconsistentLineEndingsView(model: self.model.inconsistentLineEndingsModel)
                .padding(.top, 8)
        }
        .padding(EdgeInsets(top: 8, leading: 12, bottom: 12, trailing: 12))
        .accessibilityLabel(Text("Warnings", tableName: "DocumentWindow"))
    }
}



// MARK: - Preview

@available(macOS 14, *)
#Preview(traits: .fixedLayout(width: 240, height: 300)) {
    WarningInspectorView(model: .init())
}
