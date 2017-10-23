/*
 
 ProgressViewController.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2014-06-07.
 
 ------------------------------------------------------------------------------
 
 © 2014-2017 1024jp
 
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

extension NSView {
    
    var viewControllerForSheet: NSViewController? {
        
        return self.window?.windowController?.contentViewController
    }

}



final class ProgressViewController: NSViewController {
    
    // MARK: Private Properties
    
    @objc private dynamic let progress: Progress
    @objc private dynamic let message: String
    
    @IBOutlet private weak var button: NSButton?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    required init(progress: Progress, message: String) {
        
        self.progress = progress
        self.message = message
        
        super.init(nibName: nil, bundle: nil)
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override var nibName: NSNib.Name? {
        
        return NSNib.Name("ProgressView")
    }
    
    
    
    // MARK: View Public Methods
    
    /// change button to done
    func done(buttonTitle title: String? = nil) {
        
        self.button?.title = title ?? NSLocalizedString("OK", comment: "")
        self.button?.action = #selector(dismiss)
        self.button?.keyEquivalent = "\r"
    }
    
    
    
    // MARK: View Action Messages
    
    /// cancel current process
    @IBAction func cancel(_ sender: Any?) {
        
        self.progress.cancel()
        
        self.dismiss(sender)
    }
    
}
