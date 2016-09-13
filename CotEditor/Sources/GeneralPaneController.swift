/*
 
 GeneralPaneController.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2015-07-15.
 
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

final class GeneralPaneController: NSViewController {
    
    // MARK: Private Properties
    
    private dynamic var hasUpdater = false
    private dynamic var prerelease = false
    
    @IBOutlet private weak var updaterConstraint: NSLayoutConstraint?
    
    @IBOutlet private weak var ignoreConflictButton: NSButton?
    @IBOutlet private weak var notifyConflictButton: NSButton?
    @IBOutlet private weak var revertConflictButton: NSButton?
    
    
    
    // MARK:
    // MARK: Lifecycle
    
    override var nibName: String? {
        
        return "GeneralPane"
    }
    
    
    
    // MARK: View Controller Methods
    
    /// setup UI
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // select one of document conflict radio buttons
        let conflictOption = DocumentConflictOption(rawValue: Defaults[.documentConflictOption])!
        switch conflictOption {
        case .ignore:
            self.ignoreConflictButton?.state = NSOnState
        case .notify:
            self.notifyConflictButton?.state = NSOnState
        case .revert:
            self.revertConflictButton?.state = NSOnState
        }
        
        // remove updater option on AppStore ver.
        #if APPSTORE
            // cut down height for updater checkbox
            self.view.frame.size.height -= 96
            
            // cut down x-position of visible labels
            self.view.removeConstraint(self.updaterConstraint!)
        #else
            self.hasUpdater = true
            
            if AppInfo.isPrerelease {
                self.prerelease = true
            } else {
                // cut down height for pre-release note
                self.view.frame.size.height -= 32
            }
        #endif
    }
    
    
    
    // MARK: Action Messages
    
    /// "Enable Auto Save and Versions" checkbox was clicked
    @IBAction func updateAutosaveSetting(_ sender: Any?) {
        
        let currentSetting = Document.autosavesInPlace()
        let newSetting = Defaults[.enablesAutosaveInPlace]
        
        // do nothing if the setting returned to the current one.
        guard currentSetting != newSetting else { return }
        
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("The change will be applied first at the next launch.", comment: "")
        alert.informativeText = NSLocalizedString("Do you want to restart CotEditor now?", comment: "")
        alert.addButton(withTitle: NSLocalizedString("Restart Now", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Later", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
        
        alert.beginSheetModal(for: self.view.window!) { returnCode in
            
            switch returnCode {
            case NSAlertFirstButtonReturn:  // = Restart Now
                NSApp.relaunch(delay: 2.0)
                
            case NSAlertSecondButtonReturn:  // = Later
                break  // do nothing
                
            case NSAlertThirdButtonReturn:  // = Cancel
                Defaults[.enablesAutosaveInPlace] = newSetting
                
            default: break
            }
        }
    }
    
    
    ///
    @IBAction func updateDocumentConflictSetting(_ sender: AnyObject?) {
        
        guard let tag = sender?.tag else { return }
        
        Defaults[.documentConflictOption] = tag
    }
    
}



// MARK: Private Functions

private extension NSApplication {
    
    /// relaunch application itself with delay
    func relaunch(delay: TimeInterval = 0) {
        
        let command = String(format: "sleep %f; open \"%@\"", delay, Bundle.main.bundlePath)
        
        let process = Process()
        process.launchPath = "/bin/sh"
        process.arguments = ["-c", command]
        process.launch()
        
        self.terminate(nil)
    }
    
}
