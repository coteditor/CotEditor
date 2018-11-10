//
//  GeneralPaneController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2015-07-15.
//
//  ---------------------------------------------------------------------------
//
//  © 2015-2018 1024jp
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

final class GeneralPaneController: NSViewController {
    
    // MARK: Private Properties
    
    @IBOutlet private weak var ignoreConflictButton: NSButton?
    @IBOutlet private weak var notifyConflictButton: NSButton?
    @IBOutlet private weak var revertConflictButton: NSButton?
    
    @IBOutlet private weak var selectionInstanceHighlightDelayField: NSTextField?
    
    
    
    // MARK: -
    // MARK: View Controller Methods
    
    /// setup UI
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.selectionInstanceHighlightDelayField?.bindNullPlaceholderToUserDefaults(.value)
        
        // remove updater options if no Sparkle provided
        #if APPSTORE
            for subview in self.view.subviews where subview.tag < 0 {
                subview.removeFromSuperview()
            }
        #endif
        if !Bundle.main.isPrerelease {
            for subview in self.view.subviews where subview.tag == -2 {
                subview.removeFromSuperview()
            }
        }
    }
    
    
    /// apply current settings to UI
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        // select one of document conflict radio buttons
        switch UserDefaults.standard[.documentConflictOption] {
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
        
        // do nothing if the setting returned to the current one.
        guard UserDefaults.standard[.enablesAutosaveInPlace] != Document.autosavesInPlace else { return }
        
        self.askRelaunch(for: .enablesAutosaveInPlace)
    }
    
    
    /// "Restore last windows on launch" checkbox was clicked
    @IBAction func updateWindowRestorationSetting(_ sender: Any?) {
        
        self.askRelaunch(for: .quitAlwaysKeepsWindows)
    }
    
    
    /// A radio button of documentConflictOption was clicked
    @IBAction func updateDocumentConflictSetting(_ sender: NSButton) {
        
        UserDefaults.standard[.documentConflictOption] = DocumentConflictOption(rawValue: sender.tag)!
    }
    
    
    
    // MARK: Private Methods
    
    private func askRelaunch(for defaultKey: DefaultKey<Bool>) {
        
        let alert = NSAlert()
        alert.messageText = "The change will be applied first at the next launch.".localized
        alert.informativeText = "Do you want to restart CotEditor now?".localized
        alert.addButton(withTitle: "Restart Now".localized)
        alert.addButton(withTitle: "Later".localized)
        alert.addButton(withTitle: "Cancel".localized)
        
        alert.beginSheetModal(for: self.view.window!) { returnCode in
            
            switch returnCode {
            case .alertFirstButtonReturn:  // = Restart Now
                NSApp.relaunch(delay: 2.0)
            case .alertSecondButtonReturn:  // = Later
                break  // do nothing
            case .alertThirdButtonReturn:  // = Cancel
                UserDefaults.standard[defaultKey].toggle()  // revert state
            default:
                preconditionFailure()
            }
        }
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
