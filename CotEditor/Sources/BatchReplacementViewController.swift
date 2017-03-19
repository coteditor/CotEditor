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
    
    // MARK: Private Properties
    
    private dynamic var hasInvalidSetting = false
    private dynamic var canPerform = true
    private dynamic var resultMessage: String?
    
    @IBOutlet private weak var tableView: NSTableView?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    // MARK: View Controller Methods
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // set blank
        let batchReplacement = BatchReplacement(name: NSLocalizedString("Untitled", comment: ""))
        batchReplacement.replacements.append(Replacement())
        self.representedObject = batchReplacement
        
        // -> Use obsevation since the delecation is already set to DefinitionTableViewDelegate
        NotificationCenter.default.addObserver(self, selector: #selector(validateObject), name: .NSTableViewSelectionDidChange, object: self.tableView)
    }
    
    
    /// reset previous search result
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        self.resultMessage = nil
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
    
    ///
    @IBAction func highlight(_ sender: AnyObject?) {
        
        self.endEditing()
        self.validateObject()
        self.resultMessage = nil
        
        guard
            self.canPerform,
            let textView = TextFinder.shared.client, textView.isEditable,
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
        let progress = TextFindProgress(format: .find, totalUnitCount: batchReplacement.replacements.count)
        let indicator = ProgressViewController(progress: progress, message: NSLocalizedString("Batch Replace", comment: ""))
        textView.viewControllerForSheet?.presentViewControllerAsSheet(indicator)
        
        DispatchQueue.global().async { [weak self] in
            let result = batchReplacement.find(string: string, ranges: textView.selectedRanges as [NSRange], inSelection: inSelection) { (count, stop) in
                guard !progress.isCancelled else {
                    stop = true
                    return
                }
                
                progress.needsUpdateDescription(count: count)
             }
            
            DispatchQueue.main.async {
                textView.isEditable = true
                
                guard !progress.isCancelled else {
                    indicator.dismiss(nil)
                    return
                }
                
                if result.count > 0 {
                    // apply to the text view
                    if let layoutManager = textView.layoutManager {
                        layoutManager.removeTemporaryAttribute(NSBackgroundColorAttributeName, forCharacterRange: string.nsRange)
                        let color = TextFinder.shared.highlightColor
                        for range in result {
                            layoutManager.addTemporaryAttribute(NSBackgroundColorAttributeName,
                                                                value: color, forCharacterRange: range)
                        }
                    }
                    
                } else {
                    NSBeep()
                    progress.localizedDescription = NSLocalizedString("Not Found", comment: "")
                }
                
                self?.resultMessage = {
                    guard result.count > 0 else { return NSLocalizedString("Not Found", comment: "") }
                    
                    return String(format: NSLocalizedString("%@ found", comment: ""),
                                  String.localizedStringWithFormat("%li", result.count))
                }()
                
                if UserDefaults.standard[.findClosesIndicatorWhenDone] {
                    indicator.dismiss(nil)
                }
            }
        }
    }
    
    
    /// perform batch replacement
    @IBAction func batchReplace(_ sender: Any?) {
        
        self.endEditing()
        self.validateObject()
        self.resultMessage = nil
        
        guard
            self.canPerform,
            let textView = TextFinder.shared.client, textView.isEditable,
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
        let progress = TextFindProgress(format: .replacement, totalUnitCount: batchReplacement.replacements.count)
        let indicator = ProgressViewController(progress: progress, message: NSLocalizedString("Batch Replace", comment: ""))
        textView.viewControllerForSheet?.presentViewControllerAsSheet(indicator)
        
        DispatchQueue.global().async { [weak self] in
            let result = batchReplacement.replace(string: string, ranges: textView.selectedRanges as [NSRange], inSelection: inSelection) { (count, stop) in
                guard !progress.isCancelled else {
                    stop = true
                    return
                }
                
                progress.needsUpdateDescription(count: count)
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
                
                self?.resultMessage = {
                    guard result.count > 0 else { return NSLocalizedString("Not Replaced", comment: "") }
                    
                    return String(format: NSLocalizedString("%@ replaced", comment: ""),
                                  String.localizedStringWithFormat("%li", result.count))
                }()
                
                if UserDefaults.standard[.findClosesIndicatorWhenDone] {
                    indicator.dismiss(nil)
                }
            }
        }
    }
    
    
    
    // MARK: Private Methods
    
    @objc private func validateObject() {
        
        guard let batchReplacement = self.representedObject as? BatchReplacement else { return }
        
        self.hasInvalidSetting = batchReplacement.replacements.contains { $0.localizedError != nil }
        
        self.canPerform = batchReplacement.replacements.contains { replacement in
            do {
                try replacement.validate()
            } catch {
                return false
            }
            return true
        }
    }
    
}
