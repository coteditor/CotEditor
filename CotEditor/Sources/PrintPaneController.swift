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
    
    
    
    // MARK: -
    // MARK: View Controller Methods
    
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
        popUpButton.addItem(withTitle: String(localized: "Same as Document’s Setting"))
        
        popUpButton.menu?.addItem(.separator())
        popUpButton.menu?.addItem(HeadingMenuItem(title: String(localized: "Theme")))
        
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
}
