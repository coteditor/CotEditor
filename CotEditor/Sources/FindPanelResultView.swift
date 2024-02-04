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
//  © 2015-2024 1024jp
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

final class FindPanelResultViewController: NSHostingController<FindPanelResultView> {
    
    private let model = FindPanelResultView.Model()
    
    
    init() {
        
        super.init(rootView: FindPanelResultView(model: self.model))
    }
    
    
    @MainActor required dynamic init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    /// Sets new find matches.
    func setResult(_ result: TextFindAllResult, for client: NSTextView) {
        
        self.model.matches = result.matches
        self.model.findString = result.findString
        self.model.target = client
        
        self.rootView = FindPanelResultView(model: self.model)
    }
}


struct FindPanelResultView: View {
    
    typealias Match = TextFindAllResult.Match
    
    final class Model: ObservableObject {
        
        @Published var matches: [Match] = []
        @Published var findString: String = ""
        weak var target: NSTextView?
    }
    
    
    @ObservedObject var model: Model
    
    @State private var selection: Set<Match.ID> = []
    @State private var sortOrder = [KeyPathComparator(\Match.range.location)]
    
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
            
            Text("Find string: \(self.model.findString)")
                .scenePadding(.horizontal)
            
            Table(self.model.matches, selection: $selection, sortOrder: $sortOrder) {
                TableColumn("Line", value: \.range.location) {
                    Text(self.model.target?.lineNumber(at: $0.range.location) ?? 0, format: .number)
                        .monospacedDigit()
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.vertical, -2)
                }.width(ideal: 30, max: 64)
                
                TableColumn("Found String") {
                    Text(AttributedString($0.attributedLineString(offset: 16)))
                        .truncationMode(.tail)
                        .padding(.vertical, -2)
                }
            }
            .environment(\.defaultMinListRowHeight, 20)
            .tableStyle(.bordered)
            .border(Color(nsColor: .gridColor), width: 1)
            .padding(-1)
            .font(.system(size: self.fontSize))
            .copyable(self.model.matches
                .filter(with: self.selection)
                .map(\.attributedLineString.string))
            .onChange(of: self.selection) { newValue in
                // remove selection of previous data
                if newValue.count > 1 {
                    let ids = self.model.matches.map(\.id)
                    for id in newValue where !ids.contains(id) {
                        self.selection.remove(id)
                    }
                }
                
                guard newValue.count == 1 else { return }
                self.selectMatch(newValue.first)
            }
            .onChange(of: self.sortOrder) { newOrder in
                self.model.matches.sort(using: newOrder)
            }
            .onCommand(#selector(EditorTextView.biggerFont)) {
                self.fontSize += 1
            }
            .onCommand(#selector(EditorTextView.smallerFont)) {
                self.fontSize = max(self.fontSize - 1, NSFont.smallSystemFontSize)
            }
            .onCommand(#selector(EditorTextView.resetFont)) {
                UserDefaults.standard.restore(key: .findResultViewFontSize)
            }
        }
        .controlSize(.small)
        .padding(.top, 8)
        .frame(minHeight: 0)
        .accessibilityLabel("Find Result")
    }
    
    
    private var message: String {
        
        let documentName = self.model.target?.documentName ?? "Unknown"  // This should never be nil.
        
        return switch self.model.matches.count {
            case 0:  String(localized: "No strings found in “\(documentName).”")
            case 1:  String(localized: "Found one string in “\(documentName).”")
            default: String(localized: "Found \(self.model.matches.count) strings in “\(documentName).”")
        }
    }
    
    
    /// Selects the match in the target text view.
    ///
    /// - Parameter id: The identifier of the match to select.
    @MainActor private func selectMatch(_ id: Match.ID?) {
        
        // abandon if text becomes shorter than range to select
        guard
            let range = self.model.matches.first(where: { $0.id == id })?.range,
            let textView = self.model.target,
            textView.string.length >= range.upperBound
        else { return }
        
        textView.select(range: range)
        textView.showFindIndicator(for: range)
    }
}


private extension NSTextView {
    
    var documentName: String? {
        
        self.window?.windowController?.document?.displayName
    }
}


private extension TextFindAllResult.Match {
    
    func attributedLineString(offset: Int) -> NSAttributedString {
        
        self.attributedLineString.truncatedHead(until: self.lineLocation, offset: offset)
    }
}



// MARK: - Preview

#Preview {
    let model = FindPanelResultView.Model()
    model.matches = [
        .init(range: NSRange(12..<16), lineLocation: 12,
              attributedLineString: .init("Clarus says moof!")),
        .init(range: NSRange(64..<73), lineLocation: 64,
              attributedLineString: .init("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.")),
    ]
    model.findString = "Clarus"
    
    return FindPanelResultView(model: model)
}
