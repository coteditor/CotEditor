/*
 
 SyntaxTermsEditViewController.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2015-11-28.
 
 ------------------------------------------------------------------------------
 
 © 2015-2016 1024jp
 
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

class SyntaxTermsEditViewController: NSViewController {
    
    // MARK: Private Properties
    
    private var syntaxType: SyntaxType
    
    @IBOutlet weak var termsController: NSArrayController?
    
    
    
    // MARK:
    // MARK: Lifecycle
    
    required init(syntaxType: SyntaxType) {
        
        self.syntaxType = syntaxType
        
        super.init(nibName: nil, bundle: nil)!
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    deinit {
        self.termsController?.unbind(NSContentArrayBinding)
    }
    
    
    override var nibName: String? {
        
        return "SyntaxTermsEditView"
    }
    
    
    
    // MARK: View Controller Methods
    
    /// setup binding with desired key
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.termsController!.bind(NSContentArrayBinding,
                                   to: self,
                                   withKeyPath: "representedObject." + self.syntaxType.rawValue,
                                   options: nil)
    }
    
}
