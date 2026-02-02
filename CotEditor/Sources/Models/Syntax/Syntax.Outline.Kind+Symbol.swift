//
//  Syntax.Outline.Kind+Symbol.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-01-27.
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
import AppKit
import Syntax

extension Syntax.Outline.Kind {
    
    /// Returns a SwiftUI view representing the kind as an SF Symbol.
    ///
    /// - Parameters:
    ///   - mode: The symbol rendering mode to apply.
    /// - Returns: A view that renders the symbol.
    func icon(mode: SymbolRenderingMode = .hierarchical) -> some View {
        
        self.symbol.image
            .symbolVariant(self == .separator ? .none : .square.fill)
            .symbolRenderingMode(mode)
            .foregroundStyle(Color(nsColor: self.color))
    }
    
    
    /// Produces an AppKit `NSImage` for the kind symbol.
    var iconImage: NSImage {
        
        self.symbol.nsImage(variant: self == .separator ? "" : ".square.fill",
                            accessibilityDescription: self.label)!
            .withSymbolConfiguration(.init(hierarchicalColor: self.color))!
    }
}


private extension Syntax.Outline.Kind {
    
    /// The color for the symbol.
    var color: NSColor {
        
        switch self {
            case .container: .systemBlue
            case .value: .systemGreen
            case .function: .systemOrange
            case .heading: .systemBrown
            case .mark: .systemRed
            case .reference: .systemPurple
            case .separator: .systemGray
        }
    }
    
    
    /// The base symbol used to represent the kind.
    var symbol: SymbolResource {
        
        switch self {
            case .container: .system("chevron.forward")
            case .value: .system("v")
            case .function: .system("f")
            case .heading: .resource(.listBulletSquareFill)
            case .mark: .system("flag")
            case .reference: .system("arrow.uturn.backward")
            case .separator: .system("minus")
        }
    }
}


// MARK: -

#Preview {
    VStack(alignment: .leading) {
        ForEach(Syntax.Outline.Kind.allCases, id: \.self) { kind in
            Label {
                Text(kind.label)
            } icon: {
                kind.icon()
            }
        }
    }
    .scenePadding()
}
