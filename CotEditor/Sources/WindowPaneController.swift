//
//  WindowPaneController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2014-04-18.
//
//  ---------------------------------------------------------------------------
//
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

final class WindowPaneController: NSViewController {
    
    // MARK: Private Properties
    
    private lazy var titleForRespectSystemSetting: String = self.tabbingOptionMenu!.items.first!.title
    
    @IBOutlet private weak var tabbingOptionMenu: NSMenu?
    @IBOutlet private weak var tabbingSupportCaution: NSTextField?
    
    @objc private dynamic var editorOpaque: Bool = (UserDefaults.standard[.windowAlpha] == 1.0)
    
    
    
    // MARK: -
    // MARK: View Controller Methods
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        if (NSApp.delegate as! AppDelegate).supportsWindowTabbing {
            self.tabbingSupportCaution!.removeFromSuperview()
        }
    }
    
    
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        guard #available(macOS 10.12, *) else { return }
        
        // display the current system-wide user setting for window tabbing in "Respect System Setting" menu item.
        let menu = self.tabbingOptionMenu!
        let systemSettingLabel = menu.item(withTag: NSWindow.userTabbingPreference.rawValue)!.title
        let attrLabel = NSAttributedString(string: self.titleForRespectSystemSetting,
                                           attributes: [.font: menu.font])
        let userSettingLabel = NSAttributedString(string: String(format: NSLocalizedString(" (%@)", comment: ""), systemSettingLabel),
                                                  attributes: [.font: menu.font,
                                                               .foregroundColor: NSColor.secondaryLabelColor])
        
        menu.items.first!.attributedTitle = attrLabel + userSettingLabel
    }
    
    
    
    // MARK: Actions
    
    /// opaque setting did update
    @IBAction func changeEditorOpaque(_ sender: NSControl) {
        
        self.editorOpaque = (sender.doubleValue == 1.0)
    }
    
}
