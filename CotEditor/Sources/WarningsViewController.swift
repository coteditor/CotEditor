//
//  WarningsViewController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2022-04-11.
//
//  ---------------------------------------------------------------------------
//
//  © 2022-2023 1024jp
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

final class WarningsViewController: NSSplitViewController, DocumentOwner {
    
    // MARK: Public Properties
    
    var document: Document { didSet { self.updateDocument() } }
    
    
    // MARK: Lifecycle
    
    init(document: Document) {
        
        self.document = document
        
        super.init(nibName: nil, bundle: nil)
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.splitView.isVertical = false
        
        self.children = [
            NSStoryboard(name: "IncompatibleCharactersView").instantiateInitialController { coder in
                IncompatibleCharactersViewController(document: self.document, coder: coder)
            }!,
            NSStoryboard(name: "InconsistentLineEndingsView").instantiateInitialController { coder in
                InconsistentLineEndingsViewController(document: self.document, coder: coder)
            }!,
        ]
        
        // set accessibility
        self.view.setAccessibilityLabel(String(localized: "Warnings"))
    }
    
    
    // MARK: Private Methods
    
    /// Updates document in the child views.
    private func updateDocument() {
        
        for item in self.splitViewItems {
            (item.viewController as? any DocumentOwner)?.document = self.document
        }
    }
}
