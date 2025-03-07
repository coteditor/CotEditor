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
//  © 2015-2025 1024jp
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
import Defaults

final class FindPanelResultViewController: NSHostingController<FindPanelResultView> {
    
    private let model = FindPanelResultView.Model()
    
    
    init() {
        
        super.init(rootView: FindPanelResultView(model: self.model))
    }
    
    
    required dynamic init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    /// Sets new find matches.
    func setResult(_ result: TextFindAllResult, for client: NSTextView) {
        
        self.model.matches = result.matches
        self.model.findString = result.findString
        self.model.target = client
    }
}


struct FindPanelResultView: View {
    
    typealias Match = TextFindAllResult.Match
    
    @MainActor @Observable final class Model {
        
        var matches: [Match] = []
        var findString: String = ""
        weak var target: NSTextView?
    }
    
    
    @State var model: Model
    
    @State private var documentName: String?
    @State private var selection: Set<Match.ID> = []
    @State private var sortOrder = [KeyPathComparator(\Match.range.location)]
    
    @AppStorage(.findResultViewFontSize) private var fontSize: Double
    
    
    // MARK: View
    
    var body: some View {
        
        VStack(alignment: .leading) {
            HStack {
                Button(String(localized: "Close", table: "TextFind", comment: "button label"), systemImage: "chevron.up") {
                    NSApp.sendAction(#selector(FindPanelContentViewController.closeResultView), to: nil, from: nil)
                }
                .fontWeight(.medium)
                .imageScale(.small)
                .labelStyle(.iconOnly)
                .help(String(localized: "Close find result.", table: "TextFind", comment: "tooltip"))
                
                Text(self.message)
                    .fontWeight(.bold)
            }.scenePadding(.horizontal)
            
            Text("Find string: \(self.model.findString)", tableName: "TextFind")
                .scenePadding(.horizontal)
            
            Table(self.model.matches, selection: $selection, sortOrder: $sortOrder) {
                TableColumn(String(localized: "Line", table: "TextFind", comment: "table column header"), value: \.range.location) {
                    Text($0.lineNumber, format: .number)
                        .monospacedDigit()
                        .padding(.vertical, -2)
                }
                .width(ideal: 30, max: 64)
                .alignment(.trailing)
                
                TableColumn(String(localized: "Found String", table: "TextFind", comment: "table column header")) {
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
            .onChange(of: self.selection) { (_, newValue) in
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
            .onChange(of: self.sortOrder) { (_, newValue) in
                self.model.matches.sort(using: newValue)
            }
            .onChange(of: self.model.target, initial: true) { (_, newValue) in
                self.documentName = newValue?.documentName
            }
            .contextMenu {
                Menu(String(localized: "Text Size", table: "MainMenu")) {
                    Button(String(localized: "Bigger", table: "MainMenu"), action: self.biggerFont)
                    Button(String(localized: "Smaller", table: "MainMenu"), action: self.smallerFont)
                    Button(String(localized: "Reset to Default", table: "MainMenu"), action: self.resetFont)
                }
            }
            .onCommand(#selector((any TextSizeChanging).biggerFont), perform: self.biggerFont)
            .onCommand(#selector((any TextSizeChanging).smallerFont), perform: self.smallerFont)
            .onCommand(#selector((any TextSizeChanging).resetFont), perform: self.resetFont)
        }
        .controlSize(.small)
        .padding(.top, 8)
        .frame(minHeight: 0)
        .accessibilityLabel(String(localized: "Find Result", table: "TextFind", comment: "accessibility label"))
    }
    
    
    // MARK: Private Methods
    
    private var message: String {
        
        let documentName = self.documentName ?? "Unknown"  // This should never be nil.
        
        return self.model.matches.isEmpty
            ? String(localized: "No strings found in “\(documentName).”", table: "TextFind",
                     comment: "message in the Find All result view (“%@” is filename)")
            : String(localized: "Found \(self.model.matches.count) strings in “\(documentName).”", table: "TextFind",
                     comment: "message in the Find All result view (“%@” is filename)")
    }
    
    
    /// Selects the match in the target text view.
    ///
    /// - Parameter id: The identifier of the match to select.
    private func selectMatch(_ id: Match.ID?) {
        
        // abandon if text becomes shorter than range to select
        guard
            let range = self.model.matches[id: id]?.range,
            let textView = self.model.target,
            textView.string.length >= range.upperBound
        else { return }
        
        textView.select(range: range)
        textView.showFindIndicator(for: range)
    }
    
    
    /// Make the table's font size bigger.
    private func biggerFont() {
        
        self.fontSize += 1
    }
    
    
    /// Make the table's font size smaller.
    private func smallerFont() {
        
        self.fontSize = max(self.fontSize - 1, NSFont.smallSystemFontSize)
    }
    
    
    /// Resets the table's font size to the default.
    private func resetFont() {
        
        UserDefaults.standard.restore(key: .findResultViewFontSize)
    }
}


private extension NSTextView {
    
    var documentName: String? {
        
        (self.window?.windowController as? DocumentWindowController)?.fileDocument?.displayName
    }
}


private extension TextFindAllResult.Match {
    
    /// Returns the attributed string truncated from the head.
    ///
    /// - Parameter offset: The maximum number of composed characters to truncate.
    /// - Returns: An attributed string.
    func attributedLineString(offset: Int) -> NSAttributedString {
        
        self.attributedLineString.truncatedHead(until: self.inlineLocation, offset: offset)
    }
}


// MARK: - Preview

#Preview {
    let model = FindPanelResultView.Model()
    model.matches = [
        .init(range: NSRange(12..<16), lineNumber: 1, inlineLocation: 12,
              attributedLineString: .init("Clarus says moof!")),
        .init(range: NSRange(64..<73), lineNumber: 3, inlineLocation: 64,
              attributedLineString: .init("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.")),
    ]
    model.findString = "Clarus"
    
    return FindPanelResultView(model: model)
}
