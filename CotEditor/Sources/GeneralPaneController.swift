/*
 
 GeneralPaneController.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2015-07-15.
 
 ------------------------------------------------------------------------------
 
 © 2015-2017 1024jp
 
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

final class GeneralPaneController: NSViewController {
    
    // MARK: Private Properties
    
    @objc private dynamic var hasUpdater = false
    @objc private dynamic var prerelease = false
    
    @IBOutlet private weak var updaterConstraint: NSLayoutConstraint?
    
    @IBOutlet private weak var ignoreConflictButton: NSButton?
    @IBOutlet private weak var notifyConflictButton: NSButton?
    @IBOutlet private weak var revertConflictButton: NSButton?
    
    
    
    // MARK: -
    // MARK: View Controller Methods
    
    /// setup UI
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
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
    
    
    /// apply current settings to UI
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        // select one of document conflict radio buttons
        let conflictOption = DocumentConflictOption(rawValue: UserDefaults.standard[.documentConflictOption])!
        switch conflictOption {
        case .ignore:
            self.ignoreConflictButton?.state = .on
        case .notify:
            self.notifyConflictButton?.state = .on
        case .revert:
            self.revertConflictButton?.state = .on
        }
    }
    
    
    
    // MARK: Action Messages
    
    /// "Enable Auto Save and Versions" checkbox was clicked
    @IBAction func updateAutosaveSetting(_ sender: Any?) {
        
        let currentSetting = Document.autosavesInPlace
        let newSetting = UserDefaults.standard[.enablesAutosaveInPlace]
        
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
            case .alertFirstButtonReturn:  // = Restart Now
                NSApp.relaunch(delay: 2.0)
                
            case .alertSecondButtonReturn:  // = Later
                break  // do nothing
                
            case .alertThirdButtonReturn:  // = Cancel
                UserDefaults.standard[.enablesAutosaveInPlace] = !newSetting
                
            default: break
            }
        }
    }
    
    
    /// A radio button of documentConflictOption was clicked
    @IBAction func updateDocumentConflictSetting(_ sender: NSControl) {
        
        UserDefaults.standard[.documentConflictOption] = sender.tag
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
