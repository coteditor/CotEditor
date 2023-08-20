//
//  PrintPaneController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2014-04-18.
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

final class PrintPaneController: NSViewController {
    
    // MARK: Private Properties
    
    @IBOutlet private weak var colorPopUpButton: NSPopUpButton?
    
    @IBOutlet private weak var primaryHeaderPopUpButton: NSPopUpButton?
    @IBOutlet private weak var secondaryHeaderPopUpButton: NSPopUpButton?
    @IBOutlet private weak var primaryFooterPopUpButton: NSPopUpButton?
    @IBOutlet private weak var secondaryFooterPopUpButton: NSPopUpButton?
    
    @IBOutlet private weak var primaryHeaderAlignmentControl: NSSegmentedControl?
    @IBOutlet private weak var secondaryHeaderAlignmentControl: NSSegmentedControl?
    @IBOutlet private weak var primaryFooterAlignmentControl: NSSegmentedControl?
    @IBOutlet private weak var secondaryFooterAlignmentControl: NSSegmentedControl?
    
    
    
    // MARK: -
    // MARK: View Controller Methods
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.setup(popUpButton: self.primaryHeaderPopUpButton!,
                   contentKey: .primaryHeaderContent, enablingKey: .printHeader)
        self.setup(popUpButton: self.secondaryHeaderPopUpButton!,
                   contentKey: .secondaryHeaderContent, enablingKey: .printHeader)
        self.setup(popUpButton: self.primaryFooterPopUpButton!,
                   contentKey: .primaryFooterContent, enablingKey: .printFooter)
        self.setup(popUpButton: self.secondaryFooterPopUpButton!,
                   contentKey: .secondaryFooterContent, enablingKey: .printFooter)
        
        AlignmentType.setup(segmentedControl: self.primaryHeaderAlignmentControl!)
        AlignmentType.setup(segmentedControl: self.secondaryHeaderAlignmentControl!)
        AlignmentType.setup(segmentedControl: self.primaryFooterAlignmentControl!)
        AlignmentType.setup(segmentedControl: self.secondaryFooterAlignmentControl!)
    }
    
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        self.setupColorMenu()
    }
    
    
    
    // MARK: Action Messages
    
    /// Color setting did update.
    @IBAction func changePrintTheme(_ sender: NSPopUpButton) {
        
        let index = sender.indexOfSelectedItem
        let theme = (index > 2) ? sender.titleOfSelectedItem : nil  // do not set theme on `Black and White` and `same as document's setting`
        
        UserDefaults.standard[.printTheme] = theme
        UserDefaults.standard[.printColorIndex] = index
    }
    
    
    
    // MARK: Private Methods
    
    /// Update popup menu for color setting.
    private func setupColorMenu() {
        
        let index = UserDefaults.standard[.printColorIndex]
        let themeName = UserDefaults.standard[.printTheme]
        let themeNames = ThemeManager.shared.settingNames
        
        guard let popUpButton = self.colorPopUpButton else { return assertionFailure() }
        
        popUpButton.removeAllItems()
        
        // build popup button
        popUpButton.addItem(withTitle: ThemeName.blackAndWhite)
        popUpButton.addItem(withTitle: String(localized: "Use Editor Setting"))
        
        popUpButton.menu?.addItem(.separator())
        popUpButton.menu?.addItem(.sectionHeader(title: String(localized: "Theme")))
        
        for name in themeNames {
            popUpButton.addItem(withTitle: name)
        }
        
        // select menu
        popUpButton.selectItem(at: 0)  // black and white (default)
        if let themeName {
            if themeNames.contains(themeName) {
                popUpButton.selectItem(withTitle: themeName)
            } else if index == 1 {
                popUpButton.selectItem(at: 1)  // same as document
            }
        }
    }
    
    
    /// Set up pop-up button for header/footer print info.
    /// - Parameters:
    ///   - popUpButton: The pop-up button to set up.
    ///   - contentKey: The default key for binding to set the option.
    ///   - enablingKey: The default key for binding to enable the button.
    private func setup(popUpButton: NSPopUpButton, contentKey: DefaultKey<PrintInfoType>, enablingKey: DefaultKey<Bool>) {
        
        let defaults = NSUserDefaultsController.shared
        
        popUpButton.menu?.items = PrintInfoType.menuItems
        popUpButton.bind(.selectedTag, to: defaults, withKeyPath: "values.\(contentKey.rawValue)")
        popUpButton.bind(.enabled, to: defaults, withKeyPath: "values.\(enablingKey.rawValue)")
    }
}
