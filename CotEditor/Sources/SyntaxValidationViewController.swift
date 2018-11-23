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

final class SyntaxValidationViewController: NSViewController {
    
    // MARK: Private Properties
    
    @objc private dynamic var statusImage: NSImage?
    @objc private dynamic var message = ""
    @objc private dynamic var result = ""
    
    
    
    // MARK: -
    // MARK: Life Cycle
    
    override func viewWillAppear() {
        
        // update validation result
        let style = self.representedObject as! SyntaxManager.StyleDictionary
        let errors = SyntaxStyleValidator.validate(style)
        
        self.display(errors: errors)
    }
    
    
    
    // MARK: Private Methods
    
    /// insert the results to text view
    private func display(errors: [SyntaxStyleValidator.StyleError]) {
        
        let imageName = errors.isEmpty ? NSImage.statusAvailableName : NSImage.statusUnavailableName
        self.statusImage = NSImage(named: imageName)
        
        self.message = {
            switch errors.count {
            case 0:
                return "No error was found.".localized
            case 1:
                return "An error was found!".localized
            default:
                return String(format: "%i errors were found!".localized, errors.count)
            }
        }()
        
        self.result = errors
            .map { error -> String in
                guard let failureReason = error.failureReason else {
                    return error.localizedDescription
                }
                return error.localizedDescription + "\n\t> " + failureReason
            }
            .map { "⚠️ " + $0 }
            .joined(separator: "\n\n")
    }
    
}
