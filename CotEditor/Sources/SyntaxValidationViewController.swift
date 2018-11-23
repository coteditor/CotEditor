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
    
    private(set) var didValidate = false
    
    @objc private dynamic var result: String?
    
    @IBOutlet private var textView: NSTextView?
    
    
    
    // MARK: -
    // MARK: Public Methods
    
    /// validate style and insert the results to text view
    ///
    /// - Returns: If the style is valid
    @discardableResult
    func validateSyntax() -> Bool {
        
        guard let style = self.representedObject as? [String: Any] else { return true }
        
        let errors = SyntaxStyleValidator.validate(style)
        
        let resultMessage: String = {
            switch errors.count {
            case 0:
                return "✅ " + "No error was found.".localized
            case 1:
                return "An error was found!".localized
            default:
                return String(format: "%i errors were found!".localized, errors.count)
            }
        }()
        
        let errorMessages: [String] = errors.map { (error: SyntaxStyleValidator.StyleError) -> String in
            let failureReason = error.failureReason ?? ""
            return "⚠️ " + error.localizedDescription + "\n\t> " + failureReason
        }
        
        self.result = resultMessage + "\n\n" + errorMessages.joined(separator: "\n\n")
        
        return errors.isEmpty
    }
    
    
    
    // MARK: Action Messages
    
    /// start syntax style validation
    @IBAction func startValidation(_ sender: Any?) {
        
        self.validateSyntax()
    }
    
}
