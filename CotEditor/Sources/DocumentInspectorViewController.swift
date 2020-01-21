//
//  DocumentInspectorViewController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-05-31.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2020 1024jp
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

final class DocumentInspectorViewController: NSViewController {
        
    // MARK: Private Properties
    
    @IBOutlet private var dateFormatter: DateFormatter?
    @IBOutlet private var byteCountFormatter: ByteCountFormatter?
    @IBOutlet private var filePermissionsFormatter: FilePermissionsFormatter?
    
    
    
    // MARK: -
    // MARK: View Controller Methods
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // set accessibility
        self.view.setAccessibilityLabel("document insepector".localized)
    }
    
    
    /// let documentAnalyzer autoupdate
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        assert(self.analyzer != nil)
        
        self.analyzer?.needsUpdateEditorInfo = true
        self.analyzer?.invalidateEditorInfo()
    }
    
    
    /// stop autoupdate documentAnalyzer
    override func viewDidDisappear() {
        
        super.viewDidDisappear()
        
        self.analyzer?.needsUpdateEditorInfo = false
    }
    
    
    /// set analyzer
    override var representedObject: Any? {
        
        willSet {
            self.analyzer?.needsUpdateEditorInfo = false
        }
        
        didSet {
            assert(representedObject == nil || representedObject is DocumentAnalyzer,
                   "representedObject of \(self.className) must be an instance of \(DocumentAnalyzer.className())")
            
            self.analyzer?.needsUpdateEditorInfo = self.isViewShown
        }
    }
    
    
    
    // MARK: Private Methods
    
    private var analyzer: DocumentAnalyzer? {
        
        return self.representedObject as? DocumentAnalyzer
    }
    
}
