//
//  FindPanelFieldView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-06-26.
//
//  ---------------------------------------------------------------------------
//
//  © 2014-2025 1024jp
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
import Defaults
import RegexHighlighting
import TextFind

struct FindPanelFieldView: View {
    
    // -> Not used in code but need to reset focus
    @Environment(\.appearsActive) private var appearsActive
    
    @AppStorage(.findUsesRegularExpression) private var usesRegularExpression: Bool
    @AppStorage(.findIgnoresCase) private var ignoresCase: Bool
    @AppStorage(.findInSelection) private var inSelection: Bool
    @AppStorage(.findRegexUnescapesReplacementString) private var unescapesReplacementString: Bool
    @AppStorage(.findSearchesIncrementally) private var searchesIncrementally: Bool
    
    @State private var settings: TextFinderSettings = .shared
    @State private var result: FindResult?
    @State private var isFindStringValid = true
    @State private var isPressingShift = false
    @State private var isRegexReferencePresented = false
    @State private var isSettingsPresented = false
    
    @State private var scrollerThickness: Double = 0
    @State private var findMessageWidth: Double = 0
    @State private var replaceMessageWidth: Double = 0
    
    
    var body: some View {
        
        VStack {
            FindTextField(String(localized: "Find", table: "TextFind", comment: "placeholder"),
                          text: $settings.findString,
                          mode: .search,
                          isRegularExpression: self.usesRegularExpression,
                          trailingInset: self.findMessageWidth)
            {
                let action = self.isPressingShift
                    ? #selector((any TextFinderClient).matchPrevious)
                    : #selector((any TextFinderClient).matchNext)
                NSApp.sendAction(action, to: nil, from: nil)
            }
            .onModifierKeysChanged(mask: .shift) { _, new in self.isPressingShift = new.contains(.shift) }
            .overlay(alignment: .top) {
                HStack(alignment: .firstTextBaseline) {
                    HistoryMenu(String(localized: "Recent Searches", table: "TextFind", comment: "menu item header"),
                                defaultKey: .findHistory, systemImage: "magnifyingglass",
                                clearLabel: String(localized: "Clear Recent Searches", table: "TextFind", comment: "menu item label"),
                                value: $settings.findString)
                    Spacer()
                    FindPanelFieldAccessoryView(result: (self.result?.action == .find) ? self.result?.message : nil,
                                                text: $settings.findString)
                        .onGeometryChange(for: CGFloat.self, of: \.size.width) { self.findMessageWidth = $0 }
                }
                .padding(.trailing, self.scrollerThickness)
            }
            .help(String(localized: "Type the text to search for.", table: "TextFind", comment: "tooltip"))
            .frame(minHeight: 44)
            
            FindTextField(String(localized: "Replace with", table: "TextFind", comment: "placeholder"),
                          text: $settings.replacementString,
                          mode: .replacement(unescapes: self.unescapesReplacementString),
                          isRegularExpression: self.usesRegularExpression,
                          trailingInset: self.replaceMessageWidth)
            .overlay(alignment: .top) {
                HStack(alignment: .firstTextBaseline) {
                    HistoryMenu(String(localized: "Recent Replacements", table: "TextFind", comment: "menu item header"),
                                defaultKey: .replaceHistory, systemImage: "pencil",
                                clearLabel: String(localized: "Clear Recent Replacements", table: "TextFind", comment: "menu item label"),
                                value: $settings.replacementString)
                    Spacer()
                    FindPanelFieldAccessoryView(result: (self.result?.action == .replace) ? self.result?.message : nil,
                                                text: $settings.replacementString)
                        .onGeometryChange(for: CGFloat.self, of: \.size.width) { self.replaceMessageWidth = $0 }
                }
                .padding(.trailing, self.scrollerThickness)
            }
            .help(String(localized: "Type the text to replace the found text.", table: "TextFind", comment: "tooltip"))
            .frame(minHeight: 44)
            
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Toggle(String(localized: "Regular Expression", table: "TextFind", comment: "toggle button label"), isOn: $usesRegularExpression)
                        .help(String(localized: "Select to search with regular expression.", table: "TextFind", comment: "tooltip"))
                        .fixedSize()
                    HelpLink {
                        self.isRegexReferencePresented.toggle()
                    }
                    .help(String(localized: "Show quick reference for regular expression syntax.", table: "TextFind", comment: "tooltip"))
                    .detachablePopover(isPresented: $isRegexReferencePresented, arrowEdge: .bottom) {
                        RegularExpressionReferenceView()
                    }
                    .controlSize(.mini)
                }
                Toggle(String(localized: "Ignore Case", table: "TextFind", comment: "toggle button label"), isOn: $ignoresCase)
                    .help(String(localized: "Select to ignore character case on search.", table: "TextFind", comment: "tooltip"))
                    .fixedSize()
                Toggle(String(localized: "In Selection", table: "TextFind", comment: "toggle button label"), isOn: $inSelection)
                    .help(String(localized: "Select to search text only from selection.", table: "TextFind", comment: "tooltip"))
                    .fixedSize()
                
                Spacer()
                
                Button(String(localized: "Advanced options", table: "TextFind", comment: "accessibility label"), systemImage: "ellipsis") {
                    self.isSettingsPresented.toggle()
                }
                .popover(isPresented: $isSettingsPresented, arrowEdge: .trailing) {
                    FindSettingsView()
                }
                .symbolVariant(.circle)
                .labelStyle(.iconOnly)
                .help(String(localized: "Show advanced options", table: "TextFind", comment: "tooltip"))
            }
            .controlSize(.small)
        }
        .onAppear {
            self.invalidateScrollerThickness()
        }
        .onChange(of: self.settings.findString) { _, newValue in
            self.result = nil
            
            // perform incremental search
            if self.searchesIncrementally,
               !self.inSelection,
               !newValue.isEmpty,
               !self.usesRegularExpression || (try? NSRegularExpression(pattern: newValue)) != nil
            {
                NSApp.sendAction(#selector((any TextFinderClient).incrementalSearch), to: nil, from: nil)
            }
        }
        .onChange(of: self.settings.replacementString) {
            self.result = nil
        }
        .task {
            for await notification in NotificationCenter.default.notifications(named: TextFinder.DidFindMessage.name) {
                self.result = notification.userInfo?["result"] as? FindResult
            }
        }
        .task {
            for await _ in NotificationCenter.default.notifications(named: NSWindow.didResignMainNotification) {
                self.result = nil
            }
        }
        .task {
            for await _ in NotificationCenter.default.notifications(named: NSScroller.preferredScrollerStyleDidChangeNotification) {
                self.invalidateScrollerThickness()
            }
        }
        .scenePadding([.top, .horizontal])
        .padding(.bottom, 8)
    }
    
    
    /// Updates the scroller thickness preserving for the Clear button padding.
    private func invalidateScrollerThickness() {
        
        self.scrollerThickness = NSScroller.preferredScrollerStyle == .legacy ? NSScroller.scrollerWidth(for: .small, scrollerStyle: NSScroller.preferredScrollerStyle) : 0
    }
}


private struct FindPanelFieldAccessoryView: View {
    
    var result: String?
    @Binding var text: String
    
    
    var body: some View {
        
        if !self.text.isEmpty {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                if let result {
                    Text(result)
                        .monospacedDigit()
                        .padding(.horizontal, 2)
                        .foregroundStyle(.tertiary)
                        .background(.background)
                        .clipShape(.rect(cornerRadius: 2))
                }
                
                Button(String(localized: "Clear", table: "TextFind", comment: "button label"), systemImage: "xmark") {
                    self.text = ""
                }
                .symbolVariant(.circle.fill)
                .buttonStyle(.borderless)
                .labelStyle(.iconOnly)
            }
            .controlSize(.small)
            .padding(5)
        }
    }
}


private struct HistoryMenu: View {
    
    var defaultKey: DefaultKey<[String]>
    
    var label: String
    var systemImage: String
    var clearLabel: String
    
    @Binding var value: String
    
    
    init(_ label: String, defaultKey: DefaultKey<[String]>, systemImage: String, clearLabel: String, value: Binding<String>) {
        
        self.defaultKey = defaultKey
        self.label = label
        self.systemImage = systemImage
        self.clearLabel = clearLabel
        self._value = value
    }
    
    
    var body: some View {
        
        Menu {
            let histories = UserDefaults.standard[self.defaultKey]
            
            if !histories.isEmpty {
                Section(self.label) {
                    ForEach(histories, id: \.self) { string in
                        let title = (string.count <= 64) ? string : (String(string.prefix(64)) + "…")
                        
                        Button(title) {
                            self.value = string
                        }.help(string)
                    }
                }
            }
            Button(self.clearLabel, systemImage: "trash") {
                UserDefaults.standard.removeObject(forKey: self.defaultKey.rawValue)
            }.disabled(histories.isEmpty)
        } label: {
            Label(self.label, systemImage: self.systemImage)
                .labelStyle(.iconOnly)
        }
        .buttonStyle(.borderless)
        .frame(minWidth: 34)
        .padding(.vertical, 5)
        .padding(.horizontal, 3)
    }
}


private struct FindTextField: NSViewRepresentable {
    
    typealias NSViewType = NSScrollView
    typealias TextView = RegexTextView
    
    
    var prompt: String
    @Binding var text: String
    @MainActor var action: (() -> Void)?
    
    var mode: RegexParseMode = .search
    var isRegularExpression: Bool = false
    var trailingInset: Double = 0
    
    @Environment(\.layoutDirection) private var layoutDirection
    
    
    init(_ prompt: String, text: Binding<String>, mode: RegexParseMode, isRegularExpression: Bool, trailingInset: Double, action: (@MainActor () -> Void)? = nil) {
        
        self.prompt = prompt
        self._text = text
        self.mode = mode
        self.isRegularExpression = isRegularExpression
        self.trailingInset = trailingInset
        self.action = action
    }
    
    
    func makeNSView(context: Context) -> NSScrollView {
        
        let textView = FindPanelTextView()
        textView.allowsUndo = true
        textView.delegate = context.coordinator
        textView.setValue(self.prompt, forKey: "placeholderString")  // private property in NSTextView
        textView.action = self.action
        
        let scrollView = SynchronizedScrollView()
        scrollView.contentView = FindPanelTextClipView()
        scrollView.documentView = textView
        scrollView.allowsMagnification = true
        scrollView.borderType = .lineBorder
        scrollView.focusRingType = .exterior
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.verticalScroller?.controlSize = .small
        scrollView.horizontalScroller?.controlSize = .small
        scrollView.contentView.automaticallyAdjustsContentInsets = false
        
        return scrollView
    }
    
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        
        let textView = nsView.documentView as! TextView
        textView.string = self.text
        textView.parseMode = self.mode
        textView.isRegularExpressionMode = self.isRegularExpression
        
        // add extra scroll margin to the trailing side of the textView, so that the entire input can be read
        let leadingKeyPath = (self.layoutDirection == .rightToLeft) ? \NSEdgeInsets.left : \.right
        nsView.contentView.contentInsets[keyPath: leadingKeyPath] = self.trailingInset
        
        if case .search = self.mode {
            // make find text view the initial first responder to focus it on showWindow(_:)
            textView.window?.initialFirstResponder = textView
        }
    }
    
    
    func makeCoordinator() -> Coordinator {
        
        Coordinator(text: $text)
    }
    
    
    final class Coordinator: NSObject, NSTextViewDelegate {
        
        @Binding private var text: String
        
        
        init(text: Binding<String>) {
            
            self._text = text
        }
        
        
        func textDidChange(_ notification: Notification) {
            
            guard
                let textView = notification.object as? TextView,
                !textView.hasMarkedText()
            else { return }
            
            self.text = textView.string
        }
    }
}


// MARK: - Preview

#Preview(traits: .fixedLayout(width: 400, height: 200)) {
    FindPanelFieldView()
}
