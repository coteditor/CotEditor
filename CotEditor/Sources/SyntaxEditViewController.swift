//
//  SyntaxEditViewController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2014-04-03.
//
//  ---------------------------------------------------------------------------
//
//  © 2004-2007 nakamuxu
//  © 2014-2023 1024jp
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

final class SyntaxEditViewController: NSViewController, NSTextFieldDelegate, NSTableViewDelegate {
    
    enum Mode {
        
        case edit(_ state: SettingState)
        case new
    }
    
    
    
    // MARK: Private Properties
    
    private let mode: Mode
    private let syntax: NSMutableDictionary
    private let validator: SyntaxValidator
    @objc private let isRestorable: Bool
    @objc private let isBundledSyntax: Bool
    
    @objc private dynamic var menuTitles: [String] = []  // for binding
    @objc private dynamic var message: String?
    
    private var tabViewController: NSTabViewController?
    
    @IBOutlet private weak var menuTableView: NSTableView?
    @IBOutlet private weak var syntaxNameField: NSTextField?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    /// Initialize view from a storyboard with the given mode.
    ///
    /// - Parameters:
    ///   - coder: The coder to instantiate the view from a storyboard.
    ///   - mode: The edit mode.
    init?(coder: NSCoder, mode: Mode) {
        
        self.mode = mode
        
        let manager = SyntaxManager.shared
        
        let syntax: SyntaxManager.SyntaxDictionary = switch mode {
            case .edit(let state):
                manager.settingDictionary(name: state.name) ?? manager.blankSettingDictionary
            case .new:
                manager.blankSettingDictionary
        }
        self.syntax = NSMutableDictionary(dictionary: syntax)
        
        switch mode {
            case .edit(let state):
                self.isBundledSyntax = state.isBundled
                self.isRestorable = state.isRestorable
            case .new:
                self.isBundledSyntax = false
                self.isRestorable = false
        }
        
        self.validator = SyntaxValidator(syntax: self.syntax)
        
        super.init(coder: coder)
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        // prepare embedded TabViewController
        if let tabViewController = segue.destinationController as? NSTabViewController {
            let validationView = SyntaxValidationView(validator: self.validator)
            let validationTabItem = NSTabViewItem(viewController: NSHostingController(rootView: validationView))
            validationTabItem.identifier = "validation"
            validationTabItem.label = String(localized: "Syntax Validation")
            tabViewController.addTabViewItem(validationTabItem)
            
            self.tabViewController = tabViewController
            self.menuTitles = tabViewController.tabViewItems.map(\.label)
                .map { String(localized: String.LocalizationValue($0)) }
            tabViewController.children.forEach { $0.representedObject = self.syntax }
        }
    }
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        let syntaxNameField = self.syntaxNameField!
        
        // setup syntax name field
        syntaxNameField.stringValue = switch self.mode {
            case .edit(let state): state.name
            case .new: ""
        }
        if self.isBundledSyntax {
            syntaxNameField.isBezeled = false
            syntaxNameField.isSelectable = false
            syntaxNameField.isEditable = false
            syntaxNameField.isBordered = true
            syntaxNameField.toolTip = String(localized: "Bundled syntaxes can’t be renamed.")
        }
    }
    
    
    
    // MARK: Delegate
    
    // NSTextFieldDelegate  < syntaxNameField
    
    /// syntax name did change
    func controlTextDidChange(_ obj: Notification) {
        
        guard let field = obj.object as? NSTextField, field == self.syntaxNameField else { return }
        
        // validate newly input name
        let syntaxName = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        
        self.validate(syntaxName: syntaxName)
    }
    
    
    // NSTableViewDelegate  < menuTableView
    
    /// side menu tableView selection did change
    func tableViewSelectionDidChange(_ notification: Notification) {
        
        guard let tableView = notification.object as? NSTableView else { return assertionFailure() }
        
        // switch view
        self.endEditing()
        self.tabViewController?.selectedTabViewItemIndex = tableView.selectedRow
    }
    
    
    /// return if menu item is selectable
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        
        // separator cannot be selected
        (self.menuTitles[row] != .separator)
    }
    
    
    
    // MARK: Action Messages
    
    /// restore current settings in editor to default
    @IBAction func setToFactoryDefaults(_ sender: Any?) {
        
        guard
            case .edit(let state) = self.mode,
            let syntax = SyntaxManager.shared.bundledSettingDictionary(name: state.name)
        else { return }
        
        self.syntax.setDictionary(syntax)
        
        // update validation result if displayed
        self.validator.validate()
    }
    
    
    /// jump to syntax's distribution URL
    @IBAction func jumpToURL(_ sender: Any?) {
        
        guard
            let metadata = self.syntax[SyntaxKey.metadata] as? [String: Any],
            let urlString = metadata[MetadataKey.distributionURL] as? String,
            let url = URL(string: urlString)
        else { return NSSound.beep() }
        
        NSWorkspace.shared.open(url)
    }
    
    
    /// save edit and close editor
    @IBAction func save(_ sender: Any?) {
        
        // fix current input
        self.endEditing()
        
        // trim spaces/tab/newlines in syntax name
        let syntaxName = self.syntaxNameField?.stringValue.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        self.syntaxNameField?.stringValue = syntaxName
        
        // syntax name validation
        guard self.validate(syntaxName: syntaxName) else {
            self.view.window?.makeFirstResponder(self.syntaxNameField)
            NSSound.beep()
            return
        }
        
        // validate syntax and display errors
        guard self.validator.validate() else {
            // show "Validation" pane
            let index = self.tabViewController!.tabViewItems.firstIndex { ($0.identifier as? String) == "validation" }!
            self.menuTableView?.selectRowIndexes([index], byExtendingSelection: false)
            NSSound.beep()
            return
        }
        
        // NSMutableDictonary to SyntaxDictionary
        let syntaxDictionary: SyntaxManager.SyntaxDictionary = self.syntax.reduce(into: [:]) { (dictionary, item) in
            guard let key = item.key as? String else { return assertionFailure() }
            dictionary[key] = item.value
        }
        
        let oldName: String? = {
            guard case .edit(let state) = self.mode else { return nil }
            return state.name
        }()
        
        do {
            try SyntaxManager.shared.save(settingDictionary: syntaxDictionary, name: syntaxName, oldName: oldName)
        } catch {
            print(error)
        }
        
        self.dismiss(sender)
    }
    
    
    
    // MARK: Private Methods
    
    /// Validate the passed-in syntax name.
    ///
    /// - Parameter syntaxName: The syntax name to test.
    /// - Returns: `true` if the syntax name is valid.
    @discardableResult
    private func validate(syntaxName: String) -> Bool {
        
        if case .edit = self.mode, self.isBundledSyntax { return true }  // cannot edit syntax name
        
        self.message = nil
        
        let originalName: String? = {
            guard case .edit(let state) = self.mode else { return nil }
            return state.name
        }()
        
        do {
            try SyntaxManager.shared.validate(settingName: syntaxName, originalName: originalName)
        } catch {
            self.message = error.localizedDescription
            return false
        }
        
        return true
    }
}
