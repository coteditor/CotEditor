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
    
    func icon(mode: SymbolRenderingMode) -> some View {
        
        Image(systemName: self.symbolName)
            .symbolVariant(.square.fill)
            .symbolRenderingMode(mode)
            .foregroundStyle(Color(nsColor: self.color))
            .accessibilityLabel(self.label)
    }
    
    
    var iconImage: NSImage {
        
        NSImage(systemSymbolName: self.symbolName + ".square.fill", accessibilityDescription: self.label)!
            .withSymbolConfiguration(.init(hierarchicalColor: self.color))!
    }
    
    
    private var color: NSColor {
        
        switch self {
            case .container: .systemBlue
            case .function: .systemOrange
            case .value: .systemGreen
            case .heading: .systemTeal
            case .mark: .systemRed
            case .reference: .systemPurple
            case .separator: .systemGray
        }
    }
    
    
    private var symbolName: String {
        
        switch self {
            case .container: "c"
            case .function: "f"
            case .value: "v"
            case .heading: "arrowtriangle.forward"
            case .mark: "dot"
            case .reference: "arrow.uturn.backward"
            case .separator: "minus"
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
                kind.icon(mode: .hierarchical)
            }
        }
    }
    .scenePadding()
}
