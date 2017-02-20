/*
 
 EditPaneController.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2014-04-18.
 
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014-2016 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 https://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Cocoa

final class EditPaneController: NSViewController {
    
    // MARK: Private Properties
    
    private dynamic var isValidCompletion = true
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    override var nibName: String? {
        
        return "EditPane"
    }
    
    
    
    // MARK: View Controller Methods
    
    /// setup UI
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.updateCompletionHintMessage()
    }
    
    
    
    // MARK: Action Messages
    
    /// completion list condition was changed
    @IBAction func updateCompletionListWords(_ sender: Any?) {
        
        self.updateCompletionHintMessage()
    }
    
    
    
    // MARK: Private Methods
    
    /// update hint for word completion
    private func updateCompletionHintMessage() {
        
        let defaults = UserDefaults.standard
        self.isValidCompletion = (
            defaults[.completesDocumentWords] ||
            defaults[.completesSyntaxWords] ||
            defaults[.completesStandartWords]
        )
    }
    
}
