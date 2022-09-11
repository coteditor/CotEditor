//
//  ThemeMetaDataViewController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2017-03-17.
//
//  ---------------------------------------------------------------------------
//
//  © 2017-2021 1024jp
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

final class ThemeMetaDataViewController: NSViewController {
    
    // MARK: Public Properties
    
    @objc dynamic var isBundled = false
    
    
    
    // MARK: Action Messages
    
    /// jump to theme's distribution URL
    @IBAction func jumpToURL(_ sender: Any?) {
        
        guard
            let theme = self.representedObject as? Theme.Metadata,
            let address = theme.distributionURL,
            let url = URL(string: address)
            else { return NSSound.beep() }
        
        NSWorkspace.shared.open(url)
    }
    
}
