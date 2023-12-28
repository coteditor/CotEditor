//
//  EditPaneController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2014-04-18.
//
//  ---------------------------------------------------------------------------
//
//  © 2004-2007 nakamuxu
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

import AppKit

final class EditPaneController: NSViewController {
    
    // MARK: Private Properties
    
    @objc private dynamic lazy var isValidCompletion: Bool = self.validateCompletionSetting()
    
    @IBOutlet private weak var tabWidthField: NSTextField?
    @IBOutlet private weak var selectionInstanceHighlightDelayField: NSTextField?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // set initial values as fields' placeholder
        self.tabWidthField?.bindNullPlaceholderToUserDefaults()
        self.selectionInstanceHighlightDelayField?.bindNullPlaceholderToUserDefaults()
    }
    
    
    
    // MARK: Action Messages
    
    /// The condition of the completion list was changed.
    @IBAction func updateCompletionListWords(_ sender: Any?) {
        
        self.isValidCompletion = self.validateCompletionSetting()
    }
    
    
    
    // MARK: Private Methods
    
    /// Updates the hint for word completion.
    private func validateCompletionSetting() -> Bool {
        
        (UserDefaults.standard[.completesDocumentWords] ||
         UserDefaults.standard[.completesSyntaxWords] ||
         UserDefaults.standard[.completesStandardWords])
    }
}
