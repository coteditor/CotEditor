//
//  SyntaxValidationViewController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2014-09-08.
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

final class SyntaxValidationViewController: NSViewController {
    
    // MARK: Private Properties
    
    @objc private dynamic var errors: [SyntaxStyleValidator.StyleError] = []
    
    @objc private dynamic var statusImage: NSImage?
    @objc private dynamic var message = ""
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        self.validateStyle()
    }
    
    
    
    // MARK: Public Methods
    
    func validateStyle() {
        
        let style = self.representedObject as! SyntaxManager.StyleDictionary
        
        self.errors = SyntaxStyleValidator.validate(style)
        self.updateMessage()
    }
    
    
    
    // MARK: Private Methods
    
    /// insert the results to text view
    private func updateMessage() {
        
        let imageName = self.errors.isEmpty ? NSImage.statusAvailableName : NSImage.statusUnavailableName
        self.statusImage = NSImage(named: imageName)
        
        self.message = {
            switch self.errors.count {
                case 0:
                    return "No error found.".localized
                case 1:
                    return "An error found!".localized
                default:
                    return String(localized: "\(errors.count) errors found!")
            }
        }()
    }
    
}
