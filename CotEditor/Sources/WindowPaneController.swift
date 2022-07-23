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

final class WindowPaneController: NSViewController {
    
    // MARK: Private Properties
    
    private lazy var titleForRespectSystemSetting: String = self.tabbingOptionMenu!.items.first!.title
    
    @IBOutlet private weak var tabbingOptionMenu: NSMenu?
    
    @IBOutlet private weak var pageGuideColumnField: NSTextField?
    @IBOutlet private weak var overscrollField: NSTextField?
    @IBOutlet private weak var editorOpacityField: NSTextField?
    
    @IBOutlet private weak var ltrWritingDirectionButton: NSButton?
    @IBOutlet private weak var rtlWritingDirectionButton: NSButton?
    @IBOutlet private weak var verticalWritingDirectionButton: NSButton?
    
    
    
    // MARK: -
    // MARK: View Controller Methods
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // set initial values as fields' placeholder
        self.pageGuideColumnField?.bindNullPlaceholderToUserDefaults()
        self.overscrollField?.bindNullPlaceholderToUserDefaults()
        self.editorOpacityField?.bindNullPlaceholderToUserDefaults()
    }
    
    
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        // display the current systemwide user setting for window tabbing in "Respect System Setting" menu item.
        let menu = self.tabbingOptionMenu!
        let systemSettingLabel = menu.item(withTag: NSWindow.userTabbingPreference.rawValue)!.title
        let attributes: [NSAttributedString.Key: Any] = [.font: menu.font].compactMapValues { $0 }
        let attrLabel = NSAttributedString(string: self.titleForRespectSystemSetting, attributes: attributes)
        let userSettingLabel = NSAttributedString(string: String(localized: " (\(systemSettingLabel))"),
                                                  attributes: [.foregroundColor: NSColor.secondaryLabelColor].merging(attributes) { $1 })
        
        menu.items.first!.attributedTitle = attrLabel + userSettingLabel
        
        // select one of writing direction radio buttons
        switch UserDefaults.standard[.writingDirection] {
            case .leftToRight:
                self.ltrWritingDirectionButton?.state = .on
            case .rightToLeft:
                self.rtlWritingDirectionButton?.state = .on
            case .vertical:
                self.verticalWritingDirectionButton?.state = .on
        }
    }
    
    
    
    // MARK: Action Messages
    
    /// A radio button of writingDirection was clicked
    @IBAction func updateWritingDirectionSetting(_ sender: NSControl) {
        
        UserDefaults.standard[.writingDirection] = WritingDirection(rawValue: sender.tag)!
    }
    
}
