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
//  © 2014-2018 1024jp
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


enum SyntaxEditSheetMode: Int {
    
    case edit
    case copy
    case new
}


private enum PaneIndex: Int {
    
    case keywords
    case commands
    case types
    case attributes
    case variables
    case values
    case numbers
    case strings
    case characters
    case comments
    case separator1
    case outline
    case completion
    case fileMapping
    case separator2
    case styleInfo
    case validation
    
    
    var title: String {
        switch self {
        case .keywords: return "Keywords"
        case .commands: return "Commands"
        case .types: return "Types"
        case .attributes: return "Attributes"
        case .variables: return "Variables"
        case .values: return "Values"
        case .numbers: return "Numbers"
        case .strings: return "Strings"
        case .characters: return "Characters"
        case .comments: return "Comments"
        case .separator1: return String.separator
        case .outline: return "Outline Menu"
        case .completion: return "Completion List"
        case .fileMapping: return "File Mapping"
        case .separator2: return String.separator
        case .styleInfo: return "Style Info"
        case .validation: return "Syntax Validation"
        }
    }
}



// MARK: -

final class SyntaxEditViewController: NSViewController, NSTextFieldDelegate, NSTableViewDelegate {
    
    // MARK: Private Properties
    
    private let mode: SyntaxEditSheetMode
    private let originalStyleName: String
    @objc private dynamic var style: NSMutableDictionary
    @objc private dynamic var message: String?
    @objc private dynamic var isStyleNameValid = true
    private let isBundledStyle: Bool
    private let isCustomized: Bool
    
    private var viewControllers = [NSViewController?]()
    
    @IBOutlet private weak var box: NSBox?
    @IBOutlet private weak var menuTableView: NSTableView?
    @IBOutlet private weak var styleNameField: NSTextField?
    @IBOutlet private weak var restoreButton: NSButton?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    required init?(style styleName: String, mode: SyntaxEditSheetMode) {
        
        let manager = SyntaxManager.shared
        let name: String
        let style: SyntaxManager.StyleDictionary
        switch mode {
        case .edit:
            name = styleName
            style = manager.settingDictionary(name: styleName) ?? manager.blankSettingDictionary
            
        case .copy:
            name = manager.savableSettingName(for: styleName, appendCopySuffix: true)
            style = manager.settingDictionary(name: styleName) ?? manager.blankSettingDictionary
            
        case .new:
            name = ""
            style = manager.blankSettingDictionary
        }
        self.mode = mode
        self.style = NSMutableDictionary(dictionary: style)
        self.originalStyleName = name
        
        self.isBundledStyle = manager.isBundledSetting(name: name)
        self.isCustomized = manager.isCustomizedBundledSetting(name: name)
        
        if self.isBundledStyle {
            self.message = "Bundled styles can’t be renamed.".localized
        }
        
        super.init(nibName: nil, bundle: nil)
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override var nibName: NSNib.Name? {
        
        return NSNib.Name("SyntaxEditView")
    }
    
    
    
    // MARK: View Controller Methods
    
    /// setup UI
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // setup style name field and restore button
        self.styleNameField?.stringValue = self.originalStyleName
        
        if self.isBundledStyle {
            self.styleNameField?.drawsBackground = false
            self.styleNameField?.isBezeled = false
            self.styleNameField?.isSelectable = false
            self.styleNameField?.isEditable = false
            self.styleNameField?.isBordered = true
            self.restoreButton?.isEnabled = self.isCustomized
        } else {
            self.restoreButton?.isEnabled = false
        }
        
        // setup views
        var viewControllers = [NSViewController?]()
        for type in SyntaxType.allCases {
            if type == .comments { break }
            viewControllers.append(SyntaxTermsEditViewController(syntaxType: type))
        }
        viewControllers.append(NSViewController(nibName: "SyntaxCommentsEditView", bundle: nil))
        viewControllers.append(nil)  // separator
        viewControllers.append(SyntaxEditChildViewController.instantiate(storyboard: "SyntaxOutlineEditView"))
        viewControllers.append(SyntaxEditChildViewController.instantiate(storyboard: "SyntaxCompletionsEditView"))
        viewControllers.append(SyntaxFileMappingEditViewController.instantiate(storyboard: "SyntaxFileMappingEditView"))
        viewControllers.append(nil)  // separator
        viewControllers.append(NSViewController.instantiate(storyboard: "SyntaxInfoEditView"))
        viewControllers.append(SyntaxValidationViewController.instantiate(storyboard: "SyntaxValidationView"))
        
        for viewController in viewControllers {
            guard let viewController = viewController else { continue }  // skip separator
            
            viewController.representedObject = self.style
        }
        
        self.viewControllers = viewControllers
        self.swapView(index: 0)
        
        // set accessibility
        self.box?.setAccessibilityElement(true)
        self.box?.setAccessibilityRole(.group)
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
        
        let row = tableView.selectedRow
        
        // switch view
        self.swapView(index: row)
    }
    
    
    /// return if menu item is selectable
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        
        // separator cannot be selected
        return (PaneIndex(rawValue: row)!.title != String.separator)
    }
    
    
    
    // MARK: Action Messages
    
    /// restore current settings in editor to default
    @IBAction func setToFactoryDefaults(_ sender: Any?) {
        
        guard let style = SyntaxManager.shared.bundledSettingDictionary(name: self.originalStyleName) else { return }
        
        // discard current editing
        self.discardEditing()
        
        // set new content
        self.style.setDictionary(style)
        
        // disable "Restore Defaults" button
        self.restoreButton?.isEnabled = false
    }
    
    
    /// jump to style's destribution URL
    @IBAction func jumpToURL(_ sender: Any?) {
        
        guard
            let metadata = self.style[DictionaryKey.metadata.rawValue] as? [String: Any],
            let urlString = metadata[MetadataKey.distributionURL.rawValue] as? String,
            let url = URL(string: urlString) else {
                NSSound.beep()
                return
        }
        
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
        
        // validate syntax and display errors (or proceed if user has already seen the error)
        let validationController = self.viewControllers[PaneIndex.validation.rawValue] as! SyntaxValidationViewController
        guard validationController.didValidate || validationController.validateSyntax() else {
            // show "Validation" pane
            self.menuTableView?.selectRowIndexes(IndexSet(integer: PaneIndex.validation.rawValue), byExtendingSelection: false)
            NSSound.beep()
            return
        }
        
        // NSMutableDictonary to StyleDictionary
        let style = self.style
        var styleDictionary = SyntaxManager.StyleDictionary()
        for case let (key as String, value) in style {
            styleDictionary[key] = value
        }
        
        let oldName: String? = (self.mode == .new) ? nil : self.originalStyleName
        
        do {
            try SyntaxManager.shared.save(settingDictionary: styleDictionary, name: styleName, oldName: oldName)
        } catch {
            print(error)
        }
        
        self.dismiss(sender)
    }
    
    
    /// discard edit and close editor
    @IBAction func cancel(_ sender: Any?) {
        
        self.discardEditing()
        self.dismiss(sender)
    }
    
    
    
    // MARK: Private Methods
    
    /// menu titles for binding
    @objc var menuTitles: [String] {
        
        return (0...PaneIndex.validation.rawValue)
            .map { PaneIndex(rawValue: $0)!.title.localized }
    }
    
    
    /// change pane
    private func swapView(index: Int) {
        
        // finish current editing anyway
        self.endEditing()
        
        guard let view = self.viewControllers[index]?.view else { return }
        
        // swap views
        self.box!.contentView = view
        self.box!.setAccessibilityLabel(self.menuTitles[index])
    }
    
    
    /// validate passed-in style name and return if valid
    @discardableResult
    private func validate(styleName: String) -> Bool {
        
        if self.mode == .edit, self.isBundledStyle { return true }  // cannot edit style name
        
        self.isStyleNameValid = true
        self.message = nil
        
        if (self.mode == .edit), (styleName.caseInsensitiveCompare(self.originalStyleName) == .orderedSame) { return true }
        
        do {
            try SyntaxManager.shared.validate(settingName: styleName, originalName: self.originalStyleName)
            
        } catch let error as InvalidNameError {
            self.isStyleNameValid = false
            self.message = "⚠️ " + error.localizedDescription + " " + error.recoverySuggestion!
            
        } catch { assertionFailure("Caught unknown error.") }
        
        return self.isStyleNameValid
    }
    
}
