//
//  HUDView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2022-07-22.
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

struct HUDView: View {
    
    enum Symbol {
        
        case wrap
    }
    
    
    weak var parent: NSHostingView<Self>?  // workaround presentationMode.dismiss() doesn't work
    
    @State var symbol: Symbol
    @State var flipped = false
    @State var isPresented = true
    
    
    var body: some View {
        
        if self.isPresented {
            Image(systemName: self.symbol.imageName)
                .resizable()
                .scaledToFit()
                .foregroundColor(.secondaryLabel)
                .frame(width: 72, height: 72)
                .scaleEffect(y: self.flipped ? -1 : 1)
                .padding(28)
                .background(.ultraThinMaterial)
                .cornerRadius(14)
                .onAppear(perform: {
                    withAnimation(.default.delay(0.5)) {
                        self.isPresented = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.parent?.removeFromSuperview()
                        }
                    }
                })
        }
    }
}


private extension HUDView.Symbol {
    
    var imageName: String {
        
        switch self {
            case .wrap:
                return "arrow.triangle.capsulepath"
        }
    }
    
}
