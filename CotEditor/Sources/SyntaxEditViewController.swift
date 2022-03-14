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
//  © 2014-2022 1024jp
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

import Cocoa

final class SyntaxEditViewController: NSViewController, NSTextFieldDelegate, NSTableViewDelegate {
    
    enum Mode {
        
        case edit(_ name: String)
        case copy(_ name: String)
        case new
    }
    
    
    
    // MARK: Public Properties
    
    var mode: Mode = .new {
        
        didSet {
            let manager = SyntaxManager.shared
            
            let style: SyntaxManager.StyleDictionary = {
                switch mode {
                    case .edit(let name), .copy(let name):
                        return manager.settingDictionary(name: name) ?? manager.blankSettingDictionary
                    case .new:
                        return manager.blankSettingDictionary
                }
            }()
            self.style.setDictionary(style)
            
            if case .edit(let name) = mode {
                self.isBundledStyle = manager.isBundledSetting(name: name)
                self.isRestoreble = manager.isCustomizedBundledSetting(name: name)
            }
        }
    }
    
    
    // MARK: Private Properties
    
    @objc private dynamic var menuTitles: [String] = []  // for binding
    
    private let style = NSMutableDictionary(dictionary: SyntaxManager.shared.blankSettingDictionary)
    @objc private dynamic var message: String?
    @objc private dynamic var isStyleNameValid = true
    @objc private dynamic var isRestoreble = false
    @objc private dynamic var isBundledStyle = false
    
    private var tabViewController: NSTabViewController?
    
    @IBOutlet private weak var menuTableView: NSTableView?
    @IBOutlet private weak var styleNameField: NSTextField?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    /// prepare embeded TabViewController
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        if let destinationController = segue.destinationController as? NSTabViewController {
            self.tabViewController = destinationController
            self.menuTitles = destinationController.tabViewItems.map(\.label.localized)
            destinationController.children.forEach { $0.representedObject = self.style }
        }
    }
    
    
    /// setup UI
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // setup style name field
        self.styleNameField?.stringValue = {
            switch self.mode {
                case .edit(let name): return name
                case .copy(let name): return SyntaxManager.shared.savableSettingName(for: name, appendingCopySuffix: true)
                case .new: return ""
            }
        }()
        if self.isBundledStyle {
            self.styleNameField?.drawsBackground = false
            self.styleNameField?.isBezeled = false
            self.styleNameField?.isSelectable = false
            self.styleNameField?.isEditable = false
            self.styleNameField?.isBordered = true
        }
        
        if self.isBundledStyle {
            self.message = "Bundled styles can’t be renamed.".localized
        }
    }
    
    
    
    // MARK: Delegate
    
    // NSTextFieldDelegate  < styleNameField
    
    /// style name did change
    func controlTextDidChange(_ obj: Notification) {
        
        guard let field = obj.object as? NSTextField, field == self.styleNameField else { return }
        
        // validate newly input name
        let styleName = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        
        self.validate(styleName: styleName)
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
        return (self.menuTitles[row] != .separator)
    }
    
    
    
    // MARK: Action Messages
    
    /// restore current settings in editor to default
    @IBAction func setToFactoryDefaults(_ sender: Any?) {
        
        guard
            case .edit(let name) = self.mode,
            let style = SyntaxManager.shared.bundledSettingDictionary(name: name)
            else { return }
        
        self.style.setDictionary(style)
        
        // update validation result if displayed
        (self.tabViewController?.tabView.selectedTabViewItem?.viewController as? SyntaxValidationViewController)?.validateStyle()
    }
    
    
    /// jump to style's destribution URL
    @IBAction func jumpToURL(_ sender: Any?) {
        
        guard
            let metadata = self.style[SyntaxKey.metadata] as? [String: Any],
            let urlString = metadata[MetadataKey.distributionURL] as? String,
            let url = URL(string: urlString)
            else { return NSSound.beep() }
        
        NSWorkspace.shared.open(url)
    }
    
    
    /// save edit and close editor
    @IBAction func save(_ sender: Any?) {
        
        // fix current input
        self.endEditing()
        
        // trim spaces/tab/newlines in style name
        let styleName = self.styleNameField?.stringValue.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        self.styleNameField?.stringValue = styleName
        
        // style name validation
        guard self.validate(styleName: styleName) else {
            self.view.window?.makeFirstResponder(self.styleNameField)
            NSSound.beep()
            return
        }
        
        // validate syntax and display errors
        guard SyntaxStyleValidator.validate(self.style as! SyntaxManager.StyleDictionary).isEmpty else {
            // show "Validation" pane
            let index = self.tabViewController!.tabViewItems.firstIndex { ($0.identifier as? String) == "validation" }!
            self.menuTableView?.selectRowIndexes([index], byExtendingSelection: false)
            NSSound.beep()
            return
        }
        
        // NSMutableDictonary to StyleDictionary
        let styleDictionary: SyntaxManager.StyleDictionary = self.style.reduce(into: [:]) { (dictionary, item) in
            guard let key = item.key as? String else { return assertionFailure() }
            dictionary[key] = item.value
        }
        
        let oldName: String? = {
            guard case .edit(let name) = self.mode else { return nil }
            return name
        }()
        
        do {
            try SyntaxManager.shared.save(settingDictionary: styleDictionary, name: styleName, oldName: oldName)
        } catch {
            print(error)
        }
        
        self.dismiss(sender)
    }
    
    
    
    // MARK: Private Methods
    
    /// validate passed-in style name and return if valid
    @discardableResult
    private func validate(styleName: String) -> Bool {
        
        if case .edit = self.mode, self.isBundledStyle { return true }  // cannot edit style name
        
        self.isStyleNameValid = true
        self.message = nil
        
        if case .edit(let name) = self.mode, (styleName.caseInsensitiveCompare(name) == .orderedSame) { return true }
        
        let originalName: String? = {
            guard case .edit(let name) = self.mode else { return nil }
            return name
        }()
        
        do {
            try SyntaxManager.shared.validate(settingName: styleName, originalName: originalName)
            
        } catch let error as InvalidNameError {
            self.isStyleNameValid = false
            self.message = "⚠️ " + error.localizedDescription + " " + error.recoverySuggestion!
            
        } catch { assertionFailure("Caught unknown error: \(error)") }
        
        return self.isStyleNameValid
    }
    
}
