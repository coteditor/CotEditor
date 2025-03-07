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
//  © 2024-2025 1024jp
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
import Syntax

struct NavigationBar: View {
    
    @State var outlineNavigator: OutlineNavigator
    @State var splitState: SplitState
    
    
    var body: some View {
        
        HStack(alignment: .center, spacing: 0) {
            Button {
                NSApp.sendAction(#selector(DocumentViewController.closeSplitTextView), to: nil, from: self.outlineNavigator.textView)
            } label: {
                Label(String(localized: "Close Split Editor", table: "Document", comment: "accessibility label for button"), systemImage: "xmark")
                    .frame(width: 18)
                    .frame(maxHeight: .infinity, alignment: .center)
            }
            .labelStyle(.iconOnly)
            .help(String(localized: "Close split editor", table: "Document", comment: "tooltip for button"))
            .symbolEffect(.disappear, isActive: !self.splitState.canClose)
            .accessibilityHidden(!self.splitState.canClose)
            
            Divider()
                .padding(.vertical, 4)
                .padding(.horizontal, 3)
                .opacity(self.splitState.canClose ? 1 : 0)
                .accessibilityHidden(!self.splitState.canClose)
            
            OutlineNavigationView(navigator: $outlineNavigator)
            
            Spacer()
            
            Button {
                NSApp.sendAction(#selector(DocumentViewController.openSplitTextView), to: nil, from: self.outlineNavigator.textView)
            } label: {
                Label(String(localized: "Split Editor", table: "Document", comment: "accessibility label for button"), image: .splitAdd)
                    .frame(width: 18)
                    .frame(maxHeight: .infinity, alignment: .center)
            }
            .rotationEffect(.degrees(self.splitState.isVertical ? -90 : 0))
            .labelStyle(.iconOnly)
            .help(String(localized: "Split editor", table: "Document", comment: "tooltip for button"))
            .contextMenu {
                Button {
                    NSApp.sendAction(#selector(DocumentViewController.toggleSplitOrientation), to: nil, from: nil)
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
        .padding(.horizontal, 2)
        .background(.windowBackground)
        .frame(height: 20)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(String(localized: "Navigation Bar", table: "Document", comment: "accessibility label"))
    }
}


private struct OutlineNavigationView: View {
    
    @Binding var navigator: OutlineNavigator
    
    @State private var isLongExtraction = false
    @State private var extractionDelayTask: Task<Void, any Error>?
    
    
    var body: some View {
        
        HStack {
            if let items = self.navigator.items {
                if !items.isEmpty {
                    HStack(spacing: 0) {
                        if self.navigator.isVerticalOrientation {
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
                    OutlinePicker(items: items, selection: $navigator.selection, isPresented: $navigator.isOutlinePickerPresented) {
                        self.navigator.textView?.select(range: $0.range)
                    }
                    .accessibilityLabel(String(localized: "Outline Menu", table: "Document", comment: "accessibility label"))
                }
            } else if self.isLongExtraction {
                Text("Extracting Outline…", tableName: "Document")
                    .foregroundStyle(.secondary)
            }
        }
        .onDisappear {
            self.extractionDelayTask?.cancel()
        }
        .onChange(of: self.navigator.items, initial: true) { (_, newValue) in
            // show message only when parse takes more than 1 second.
            self.extractionDelayTask?.cancel()
            if newValue == nil {
                self.extractionDelayTask = Task {
                    try await Task.sleep(for: .seconds(1))
                    self.isLongExtraction = true
                }
            } else {
                self.extractionDelayTask = nil
                self.isLongExtraction = false
            }
        }
    }
    
    
    // MARK: Private Methods
    
    @ViewBuilder private func previousButton(systemImage: String) -> some View {
        
        Button {
            self.navigator.selectPreviousItem()
        } label: {
            Label(String(localized: "Previous Outline Item", table: "Document", comment: "accessibility label for button"), systemImage: systemImage)
                .frame(width: 18)
                .frame(maxHeight: .infinity, alignment: .center)
        }
        .fontWeight(.medium)
        .labelStyle(.iconOnly)
        .disabled(!self.navigator.canSelectPreviousItem)
        .help(String(localized: "Jump to previous outline item", table: "Document", comment: "tooltip for button"))
    }
    
    
    @ViewBuilder private func nextButton(systemImage: String) -> some View {
        
        Button {
            self.navigator.selectNextItem()
        } label: {
            Label(String(localized: "Next Outline Item", table: "Document", comment: "accessibility label for button"), systemImage: systemImage)
                .frame(width: 18)
                .frame(maxHeight: .infinity, alignment: .center)
        }
        .fontWeight(.medium)
        .labelStyle(.iconOnly)
        .disabled(!self.navigator.canSelectNextItem)
        .help(String(localized: "Jump to next outline item", table: "Document", comment: "tooltip for button"))
    }
}


// MARK: - Preview

#Preview {
    let navigator = OutlineNavigator()
    navigator.items = [
        OutlineItem(title: "    Heading 1", range: .notFound),
        OutlineItem(title: "Heading 2", range: .notFound),
    ]
    
    return NavigationBar(outlineNavigator: navigator, splitState: SplitState(canClose: true))
        .frame(width: 300)
}
