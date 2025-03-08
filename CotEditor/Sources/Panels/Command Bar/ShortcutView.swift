//
//  ShortcutView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2023-11-26.
//
//  ---------------------------------------------------------------------------
//
//  © 2023-2025 1024jp
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
import Shortcut

struct ShortcutView: View {
    
    @Environment(\.layoutDirection) private var layoutDirection
    
    private var shortcut: Shortcut
    
    
    init(_ shortcut: Shortcut) {
        
        self.shortcut = shortcut
    }
    
    
    var body: some View {
        
        HStack(alignment: .firstTextBaseline, spacing: 1) {
            ForEach(self.shortcut.modifierSymbolNames, id: \.self) {
                Image(systemName: $0)
            }
            
            Group {
                if let symbolName = self.shortcut.keyEquivalentSymbolName {
                    Image(systemName: symbolName)
                } else if self.shortcut.keyEquivalentSymbol.contains(/^F[0-9]+$/) {
                    Text(self.shortcut.keyEquivalentSymbol)
                        .controlSize(.small)
                } else {
                    Text(self.shortcut.keyEquivalentSymbol)
                }
            }
            .frame(minWidth: 14, alignment: .leading)
        }
        .environment(\.layoutDirection, .leftToRight)  // shortcut is always LTR
        .fontWeight(.medium)
        .imageScale(.small)
        .fixedSize()
        .frame(minWidth: self.layoutDirection == .rightToLeft ? 60 : nil, alignment: .leading)
    }
}


// MARK: - Preview

#Preview {
    VStack(alignment: .trailing, spacing: 6) {
        ShortcutView(Shortcut("s", modifiers: [.command, .shift])!)
        ShortcutView(Shortcut(".", modifiers: [.command])!)
        ShortcutView(Shortcut(.carriageReturn, modifiers: [.command]))
        ShortcutView(Shortcut(.tab, modifiers: [.control]))
        ShortcutView(Shortcut(.help, modifiers: [.command]))
        ShortcutView(Shortcut(.f10, modifiers: [.command]))
        ShortcutView(Shortcut("f", modifiers: [.function])!)
    }.padding()
}
