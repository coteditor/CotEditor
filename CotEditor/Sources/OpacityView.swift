//
//  OpacityView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2022-12-11.
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

@available(macOS, deprecated: 14)
@MainActor final class OpacityHostingView: NSHostingView<OpacityView> {
    
    convenience init(window: DocumentWindow?) {
        
        assert(window != nil)
        
        self.init(rootView: OpacityView(window: window))
        
        self.frame.size = self.intrinsicContentSize
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        
        // Implementing `init(coder:)` is required for toolbar item menu representation.
        
        let window = NSDocumentController.shared.currentDocument?.windowControllers.first?.window as? DocumentWindow
        assert(window != nil)
        
        super.init(rootView: OpacityView(window: window))
        
        self.frame.size = self.intrinsicContentSize
    }
    
    
    @MainActor required init(rootView: OpacityView) {
        
        super.init(rootView: rootView)
    }
}


struct OpacityView: View {
    
    weak var window: DocumentWindow?
    
    @State private var opacity: Double = 1
    
    
    var body: some View {
        
        VStack(alignment: .leading) {
            Text("Editor’s Opacity")
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            
            OpacitySlider(value: $opacity)
                .onChange(of: self.opacity) { newValue in
                    self.window?.backgroundAlpha = newValue
                }
                .controlSize(.small)
                .frame(width: 160)
        }
        .onAppear {
            if let window {
                self.opacity = window.backgroundAlpha
            }
        }
        .padding(10)
        .fixedSize()
    }
}



// MARK: - Preview

#Preview {
    OpacityView()
}
