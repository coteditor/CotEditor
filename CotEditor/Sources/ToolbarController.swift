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
            self.documentObservers.removeAll()
        }
        
        didSet {
            guard let document = document else { return }
            
            self.invalidateLineEndingSelection(to: document.lineEnding)
            self.invalidateEncodingSelection()
            self.invalidateSyntaxStyleSelection()
            self.toolbar?.validateVisibleItems()
            
            // observe document status change
            document.didChangeEncoding
                .receive(on: RunLoop.main)
                .sink { [weak self] _ in self?.invalidateEncodingSelection() }
                .store(in: &self.documentObservers)
            document.didChangeLineEnding
                .receive(on: RunLoop.main)
                .sink { [weak self] in self?.invalidateLineEndingSelection(to: $0) }
                .store(in: &self.documentObservers)
            document.didChangeSyntaxStyle
                .receive(on: RunLoop.main)
                .sink { [weak self] _ in self?.invalidateSyntaxStyleSelection() }
                .store(in: &self.documentObservers)
        }
    }
    
    
    // MARK: Private Properties
    
    private var documentObservers: Set<AnyCancellable> = []
    private var menuUpdateObservers: Set<AnyCancellable> = []
    private var recentStyleNamesObserver: UserDefaultsObservation?
    
    @IBOutlet private weak var toolbar: NSToolbar?
    @IBOutlet private weak var lineEndingPopupButton: NSPopUpButton?
    @IBOutlet private weak var encodingPopupButton: NSPopUpButton?
    @IBOutlet private weak var syntaxPopupButton: NSPopUpButton?
    
    @IBOutlet private weak var shareToolbarItem: NSToolbarItem?
    
    
    
    // MARK: -
    // MARK: Object Methods
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        self.buildEncodingPopupButton()
        self.buildSyntaxPopupButton()
        
        // setup Share toolbar item
        // -> The Share button action must be called on `mouseDown`.
        (self.shareToolbarItem!.view as! NSButton).sendAction(on: .leftMouseDown)
        self.shareToolbarItem!.menuFormRepresentation = NSDocumentController.shared.standardShareMenuItem()
        
        // observe popup menu line-up change
        self.menuUpdateObservers.removeAll()
        EncodingManager.shared.didUpdateSettingList
            .sink { [weak self] _ in self?.buildEncodingPopupButton() }
            .store(in: &self.menuUpdateObservers)
        SyntaxManager.shared.didUpdateSettingList
            .sink { [weak self] _ in self?.buildSyntaxPopupButton() }
            .store(in: &self.menuUpdateObservers)
        
        self.recentStyleNamesObserver?.invalidate()
        self.recentStyleNamesObserver = UserDefaults.standard.observe(key: .recentStyleNames) { [weak self] _ in
            self?.buildSyntaxPopupButton()
        }
    }
    
    
    
    // MARK: Private Methods
    
    /// select item in the encoding popup menu
    private func invalidateLineEndingSelection(to lineEnding: LineEnding) {
        
        self.lineEndingPopupButton?.selectItem(withTag: lineEnding.index)
    }
    
    
    /// select item in the line ending menu
    private func invalidateEncodingSelection() {
        
        guard let fileEncoding = self.document?.fileEncoding else { return }
        
        var tag = Int(fileEncoding.encoding.rawValue)
        if fileEncoding.withUTF8BOM {
            tag *= -1
        }
        
        self.encodingPopupButton?.selectItem(withTag: tag)
    }
    
    
    /// select item in the syntax style menu
    private func invalidateSyntaxStyleSelection() {
        
        guard let popUpButton = self.syntaxPopupButton else { return }
        guard let styleName = self.document?.syntaxParser.style.name else { return }
        
        popUpButton.selectItem(withTitle: styleName)
        if popUpButton.selectedItem == nil {
            popUpButton.selectItem(at: 0)  // select "None"
        }
    }
    
    
    /// build encoding popup item
    private func buildEncodingPopupButton() {
        
        guard let popUpButton = self.encodingPopupButton else { return }
        
        EncodingManager.shared.updateChangeEncodingMenu(popUpButton.menu!)
        
        self.invalidateEncodingSelection()
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
