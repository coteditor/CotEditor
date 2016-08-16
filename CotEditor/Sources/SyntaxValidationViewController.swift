/*
 
 SyntaxValidationViewController.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2014-09-08.
 
 ------------------------------------------------------------------------------
 
 © 2014-2016 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Cocoa

final class SyntaxValidationViewController: NSViewController {
    
    // MARK: Private Properties
    
    private(set) var didValidate = false
    
    private dynamic var result: String?
    
    
    
    // MARK:
    // MARK: Lifecycle
    
    override var nibName: String? {
        
        return "SyntaxValidationView"
    }
    
    
    
    // MARK: Public Methods
    
    /// validate style and insert the results to text view (return: if valid)
    @discardableResult
    func validateSyntax() -> Bool {
        
        guard let style = self.representedObject as? [String: Any] else { return true }
        
        let errors = SyntaxStyleValidator.validate(style)
        
        let resultMessage: String = {
            switch errors.count {
            case 0:
                return "✅ " + NSLocalizedString("No error was found.", comment: "syntax style validation result")
            case 1:
                return NSLocalizedString("An error was found!", comment: "syntax style validation result")
            default:
                return String(format: NSLocalizedString("%i errors were found!", comment: "syntax style validation result"), errors.count)
            }
        }()
        
        let errorMessages = errors.map { error in
            return "⚠️ " + error.localizedDescription + "\n\t> " + (error.failureReason ?? "")
        }
        
        self.result = resultMessage + "\n\n" + errorMessages.joined(separator: "\n\n")
        
        return errors.isEmpty
    }
    
    
    
    // MARK: Action Messages
    
    /// start syntax style validation
    @IBAction func startValidation(_ sender: AnyObject?) {
        
        self.validateSyntax()
    }
    
}
