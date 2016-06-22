/*
 
 MigrationWindowController.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2014-10-09.
 
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

class MigrationWindowController: NSWindowController {
    
    dynamic var didMigrateSyntaxStyles: Bool = false
    dynamic var didMigrateTheme: Bool = false
    dynamic var didResetKeyBindings: Bool = false
    
    
    // MARK: Private Properties
    
    let appName: String = {
        let appName = (Bundle.main().objectForInfoDictionaryKey("CFBundleName") as! NSString) as String
        let version = (Bundle.main().objectForInfoDictionaryKey("CFBundleShortVersionString") as! NSString) as String
        
        return appName + " " + version
    }()
    
    @IBOutlet private var initialView: NSView?
    @IBOutlet private var finishedView: NSView?
    
    @IBOutlet private weak var slideView: NSView?
    @IBOutlet private weak var indicator: NSProgressIndicator?
    @IBOutlet private weak var informativeField: NSTextField?
    @IBOutlet private weak var button: NSButton?
    
    
    
    
    // MARK:
    // MARK: Window Controller Methods
    
    /// nib name
    override var windowNibName: String? {
        return "MigrationWindow"
    }
    
    
    /// setup UI
    override func windowDidLoad() {
        
        super.windowDidLoad()
    
        self.window?.level = Int(CGWindowLevelForKey(.floatingWindow))
        
        self.slideView?.layer?.backgroundColor = NSColor.white().cgColor
        
        self.indicator?.maxValue = 5
        self.indicator?.startAnimation(self)
    }

    
    
    // MARK: Public Methods
    
    /// progress indicator
    func progressIndicator() {

        self.indicator?.doubleValue += 1
    }
    
    
    /// update progress message
    func update(informative: String) {
        
        self.informativeField?.stringValue = NSLocalizedString(informative, comment: "")
    }
    
    
    /// trigger migration finish.
    func finishMigration() {
        
        self.button?.isHidden = false
        
        if let indicator = self.indicator {
            indicator.doubleValue = indicator.maxValue
            indicator.stopAnimation(self)
        }
    }
    
    
    
    // MARK: Action Messages
    
    /// transit to finished mode
    @IBAction func didFinishMigration(_ sender: AnyObject?) {
        
        self.swap(view: self.finishedView!)
        
        // change button
        if let button = self.button {
            button.target = self.window
            button.action = #selector(NSWindow.orderOut(_:))
            button.title = NSLocalizedString("Close", comment: "")
        }
    }
    
    
    
    // MARK Private Methods
    
    /// swap current slide view with another view
    private func swap(view: NSView) {
        
        guard let currentView = self.slideView?.subviews.first else { return }
        
        self.slideView?.animator().replaceSubview(currentView, with: view)
    }
    
}
