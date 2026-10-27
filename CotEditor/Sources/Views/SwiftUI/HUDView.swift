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
//  © 2022-2026 1024jp
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
    
    /// Shows a HUD view as a child view.
    ///
    /// - Parameters:
    ///   - symbol: The symbol to display in the HUD.
    final func showHUD(symbol: HUDView.Symbol) {
        
        let hudView = NSHostingView(rootView: HUDView(symbol: symbol))
        hudView.rootView.onDismiss = { [weak hudView] in
            hudView?.removeFromSuperview()
        }
        hudView.sizingOptions = .preferredContentSize
        
        // remove previous HUD if any
        for case let subview as NSHostingView<HUDView> in self.subviews {
            subview.removeFromSuperview()
        }
        
        hudView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(hudView)
        
        NSLayoutConstraint.activate([
            hudView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            hudView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
        ])
    }
}


struct HUDView: View {
    
    enum Symbol {
        
        case wrap(flipped: Bool = false)
        case reachTop
        case reachBottom
    }
    
    
    var symbol: Symbol
    var onDismiss: () -> Void = { }
    
    @State private var isPresented = true
    
    
    /// The HUD symbol and background that fade out after a short delay.
    var body: some View {
        
        Image(systemName: self.symbol.systemName)
            .resizable()
            .scaledToFit()
            .frame(width: 72, height: 72)
            .scaleEffect(y: self.symbol.isFlipped ? -1 : 1)
            .padding(28)
            .foregroundStyle(.secondary)
            .background(.ultraThinMaterial, in: .rect(cornerRadius: 14, style: .continuous))
            .opacity(self.isPresented ? 1 : 0)
            .onAppear {
                withAnimation(.default.delay(0.5)) {
                    self.isPresented = false
                } completion: {
                    self.onDismiss()
                }
            }
    }
}


private extension HUDView.Symbol {
    
    /// The SF Symbol name for the HUD.
    var systemName: String {
        
        switch self {
            case .wrap: "arrow.triangle.capsulepath"
            case .reachTop: "arrow.up.to.line"
            case .reachBottom: "arrow.down.to.line"
        }
    }
    
    
    /// Whether the symbol is flipped vertically.
    var isFlipped: Bool {
        
        switch self {
            case .wrap(let flipped):
                flipped
            default:
                false
        }
    }
}


// MARK: - Preview

#Preview {
    HUDView(symbol: .wrap())
}
