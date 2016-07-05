/*
 
 ToolbarController.swift
 
 CotEditor
 https://coteditor.com
 
 Created by nakamuxu on 2005-01-07.
 
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014-2016 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Cocoa

class ToolbarController: NSObject {
    
    // MARK: Public Properties
    
    var document: CEDocument? {
        willSet {
            for keyPath in self.observedDocumentKeys {
                self.document?.removeObserver(self, forKeyPath: keyPath)
            }
        }
        
        didSet {
            self.invalidateLineEndingSelection()
            self.invalidateEncodingSelection()
            self.invalidateSyntaxStyleSelection()
            self.toolbar?.validateVisibleItems()
            
            // observe document status change
            for keyPath in self.observedDocumentKeys {
                document?.addObserver(self, forKeyPath: keyPath, options: [], context: nil)
            }
        }
    }
    
    
    // MARK: Private Properties
    
    /// document's key paths to observe
    private var observedDocumentKeys = [NSStringFromSelector(#selector(getter: CEDocument.lineEnding)),
                                        NSStringFromSelector(#selector(getter: CEDocument.encoding)),
                                        NSStringFromSelector(#selector(getter: CEDocument.hasUTF8BOM)),
                                        NSStringFromSelector(#selector(getter: CEDocument.syntaxStyle))]
    
    @IBOutlet private weak var toolbar: NSToolbar?
    @IBOutlet private weak var lineEndingPopupButton: NSPopUpButton?
    @IBOutlet private weak var encodingPopupButton: NSPopUpButton?
    @IBOutlet private weak var syntaxPopupButton: NSPopUpButton?
    @IBOutlet private weak var shareButton: NSButton?

    
    
    // MARK:
    // MARK: Lifecycle
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        
        for keyPath in self.observedDocumentKeys {
            self.document?.removeObserver(self, forKeyPath: keyPath)
        }
    }
    
    
    
    // MARK: Object Methods
    
    /// setup UI
    override func awakeFromNib() {
        
        // setup share button
        self.shareButton?.sendAction(on: .leftMouseDown)
        
        self.buildEncodingPopupButton()
        self.buildSyntaxPopupButton()
        
        // observe popup menu line-up change
        NotificationCenter.default.addObserver(self, selector: #selector(buildEncodingPopupButton), name: EncodingManager.ListDidUpdateNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(buildSyntaxPopupButton), name: .CESyntaxListDidUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(buildSyntaxPopupButton), name: .CESyntaxHistoryDidUpdate, object: nil)
    }
    
    
    /// update popup button selection
    override func observeValue(forKeyPath keyPath: String?, of object: AnyObject?, change: [NSKeyValueChangeKey : AnyObject]?, context: UnsafeMutablePointer<Void>?) {
        
        guard let keyPath = keyPath else { return }
        
        switch NSSelectorFromString(keyPath) {
        case #selector(getter: CEDocument.lineEnding):
            DispatchQueue.main.async { [weak self] in
                self?.invalidateLineEndingSelection()
            }
            
        case #selector(getter: CEDocument.encoding),
             #selector(getter: CEDocument.hasUTF8BOM):
            DispatchQueue.main.async { [weak self] in
                self?.invalidateEncodingSelection()
            }
            
        case #selector(getter: CEDocument.syntaxStyle):
            DispatchQueue.main.async { [weak self] in
                self?.invalidateSyntaxStyleSelection()
            }
            
        default: break
        }
    }
    
    
    
    // MARK: Private Methods
    
    /// select item in the encoding popup menu
    private func invalidateLineEndingSelection() {
        
        guard let lineEnding = self.document?.lineEnding else { return }
        
        self.lineEndingPopupButton?.selectItem(withTag: lineEnding.rawValue)
    }
    
    
    /// select item in the line ending menu
    private func invalidateEncodingSelection() {
        
        guard let encoding = self.document?.encoding else { return }
        
        var tag = Int(encoding)
        if self.document?.hasUTF8BOM ?? false {
            tag *= -1
        }
        
        self.encodingPopupButton?.selectItem(withTag: tag)
    }
    
    
    /// select item in the syntax style menu
    private func invalidateSyntaxStyleSelection() {
        
        guard let popUpButton = self.syntaxPopupButton else { return }
        guard let styleName = self.document?.syntaxStyle.styleName else { return }
        
        popUpButton.selectItem(withTitle: styleName)
        if popUpButton.selectedItem == nil {
            popUpButton.selectItem(at: 0)  // select "None"
        }
    }
    
    
    /// build encoding popup item
    func buildEncodingPopupButton() {
        
        guard let popUpButton = self.encodingPopupButton else { return }
        
        EncodingManager.shared.updateChangeEncodingMenu(popUpButton.menu!)
        
        self.invalidateEncodingSelection()
    }
    
    
    /// build syntax style popup menu
    func buildSyntaxPopupButton() {
        
        guard let menu = self.syntaxPopupButton?.menu else { return }
        
        let styleNames = CESyntaxManager.shared().styleNames
        let recentStyleNames = CESyntaxManager.shared().recentStyleNames
        let action = #selector(CEDocument.changeSyntaxStyle(_:))
        
        menu.removeAllItems()
        
        menu.addItem(withTitle: NSLocalizedString("None", comment: ""), action: action, keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        
        if !recentStyleNames.isEmpty {
            let labelItem = NSMenuItem()
            labelItem.title = NSLocalizedString("Recently Used", comment: "menu heading in syntax style list on toolbar popup")
            labelItem.isEnabled = false
            menu.addItem(labelItem)
            
            for styleName in recentStyleNames {
                menu.addItem(withTitle: styleName, action: action, keyEquivalent: "")
            }
            menu.addItem(NSMenuItem.separator())
        }
        
        for styleName in styleNames {
            menu.addItem(withTitle: styleName, action: action, keyEquivalent: "")
        }
        
        self.invalidateSyntaxStyleSelection()
    }
    
}
