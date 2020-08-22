//
//  IntegrationPaneController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2014-12-20.
//
//  ---------------------------------------------------------------------------
//
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

final class IntegrationPaneController: NSViewController {
    
    // MARK: Private Properties
    
    @IBOutlet private weak var cltStatusView: NSImageView?
    @IBOutlet private weak var cltPathField: NSTextField?
    
    
    
    // MARK: -
    // MARK: View Controller Methods
    
    /// update warnings before view appears
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        self.validateCommandLineTool()
    }
    
    
    
    // MARK: Private Methods
    
    private func validateCommandLineTool() {
        
        let status = CommandLineToolManager.shared.validateSymLink()
        
        self.cltStatusView?.isHidden = !status.installed
        self.cltStatusView?.image = status.badge.image
        self.cltStatusView?.toolTip = status.message
        
        self.cltPathField?.isHidden = !status.installed
        self.cltPathField?.stringValue = String(format: "installed at %@".localized,
                                                CommandLineToolManager.shared.linkURL.path)
    }
    
}
