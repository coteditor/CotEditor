//
//  OutlinePicker.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2020-08-16.
//
//  ---------------------------------------------------------------------------
//
//  © 2020-2026 1024jp
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
import StringUtils
import Syntax

struct OutlinePicker: NSViewRepresentable {
    
    typealias NSViewType = NSPopUpButton
    
    var items: [OutlineItem]
    @Binding var selection: OutlineItem.ID?
    @Binding var isPresented: Bool
    var onSelect: (OutlineItem) -> Void
    
    
    func makeNSView(context: Context) -> NSPopUpButton {
        
        let button = NSPopUpButton()
        button.cell = OutlinePopUpButtonCell()
        button.controlSize = .small
        button.isBordered = false
        
        return button
    }
    
    
    func updateNSView(_ nsView: NSPopUpButton, context: Context) {
        
        let fontSize = NSFont.systemFontSize(for: nsView.controlSize)
        let font = nsView.font?.withSize(fontSize) ?? .menuFont(ofSize: fontSize)
        nsView.menu?.items = self.items.map { item in
            if item.isSeparator {
                return .separator()
            } else {
                let menuItem = NSMenuItem()
                menuItem.target = context.coordinator
                menuItem.action = #selector(Coordinator.itemSelected)
                menuItem.representedObject = item
                menuItem.attributedTitle = item.attributedTitle(font: font)
                menuItem.indentationLevel = if case .level(let level) = item.indent { level } else { 0 }
                return menuItem
            }
        }
        
        if let index = self.items.firstIndex(where: { $0.id == self.selection }) {
            nsView.selectItem(at: index)
        }
        
        if self.isPresented {
            nsView.menu?.popUp(positioning: nil, at: .zero, in: nsView)
            self.isPresented = false
        }
    }
    
    
    func makeCoordinator() -> Coordinator {
        
        Coordinator(selection: $selection, onSelect: self.onSelect)
    }
    
    
    func sizeThatFits(_ proposal: ProposedViewSize, nsView: NSPopUpButton, context: Context) -> CGSize? {
        
        var size = proposal.replacingUnspecifiedDimensions()
        
        guard let menuItemTitle = nsView.selectedItem?.attributedTitle else { return size }
        
        // trim indent width
        var width = nsView.intrinsicContentSize.width
        width -= menuItemTitle.size().width - nsView.attributedTitle.size().width
        width += 4  // for aesthetic margin
        size.width = min(width, size.width)
        
        return size
    }
    
    
    final class Coordinator: NSObject {
        
        @Binding var selection: OutlineItem.ID?
        var onSelect: (OutlineItem) -> Void
        
        
        init(selection: Binding<OutlineItem.ID?>, onSelect: @escaping (OutlineItem) -> Void) {
            
            self._selection = selection
            self.onSelect = onSelect
        }
        
        
        @objc func itemSelected(_ sender: NSMenuItem) {
            
            let item = sender.representedObject as! OutlineItem
            
            self.selection = item.id
            self.onSelect(item)
        }
    }
}


private final class OutlinePopUpButtonCell: NSPopUpButtonCell {
    
    override var attributedTitle: NSAttributedString {
        
        get {
            let title = super.attributedTitle
            let indentRange = (title.string as NSString).range(of: "^\\s+", options: .regularExpression)
            
            return indentRange.isEmpty
                ? title
                : title.attributedSubstring(from: NSRange(indentRange.upperBound..<title.length))
        }
        
        set {
            super.attributedTitle = newValue
        }
    }
}


@MainActor private extension OutlineItem {
    
    /// Returns the attributed title for the outline picker menu item.
    ///
    /// - Parameters:
    ///   - font: The font for text.
    /// - Returns: The attributed title.
    func attributedTitle(font: NSFont) -> NSAttributedString {
        
        let indent = switch self.indent {
            case .level: ""
            case .string(let string): string
        }
        let title = NSMutableAttributedString(string: indent)
        
        if let kind = self.kind {
            title.append(.init(attachment: kind.cachedAttachment))
            title.append(NSAttributedString(string: " "))
        }
        
        title.append(.init(string: self.title, attributes: [.font: font]))
        title.applyFontTraits(self.style.fontTraits, range: title.range)
        
        return title
    }
}


@MainActor private extension Syntax.Outline.Kind {
    
    private static var cachedAttachments: [Self: NSTextAttachment] = [:]
    
    
    /// A shared attachment for the outline kind icon.
    var cachedAttachment: NSTextAttachment {
        
        if let cached = Self.cachedAttachments[self] {
            return cached
        }
        
        let attachment = NSTextAttachment()
        attachment.image = self.iconImage
        Self.cachedAttachments[self] = attachment
        
        return attachment
    }
}
