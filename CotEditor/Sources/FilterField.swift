//
//  FilterField.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2022-02-03.
//
//  ---------------------------------------------------------------------------
//
//  © 2022 1024jp
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

final class FilterField: NSSearchField {
    
    // MARK: Private Properties
    
    private let image: NSImage = .init(named: "filter.chevron")!
    private var filteringImage: NSImage = .init(named: "filter.chevron-fill")!
    
    
    
    // MARK: Lifecycle
    
    required init?(coder: NSCoder) {
        
        super.init(coder: coder)
        
        if #available(macOS 12.0, *) {
            let configuration = NSImage.SymbolConfiguration(paletteColors: [.labelColor, .controlAccentColor])
            self.filteringImage = self.filteringImage.withSymbolConfiguration(configuration)!
        }
        self.validateImage()
        
        let searchMenu = NSMenu(title: "Recent Filters".localized)
        searchMenu.addItem(withTitle: "Recent Filters".localized, action: nil, keyEquivalent: "")
            .tag = NSSearchField.recentsTitleMenuItemTag
        searchMenu.addItem(withTitle: "", action: nil, keyEquivalent: "")
            .tag = NSSearchField.recentsMenuItemTag
        searchMenu.addItem(.separator())
        searchMenu.addItem(withTitle: "Clear Recent Filters".localized, action: nil, keyEquivalent: "")
            .tag = NSSearchField.clearRecentsMenuItemTag
        searchMenu.addItem(withTitle: "No Recent Filter".localized, action: nil, keyEquivalent: "")
            .tag = NSSearchField.noRecentsMenuItemTag
        self.searchMenuTemplate = searchMenu
    }
    
    
    
    // MARK: Text Field Methods
    
    override func draw(_ dirtyRect: NSRect) {
        
        // workaround to upate icon while typing
        super.draw(dirtyRect)
    }
    
    
    override func textDidChange(_ notification: Notification) {
        
        super.textDidChange(notification)
        
        self.validateImage()
    }
    
    
    override func sendAction(_ action: Selector?, to target: Any?) -> Bool {
        
        // invoked when the search string was set by selecting recent history menu
        defer {
            self.validateImage()
        }
        
        return super.sendAction(action, to: target)
    }
    
    
    
    // MARK: Private Methods
    
    private func validateImage() {
        
        guard let buttonCell = (self.cell as? NSSearchFieldCell)?.searchButtonCell else { return assertionFailure() }
        
        buttonCell.image = self.stringValue.isEmpty ? self.image : self.filteringImage
    }
    
}
