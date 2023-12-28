//
//  AdvancedCharacterCounterView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2021-05-27.
//
//  ---------------------------------------------------------------------------
//
//  © 2021-2023 1024jp
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

struct AdvancedCharacterCounterView: View {
    
    @StateObject var counter: AdvancedCharacterCounter
    let dismissAction: () -> Void
    
    @State private var isSettingPresented = false
    
    
    var body: some View {
        
        HStack(alignment: .firstTextBaseline) {
            if let count = self.count {
                let markdown: AttributedString = switch self.counter.setting.unit {
                    case .byte: .init(localized: "*\(count)* byte(s)", table: "Count", locale: .current,
                                      comment: "Counter for Advanced Character Count")
                    default:    .init(localized: "*\(count)* character(s)", table: "Count", locale: .current,
                                      comment: "Counter for Advanced Character Count")
                }
                let attributes = AttributeContainer
                    .font(.body.monospacedDigit().weight(.medium))
                    .foregroundColor(.label)
                let attributedCount = markdown
                    .replacingAttributes(AttributeContainer.inlinePresentationIntent(.emphasized), with: attributes)
                
                Text(attributedCount)
                    .foregroundStyle(.secondary)
                
            } else {
                Label("failed", systemImage: "exclamationmark.triangle")
                    .symbolVariant(.fill)
                    .symbolRenderingMode(.multicolor)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button {
                self.isSettingPresented.toggle()
            } label: {
                Image(systemName: "gearshape")
                    .symbolVariant(.fill)
                    .accessibilityLabel("Show options")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("Show options")
            .popover(isPresented: self.$isSettingPresented) {
                VStack {
                    CharacterCountOptionsView()
                    HelpButton(anchor: "howto_count_characters")
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }.padding()
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.regularMaterial)
        .cornerRadius(8)
        .shadow(radius: 4, y: 2)
        .onTapGesture { }  // avoid clicking through
        .contextMenu {
            if let count = self.count {
                Button("Copy") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(String(count), forType: .string)
                }
                Divider()
            }
            Button("Stop Count", action: self.dismissAction)
        }
    }
    
    
    private var count: Int? {
        
        guard let selectionCount = self.counter.selectionCount else { return nil }
        
        return (selectionCount > 0) ? selectionCount : self.counter.entireCount
    }
}



// MARK: - Preview

#Preview {
    AdvancedCharacterCounterView(counter: .init(textView: .init())) { }
}
