//
//  ToolbarController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by nakamuxu on 2005-01-07.
//
//  ---------------------------------------------------------------------------
//
//  © 2004-2007 nakamuxu
//  © 2014-2020 1024jp
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

import Combine
import Cocoa

final class ToolbarController: NSObject {
    
    // MARK: Public Properties
    
    weak var document: Document? {
        
        willSet {
            self.documentStyleObserver = nil
        }
        
        didSet {
            guard let document = document else { return }
            
            self.toolbar?.validateVisibleItems()
            self.invalidateSyntaxStyleSelection()
            
            // observe document's style change
            self.documentStyleObserver = document.didChangeSyntaxStyle
                .receive(on: RunLoop.main)
                .sink { [weak self] _ in self?.invalidateSyntaxStyleSelection() }
        }
    }
    
    
    // MARK: Private Properties
    
    private var documentStyleObserver: AnyCancellable?
    private var styleListObserver: AnyCancellable?
    private var recentStyleNamesObserver: UserDefaultsObservation?
    
    @IBOutlet private weak var toolbar: NSToolbar?
    @IBOutlet private weak var shareToolbarItem: NSToolbarItem?
    @IBOutlet private weak var syntaxPopupButton: NSPopUpButton?
    
    
    
    // MARK: -
    // MARK: Object Methods
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        // setup Share toolbar item
        // -> The Share button action must be called on `mouseDown`.
        (self.shareToolbarItem!.view as! NSButton).sendAction(on: .leftMouseDown)
        self.shareToolbarItem!.menuFormRepresentation = NSDocumentController.shared.standardShareMenuItem()
        
        // setup syntax style menu
        self.buildSyntaxPopupButton()
        
        //  observe for syntax style line-up change
        self.styleListObserver = SyntaxManager.shared.didUpdateSettingList
            .sink { [weak self] _ in self?.buildSyntaxPopupButton() }
        self.recentStyleNamesObserver?.invalidate()
        self.recentStyleNamesObserver = UserDefaults.standard.observe(key: .recentStyleNames) { [weak self] _ in
            self?.buildSyntaxPopupButton()
        }
    }
    
    
    
    // MARK: Private Methods
    
    /// select item in the syntax style menu
    private func invalidateSyntaxStyleSelection() {
        
        guard let popUpButton = self.syntaxPopupButton else { return }
        guard let styleName = self.document?.syntaxParser.style.name else { return }
        
        popUpButton.selectItem(withTitle: styleName)
        if popUpButton.selectedItem == nil {
            popUpButton.selectItem(at: 0)  // select "None"
        }
    }
    
    
    /// build syntax style popup menu
    private func buildSyntaxPopupButton() {
        
        guard let menu = self.syntaxPopupButton?.menu else { return }
        
        let styleNames = SyntaxManager.shared.settingNames
        let recentStyleNames = UserDefaults.standard[.recentStyleNames]!
        let action = #selector(Document.changeSyntaxStyle)
        
        menu.removeAllItems()
        
        menu.addItem(withTitle: BundledStyleName.none, action: action, keyEquivalent: "")
        menu.addItem(.separator())
        
        if !recentStyleNames.isEmpty {
            let labelItem = NSMenuItem()
            labelItem.title = "Recently Used".localized(comment: "menu heading in syntax style list on toolbar popup")
            labelItem.isEnabled = false
            menu.addItem(labelItem)
            
            menu.items += recentStyleNames.map { NSMenuItem(title: $0, action: action, keyEquivalent: "") }
            menu.addItem(.separator())
        }
        
        menu.items += styleNames.map { NSMenuItem(title: $0, action: action, keyEquivalent: "") }
        
        self.invalidateSyntaxStyleSelection()
    }
    
}
