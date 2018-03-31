//
//  BatchReplacement+TextView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-03-26.
//
//  ---------------------------------------------------------------------------
//
//  © 2018 1024jp
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

import AppKit

extension BatchReplacement {
    
    /// highlight all matches in the textView
    func highlight(inSelection: Bool, completionHandler: @escaping (_ resultMessage: String) -> Void) {
        
        guard
            let textView = TextFinder.shared.client, textView.isEditable,
            textView.window?.attachedSheet == nil
            else {
                NSSound.beep()
                return
            }
        
        let string = textView.string.immutable
        let selectedRanges = textView.selectedRanges as! [NSRange]
        
        textView.isEditable = false
        
        // setup progress sheet
        let progress = TextFindProgress(format: .replacement)
        let indicator = ProgressViewController(progress: progress, message: NSLocalizedString("Highlight", comment: ""))
        textView.viewControllerForSheet?.presentViewControllerAsSheet(indicator)
        
        DispatchQueue.global().async { [weak self] in
            guard let strongSelf = self else { return }
            
            let result = strongSelf.find(string: string, ranges: selectedRanges, inSelection: inSelection) { (count, stop) in
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
                        layoutManager.removeTemporaryAttribute(.backgroundColor, forCharacterRange: string.nsRange)
                        let color = TextFinder.shared.highlightColor
                        for range in result {
                            layoutManager.addTemporaryAttribute(.backgroundColor, value: color, forCharacterRange: range)
                        }
                    }
                    
                } else {
                    NSSound.beep()
                    progress.localizedDescription = NSLocalizedString("Not Found", comment: "")
                }
                
                let resultMessage: String = {
                    guard result.count > 0 else { return NSLocalizedString("Not Found", comment: "") }
                    
                    return String(format: NSLocalizedString("%@ found", comment: ""),
                                  String.localizedStringWithFormat("%li", result.count))
                }()
                
                indicator.done()
                
                if UserDefaults.standard[.findClosesIndicatorWhenDone] {
                    indicator.dismiss(nil)
                }
                
                completionHandler(resultMessage)
            }
        }
    }
    
    
    /// replace all matches in the textView
    func replaceAll(inSelection: Bool, completionHandler: @escaping (_ resultMessage: String) -> Void) {
        
        guard
            let textView = TextFinder.shared.client, textView.isEditable,
            textView.window?.attachedSheet == nil
            else {
                NSSound.beep()
                return
            }

        let string = textView.string.immutable
        let selectedRanges = textView.selectedRanges as! [NSRange]
        
        textView.isEditable = false
        
        // setup progress sheet
        let progress = TextFindProgress(format: .replacement)
        let indicator = ProgressViewController(progress: progress, message: NSLocalizedString("Replace All", comment: ""))
        textView.viewControllerForSheet?.presentViewControllerAsSheet(indicator)
        
        DispatchQueue.global().async { [weak self] in
            guard let strongSelf = self else { return }
            
            let result = strongSelf.replace(string: string, ranges: selectedRanges, inSelection: inSelection) { (count, stop) in
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
                                     actionName: NSLocalizedString("Replace All", comment: ""))
                } else {
                    NSSound.beep()
                    progress.localizedDescription = NSLocalizedString("Not Found", comment: "")
                }
                
                let resultMessage: String = {
                    guard result.count > 0 else { return NSLocalizedString("Not Replaced", comment: "") }
                    
                    return String(format: NSLocalizedString("%@ replaced", comment: ""),
                                  String.localizedStringWithFormat("%li", result.count))
                }()
                
                indicator.done()
                
                if UserDefaults.standard[.findClosesIndicatorWhenDone] {
                    indicator.dismiss(nil)
                }
                
                completionHandler(resultMessage)
            }
        }
    }
    
}
