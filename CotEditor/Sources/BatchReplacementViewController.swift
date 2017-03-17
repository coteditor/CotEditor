/*
 
 BatchReplacementViewController.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2017-02-19.
 
 ------------------------------------------------------------------------------
 
 © 2017 1024jp
 
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

final class BatchReplacementViewController: NSViewController {
    
    // MARK: View Controller Methods
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.representedObject = BatchReplacement(name: NSLocalizedString("Untitled", comment: ""))
    }
    
    
    /// pass settings to advanced options popover
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        if segue.identifier == "OptionsSegue",
            let destinationController = segue.destinationController as? NSViewController,
            let batchReplacement = self.representedObject as? BatchReplacement
        {
            destinationController.representedObject = BatchReplacement.Settings.Object(settings: batchReplacement.settings)
        }
    }
    
    
    /// get settings from advanced options popover
    override func dismissViewController(_ viewController: NSViewController) {
        
        super.dismissViewController(viewController)
        
        if let object = viewController.representedObject as? BatchReplacement.Settings.Object {
            (self.representedObject as? BatchReplacement)?.settings = object.settings
        }
    }
    
    
    
    // MARK: Action Messages
    
    /// perform batch replacement
    @IBAction func batchReplace(_ sender: AnyObject?) {
        
        guard
            let textView = TextFinder.shared.client,
            let string = textView.string
            else {
                NSBeep()
                return
        }
        
        guard let batchReplacement = self.representedObject as? BatchReplacement else {
            assertionFailure("No batchReplacement object is set.")
            return
        }
        
        let inSelection = UserDefaults.standard[.findInSelection]
        
        textView.isEditable = false
        
        // setup progress sheet
        let progress = Progress(totalUnitCount: Int64(batchReplacement.replacements.count))
        let indicator = ProgressViewController(progress: progress, message: NSLocalizedString("Batch Replace", comment: ""))
        textView.viewControllerForSheet?.presentViewControllerAsSheet(indicator)
        
        DispatchQueue.global().async {
            let result = batchReplacement.replace(string: string, ranges: textView.selectedRanges as [NSRange], inSelection: inSelection) { (stop) in
                guard !progress.isCancelled else {
                    stop = true
                    return
                }
            }
            
            DispatchQueue.main.async {
                textView.isEditable = true
                
                guard !progress.isCancelled else {
                    indicator.dismiss(nil)
                    return
                }
                
                if result.count > 0 {
                    // apply to the text view
                    textView.replace(with: [result.string], ranges: [string.nsRange],
                                     selectedRanges: result.selectedRanges,
                                     actionName: NSLocalizedString("Batch Replacement", comment: ""))
                } else {
                    NSBeep()
                    progress.localizedDescription = NSLocalizedString("Not Found", comment: "")
                }
                
                if UserDefaults.standard[.findClosesIndicatorWhenDone] {
                    indicator.dismiss(nil)
                }
            }
        }
    }
    
}
