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
//  © 2018-2022 1024jp
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
    
    // MARK: Private Properties
    
    private let defaultWidth: Int
    private let completionHandler: (_ tabWidth: Int) -> Void
    
    @IBOutlet private weak var tabWidthField: NSTextField?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    /// Initialize view from a storyboard with given values.
    ///
    /// - Parameters:
    ///   - coder: The coder to instantiate the view from a storyboard.
    ///   - defaultWidth: The default tab width.
    ///   - completionHandler: The callback method to perform when the command was accepted.
    init?(coder: NSCoder, defaultWidth: Int, completionHandler: @escaping (_ tabWidth: Int) -> Void) {
        
        self.defaultWidth = defaultWidth
        self.completionHandler = completionHandler
        
        super.init(coder: coder)
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.tabWidthField?.placeholderString = String(self.defaultWidth)
    }
    
    
    
    // MARK: Action Messages
    
    /// apply
    @IBAction func apply(_ sender: Any?) {
        
        guard self.endEditing() else { return NSSound.beep() }
        
        let fieldValue = self.tabWidthField!.integerValue
        let width = (fieldValue > 0) ? fieldValue : self.defaultWidth
        
        self.completionHandler(width)
        self.dismiss(sender)
    }
    
}
