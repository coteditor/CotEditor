//
//  CommandBarView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2023-11-20.
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
import AppKit
import Observation
import Shortcut

struct CommandBarView: View {
    
    @Observable final class Model {
        
        var commands: [ActionCommand] = []
    }
    
    
    struct Candidate: Identifiable {
        
        var command: ActionCommand
        var matches: [ActionCommand.MatchedPath]
        var score: Int
        var id: UUID  { self.command.id }
    }
    
    
    @State var model: Model
    
    weak var parent: NSWindow?
    
    
    @State private var input: String = ""
    @State var candidates: [Candidate] = []
    
    @State private var selection: ActionCommand.ID?
    @FocusState private var focus: ActionCommand.ID?
    @AccessibilityFocusState private var accessibilityFocus: ActionCommand.ID?
    
    
    var body: some View {
        
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Image(systemName: "magnifyingglass")
                WindowDraggableTextField(String(localized: "Quick Actions", table: "CommandBar"), text: $input)
                    .onSubmit(self.perform)
                    .fontWeight(.light)
                    .textFieldStyle(.plain)
                    .accessibilityAddTraits(.isSearchField)
            }
            .font(.system(size: 20))
            .padding(12)
            
            if !self.candidates.isEmpty {
                Divider()
                ScrollView(.vertical) {
                    LazyVStack(spacing: 6) {
                        ForEach(self.candidates) { candidate in
                            ActionCommandView(command: candidate.command, matches: candidate.matches)
                                .selected(candidate.id == self.selection)
                                .focused($focus, equals: candidate.id)
                                .accessibilityFocused($accessibilityFocus, equals: candidate.id)
                                .id(candidate.id)
                                .onMouseDown {
                                    self.selection = candidate.id
                                } onMouseUp: { translation in
                                    if translation == .zero {
                                        self.perform()
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 10)  // workaround for FB16141979
                }
                .scrollPosition(id: $selection)
                .contentMargins(.vertical, 10, for: .scrollContent)
                .frame(maxHeight: 300)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .onChange(of: self.input) { (_, newValue) in
            self.candidates = self.model.commands
                .compactMap {
                    guard let result = $0.match(command: newValue) else { return nil }
                    return Candidate(command: $0, matches: result.result, score: result.score)
                }
                .sorted(using: SortDescriptor(\.score))
            self.selection = self.candidates.first?.id
            
            // post a VoiceOver announcement
            let announcement = String(localized: "\(self.candidates.count) commands found", table: "CommandBar",
                                      comment: "VoiceOver announcement for when incrementally updating the command search result.")
            AccessibilityNotification.Announcement(announcement).post()
        }
        .onKeyPress(.upArrow) {
            self.move(down: false) ? .handled : .ignored
        }
        .onKeyPress(.downArrow) {
            self.move(down: true) ? .handled : .ignored
        }
        .frame(width: 500)
    }
    
    
    /// Moves the selection to the next one, if any exists.
    ///
    /// - Parameter down: Whether move down or up the selection.
    /// - Returns: Whether the move action is performed.
    private func move(down: Bool) -> Bool {
        
        guard
            let index = self.candidates.firstIndex(where: { $0.id == self.selection }),
            let candidate = self.candidates[safe: index + (down ? 1 : -1)]
        else { return false }
        
        self.selection = candidate.id
        self.focus = candidate.id
        self.accessibilityFocus = candidate.id
        return true
    }
    
    
    /// Performs the selected command and closes the view.
    private func perform() {
        
        // first close the command bar and then take the action
        // so that the action is delivered to the correct (first) responder.
        self.parent?.close()
        
        if let command = self.candidates[id: self.selection]?.command {
            command.perform()
        }
    }
}


private struct ActionCommandView: View {
    
    @Environment(\.colorSchemeContrast) private var colorContrast
    
    var command: ActionCommand
    var matches: [ActionCommand.MatchedPath]
    
    var isSelected = false
    
    
    var body: some View {
        
        HStack {
            Image(systemName: self.command.kind.systemImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .font(.system(size: 23))
                .fontWeight(.light)
                .foregroundStyle(self.isSelected ? .primary : .secondary)
                .frame(width: 26, height: 22, alignment: .center)
                .accessibilityLabel(self.command.kind.label)
                .padding(.horizontal, 4)
            
            VStack(alignment: .leading) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    ForEach(Array(self.matches.enumerated()), id: \.offset) { (offset, match) in
                        if offset > 0 {
                            Image(systemName: "chevron.compact.right")
                                .foregroundStyle(.tertiary)
                        }
                        Text(self.attributed(match.string, in: match.ranges, font: .body))
                            .frame(minWidth: 20)
                            .layoutPriority((offset == 0) ? 10 : Double(offset))
                    }
                }
                .accessibilityElement(children: .combine)
                .foregroundStyle((self.isSelected && self.colorContrast == .standard) ? Color.selectedMenuItemText.opacity(0.8) : .primary)
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    ForEach(Array(self.command.paths.enumerated()), id: \.offset) { (offset, path) in
                        if offset > 0 {
                            Image(systemName: "chevron.compact.right")
                                .foregroundStyle(.tertiary)
                        }
                        Text(path)
                            .layoutPriority((offset == 0) ? 10 : Double(offset))
                    }
                }
                .accessibilityElement(children: .combine)
                .foregroundStyle(self.isSelected ? .primary : .secondary)
                .controlSize(.small)
            }
            
            Spacer()
            
            if let shortcut = self.command.shortcut {
                ShortcutView(shortcut)
                    .foregroundStyle(self.isSelected ? .primary : .secondary)
                    .layoutPriority(100)
            }
        }
        .lineLimit(1)
        .padding(.vertical, 4)
        .padding(.horizontal, 10)
        .contentShape(Rectangle())  // for clicking
        .foregroundStyle(self.isSelected ? Color.selectedMenuItemText : .primary)
        .background(self.isSelected ? Color.accentColor : .clear, in: .rect(cornerRadius: 6))
    }
    
    
    /// Sets the selecting state of the receiver.
    ///
    /// - Parameter selected: The selecting state to change.
    func selected(_ selected: Bool = true) -> Self {
        
        var view = self
        view.isSelected = selected
        return view
    }
    
    
    /// Returns an AttributedString by highlighting the given ranges by taking the view states into account.
    ///
    /// - Parameters:
    ///   - string: The base string to create the attributed string.
    ///   - ranges: The ranges for the given `string` to highlight.
    ///   - font: The base font.
    /// - Returns: An attributed string.
    private func attributed(_ string: String, in ranges: [Range<String.Index>], font: Font) -> sending AttributedString {
        
        let attributed = AttributedString(string)
        
        return ranges
            .compactMap { Range($0, in: attributed) }
            .reduce(into: attributed) { (string, range) in
                string[range].font = font.weight(.bold)
                string[range].foregroundColor = self.isSelected ? Color.selectedMenuItemText : nil
            }
    }
}


private extension ActionCommand.Kind {
    
    var systemImage: String {
        
        switch self {
            case .command: "filemenu.and.selection"
            case .script: "applescript.fill"
        }
    }
    
    
    var label: String {
        
        switch self {
            case .command: String(localized: "Command", table: "CommandBar", comment: "command type")
            case .script: String(localized: "Script", table: "CommandBar", comment: "command type")
        }
    }
}


private extension View {
    
    /// Performs actions when clicking the mouse on the view.
    ///
    /// - Parameters:
    ///   - onMouseDown: The action to perform when the mouse is down.
    ///   - onMouseUp: The action to perform when the mouse is up.
    func onMouseDown(_ onMouseDown: @escaping () -> Void, onMouseUp: @escaping (_ translation: CGSize) -> Void = { _ in }) -> some View {
        
        self.simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in onMouseDown() }
                .onEnded { onMouseUp($0.translation) }
        )
    }
}


private extension Color {
    
    static let selectedMenuItemText = Color(nsColor: .selectedMenuItemTextColor)
}


// MARK: - Preview

#Preview {
    let candidates: [CommandBarView.Candidate] = [
        .init(command: .init(kind: .command, title: "Enter Full Screen",
                             paths: ["View"],
                             shortcut: Shortcut("E", modifiers: .function),
                             action: #selector(NSResponder.yank)),
              matches: [.init(string: "Enter Full Screen", ranges: [])],
              score: 0),
        .init(command: .init(kind: .command, title: "Fortran",
                             paths: ["Format", "Syntax"],
                             action: #selector(NSResponder.yank)),
              matches: [
                .init(string: "Syntax", ranges: [Range(NSRange(0..<2), in: "Syntax")!]),
                .init(string: "Fortran", ranges: []),
              ],
              score: 0),
        .init(command: .init(kind: .script, title: "Run Script",
                             paths: ["Script"],
                             shortcut: Shortcut("R", modifiers: .command),
                             action: #selector(NSResponder.yank)),
              matches: [.init(string: "Run Script", ranges: [])],
              score: 0),
    ]
    
    return CommandBarView(model: .init(), candidates: candidates)
}


#Preview("Command View") {
    ActionCommandView(
        command: .init(kind: .command, title: "Swift",
                       paths: ["Format", "Syntax"],
                       shortcut: Shortcut("s", modifiers: [.command]),
                       action: #selector(NSResponder.yank)),
        matches: [.init(string: "Swift",
                        ranges: [Range(NSRange(1..<3), in: "Swift")!])],
        isSelected: true
    )
    .fixedSize(horizontal: false, vertical: true)
    .frame(width: 300)
    .padding(12)
}
