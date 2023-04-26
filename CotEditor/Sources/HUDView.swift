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

import AppKit
import SwiftUI

extension NSView {
    
    /// Show a HUD view as a chid view.
    ///
    /// - Parameters:
    ///   - symbol: The symbol to display in the HUD.
    func showHUD(symbol: HUDView.Symbol) {
        
        let hudView = NSHostingView(rootView: HUDView(symbol: symbol))
        hudView.rootView.parent = hudView
        hudView.translatesAutoresizingMaskIntoConstraints = false
        
        // remove previous HUD if any
        for subview in self.subviews where subview is NSHostingView<HUDView> {
            subview.removeFromSuperview()
        }
        
        self.addSubview(hudView)
        hudView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        hudView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        hudView.layout()
    }
}



struct HUDView: View {
    
    enum Symbol {
        
        case wrap(flipped: Bool = false)
        case reachTop
        case reachBottom
    }
    
    
    fileprivate weak var parent: NSHostingView<Self>?
    
    @State var symbol: Symbol
    @State private var isPresented = true
    
    
    var body: some View {
        
        if self.isPresented {
            Image(systemName: self.symbol.systemName)
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .scaleEffect(y: self.symbol.isFlipped ? -1 : 1)
                .padding(28)
                .foregroundColor(.secondary)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .onAppear {
                    withAnimation(.default.delay(0.5)) {
                        self.isPresented = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.parent?.removeFromSuperview()
                        }
                    }
                }
        }
    }
}


private extension HUDView.Symbol {
    
    var systemName: String {
        
        switch self {
            case .wrap:
                return "arrow.triangle.capsulepath"
            case .reachTop:
                return "arrow.up.to.line"
            case .reachBottom:
                return "arrow.down.to.line"
        }
    }
    
    
    var isFlipped: Bool {
        
        switch self {
            case .wrap(let flipped):
                return flipped
            default:
                return false
        }
    }
}



// MARK: - Preview

struct HUDView_Previews: PreviewProvider {
    
    static var previews: some View {
        
        HUDView(symbol: .wrap())
    }
}
