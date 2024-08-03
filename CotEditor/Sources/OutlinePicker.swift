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
//  © 2020-2024 1024jp
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
        
        let font = (nsView.font ?? .systemFont(ofSize: 0)).withSize(NSFont.systemFontSize(for: nsView.controlSize))
        nsView.menu?.items = self.items.map { item in
            if item.isSeparator {
                return .separator()
            } else {
                let menuItem = NSMenuItem()
                menuItem.target = context.coordinator
                menuItem.action = #selector(Coordinator.itemSelected)
                menuItem.representedObject = item
                menuItem.attributedTitle = NSAttributedString(string: item.title, attributes: item.attributes(baseFont: font))
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
