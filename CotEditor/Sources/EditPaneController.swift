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
//  © 2014-2020 1024jp
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

final class EditPaneController: NSViewController {
    
    // MARK: Private Properties
    
    @objc private lazy dynamic var isValidCompletion: Bool = self.validateCompletionSetting()
    
    @IBOutlet private weak var tabWidthField: NSTextField?
    @IBOutlet private weak var hangingIndentWidthField: NSTextField?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // set initial values as fields' placeholder
        self.tabWidthField?.bindNullPlaceholderToUserDefaults()
        self.hangingIndentWidthField?.bindNullPlaceholderToUserDefaults()
    }
    
    
    
    // MARK: Action Messages
    
    /// completion list condition was changed
    @IBAction func updateCompletionListWords(_ sender: Any?) {
        
        self.isValidCompletion = self.validateCompletionSetting()
    }
    
    
    
    // MARK: Private Methods
    
    /// update hint for word completion
    private func validateCompletionSetting() -> Bool {
        
        return (UserDefaults.standard[.completesDocumentWords] ||
                UserDefaults.standard[.completesSyntaxWords] ||
                UserDefaults.standard[.completesStandartWords]
            )
    }
    
}
