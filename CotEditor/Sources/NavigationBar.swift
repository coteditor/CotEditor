//
//  NavigationBar.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-02-04.
//
//  ---------------------------------------------------------------------------
//
//  © 2024 1024jp
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

struct NavigationBar: View {
    
    @State var outlineNavigator: OutlineNavigator
    @State var splitState: SplitState
    
    @State private var isOutlinePickerPresented = false
    
    
    var body: some View {
        
        HStack(alignment: .center, spacing: 6) {
            Group {
                Button(String(localized: "Close Split Editor", table: "Document", comment: "accessibility label for button"), systemImage: "xmark") {
                    NSApp.sendAction(#selector(DocumentViewController.closeSplitTextView), to: nil, from: nil)
                }
                .labelStyle(.iconOnly)
                .help(String(localized: "Close split editor", table: "Document", comment: "tooltip for button"))
                
                Divider()
                    .padding(.vertical, 4)
            }.opacity(self.splitState.canClose ? 1 : 0)
            
            if let items = self.outlineNavigator.items {
                if !items.isEmpty {
                    HStack(spacing: 0) {
                        if self.outlineNavigator.isVerticalOrientation {
                            self.nextButton(systemImage: "chevron.left")
                            self.previousButton(systemImage: "chevron.right")
                        } else {
                            self.previousButton(systemImage: "chevron.up")
                            self.nextButton(systemImage: "chevron.down")
                        }
                    }
                    
                    // Use AppKit-based picker (2024-05, macOS 14):
                    //   - To trim whitespaces of button display.
                    //   - To open programmatically.
                    OutlinePicker(items: items, selection: $outlineNavigator.selection, isPresented: $outlineNavigator.isOutlinePickerPresented) {
                        self.outlineNavigator.textView?.select(range: $0.range)
                    }
                }
            } else {
                Text("Extracting Outline…", tableName: "Document")
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button(String(localized: "Split Editor", table: "Document", comment: "accessibility label for button"), image: self.splitState.isVertical ? .splitAddVertical : .splitAdd) {
                NSApp.sendAction(#selector(DocumentViewController.openSplitTextView), to: nil, from: nil)
            }
            .labelStyle(.iconOnly)
            .help(String(localized: "Split editor", table: "Document", comment: "tooltip for button"))
            .contextMenu {
                Button {
                    NSApp.sendAction(#selector(SplitViewController.toggleSplitOrientation), to: nil, from: nil)
                } label: {
                    if self.splitState.isVertical {
                        Text("Stack Editors Horizontally", tableName: "MainMenu")
                    } else {
                        Text("Stack Editors Vertically", tableName: "MainMenu")
                    }
                }
            }
        }
        .buttonStyle(.borderless)
        .controlSize(.small)
        .padding(.horizontal, 6)
        .frame(height: 20)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(String(localized: "Navigation Bar", table: "Document", comment: "accessibility label"))
    }
    
    
    // MARK: Private Methods
    
    @ViewBuilder @MainActor private func previousButton(systemImage: String) -> some View {
        
        Button(String(localized: "Previous", table: "Document", comment: "accessibility label for button"), systemImage: systemImage) {
            self.outlineNavigator.selectPreviousItem()
        }
        .labelStyle(.iconOnly)
        .disabled(!self.outlineNavigator.canSelectPreviousItem)
        .help(String(localized: "Jump to previous outline item", table: "Document", comment: "tooltip for button"))
        .frame(width: 16)
        
    }
    
    
    @ViewBuilder @MainActor private func nextButton(systemImage: String) -> some View {
        
        Button(String(localized: "Next", table: "Document", comment: "accessibility label for button"), systemImage: systemImage) {
            self.outlineNavigator.selectNextItem()
        }
        .labelStyle(.iconOnly)
        .disabled(!self.outlineNavigator.canSelectNextItem)
        .help(String(localized: "Jump to next outline item", table: "Document", comment: "tooltip for button"))
        .frame(width: 16)
    }
}



// MARK: - Preview

#Preview {
    let navigator = OutlineNavigator()
    navigator.items = [.init(title: "Heading 1", range: .notFound)]
    
    return NavigationBar(outlineNavigator: navigator, splitState: SplitState(canClose: true))
        .frame(width: 300)
}
