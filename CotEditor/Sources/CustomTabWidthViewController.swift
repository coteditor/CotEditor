//
//  CustomTabWidthViewController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-07-07.
//
//  ---------------------------------------------------------------------------
//
//  © 2018-2020 1024jp
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

final class CustomTabWidthViewController: NSViewController {
    
    // MARK: Public Properties
    
    var defaultWidth: Int = 4
    var completionHandler: ((_ tabWidth: Int) -> Void)?
    
    
    // MARK: Private Properties
    
    @IBOutlet private weak var tabWidthField: NSTextField?
    
    
    
    // MARK: -
    // MARK: View Controller Methods
    
    /// set default tab width to placeholder
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.tabWidthField?.placeholderString = String(self.defaultWidth)
    }
    
    
    
    // MARK: Action Messages
    
    /// apply
    @IBAction func apply(_ sender: Any?) {
        
        assert(self.completionHandler != nil)
        
        guard self.endEditing() else { return NSSound.beep() }
        
        let fieldValue = self.tabWidthField!.integerValue
        let width = (fieldValue > 0) ? fieldValue : self.defaultWidth
        
        self.completionHandler?(width)
        self.dismiss(sender)
    }
    
}
