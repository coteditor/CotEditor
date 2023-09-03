//
//  FindPanelResultView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2015-01-04.
//
//  ---------------------------------------------------------------------------
//
//  © 2015-2023 1024jp
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

extension NSHostingController<FindPanelResultView> {
   
    /// Set new find matches.
    func setResult(_ result: TextFindAllResult, for client: NSTextView) {
        
        self.rootView = FindPanelResultView(matches: result.matches, findString: result.findString, target: client)
    }
}


extension FindPanelResultView {
    
    init() {
        
        self.init(matches: [], findString: "", target: nil)
    }
}


struct FindPanelResultView: View {
    
    typealias Match = TextFindAllResult.Match
    
    let matches: [Match]
    let findString: String
    weak var target: NSTextView?
    
    @State private var selected: Match.ID?
    
    @AppStorage(.findResultViewFontSize) private var fontSize: Double
    
    
    
    // MARK: View
    
    var body: some View {
        
        VStack(alignment: .leading) {
            HStack {
                Button {
                    NSApp.sendAction(#selector(FindPanelContentViewController.closeResultView), to: nil, from: nil)
                } label: {
                    Image(systemName: "chevron.up")
                        .fontWeight(.medium)
                        .imageScale(.small)
                }
                .accessibilityLabel("Close")
                .help("Close find result.")
                
                Text(self.message)
                    .fontWeight(.bold)
            }.scenePadding(.horizontal)
            
            Text("Find string: \(self.findString)")
                .scenePadding(.horizontal)
            
            Table(self.matches, selection: $selected) {
                TableColumn("Line") {
                    Text(self.target?.lineNumber(at: $0.range.location) ?? 0, format: .number)
                        .monospacedDigit()
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.vertical, -2)
                }.width(ideal: 30, max: 64)
                
                TableColumn("Found String") {
                    Text(AttributedString($0.attributedLineString))
                        .truncationMode(.tail)
                        .padding(.vertical, -2)
                }
            }
            .environment(\.defaultMinListRowHeight, 20)
            .tableStyle(.bordered)
            .border(Color(nsColor: .gridColor), width: 1)
            .padding(-1)
            .font(.system(size: self.fontSize))
            .onChange(of: self.selected) { newValue in
                guard let newValue else { return }
                self.selectMatch(newValue)
            }
            .onCommand(#selector(EditorTextView.biggerFont), perform: self.biggerFont)
            .onCommand(#selector(EditorTextView.smallerFont), perform: self.smallerFont)
            .onCommand(#selector(EditorTextView.resetFont), perform: self.resetFont)
        }
        .controlSize(.small)
        .padding(.top, 8)
        .frame(minHeight: 0)
        .accessibilityLabel("Find Result")
    }
    
    
    private var message: LocalizedStringKey {
        
        let documentName = (self.target?.window?.windowController?.document as? NSDocument)?.displayName ?? "Unknown"  // This should never be nil.
        
        return switch self.matches.count {
            case 0:  "No strings found in “\(documentName).”"
            case 1:  "Found one string in “\(documentName).”"
            default: "Found \(self.matches.count) strings in “\(documentName).”"
        }
    }
    
    
    /// Select the match in the target text view.
    ///
    /// - Parameter id: The identifier of the match to select.
    private func selectMatch(_ id: Match.ID) {
        
        // abandon if text becomes shorter than range to select
        guard
            let textView = self.target,
            let range = self.matches.first(where: { $0.id == id })?.range,
            textView.string.nsRange.upperBound >= range.upperBound
        else { return }
        
        textView.select(range: range)
        textView.showFindIndicator(for: range)
    }
    
    
    /// Increase result's font size.
    private func biggerFont() {
        
        self.fontSize += 1
    }
    
    
    /// Decrease result's font size.
    private func smallerFont() {
        
        guard self.fontSize > NSFont.smallSystemFontSize else { return }
        
        self.fontSize -= 1
    }
    
    
    /// Restore result's font size to default.
    private func resetFont() {
        
        UserDefaults.standard.restore(key: .findResultViewFontSize)
    }
}



// MARK: - Preview

#Preview {
    FindPanelResultView(
        matches: [
            .init(range: .notFound,
                  attributedLineString: .init("Clarus says moof!")),
            .init(range: .notFound,
                  attributedLineString: .init("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.")),
        ],
        findString: "Clarus"
    )
}
