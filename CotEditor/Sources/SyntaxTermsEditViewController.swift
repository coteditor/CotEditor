//
//  SyntaxTermsEditViewController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2015-11-28.
//
//  ---------------------------------------------------------------------------
//
//  © 2015-2022 1024jp
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

final class SyntaxTermsEditViewController: NSViewController {
    
    // MARK: Private Properties
    
    @IBOutlet private var termsController: NSArrayController?
    @IBOutlet private var tableViewDelegate: DefinitionTableViewDelegate?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        // set binding with desired key
        let type = (self.parent as? NSTabViewController)?.tabViewItem(for: self)?.identifier as? String
        self.termsController!.bind(.contentArray, to: self, withKeyPath: #keyPath(representedObject) + "." + type!)
    }
    
    
    override func viewDidDisappear() {
        
        super.viewDidDisappear()
        
        self.termsController?.unbind(.contentArray)
    }
    
}
