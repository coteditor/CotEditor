//
//  MultipleReplacement+TextView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-03-26.
//
//  ---------------------------------------------------------------------------
//
//  © 2018-2019 1024jp
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

extension MultipleReplacement {
    
    /// highlight all matches in the textView
    func highlight(inSelection: Bool, completionHandler: @escaping (_ resultMessage: String) -> Void) {
        
        guard let textView = TextFinder.shared.client else {
                NSSound.beep()
                return
            }
        
        let string = textView.string.immutable
        let selectedRanges = textView.selectedRanges as! [NSRange]
        
        textView.isEditable = false
        
        // setup progress sheet
        let progress = TextFindProgress(format: .replacement)
        let indicator = ProgressViewController.instantiate(storyboard: "ProgressView")
        indicator.setup(progress: progress, message: "Highlight".localized)
        textView.viewControllerForSheet?.presentAsSheet(indicator)
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let result = self.find(string: string, ranges: selectedRanges, inSelection: inSelection) { (stop) in
                guard !progress.isCancelled else {
                    stop = true
                    return
                }
                
                progress.completedUnitCount += 1
            }
            
            DispatchQueue.main.async {
                textView.isEditable = true
                
                guard !progress.isCancelled else {
                    indicator.dismiss(nil)
                    return
                }
                
                if !result.isEmpty {
                    // apply to the text view
                    if let layoutManager = textView.layoutManager {
                        layoutManager.removeTemporaryAttribute(.backgroundColor, forCharacterRange: string.nsRange)
                        let color = NSColor.textHighlighterColor
                        for range in result {
                            layoutManager.addTemporaryAttribute(.backgroundColor, value: color, forCharacterRange: range)
                        }
                    }
                    
                } else {
                    NSSound.beep()
                    progress.localizedDescription = "Not Found".localized
                }
                
                let resultMessage = !result.isEmpty
                    ? String(format: "%@ found".localized, String.localizedStringWithFormat("%li", result.count))
                    : "Not Found".localized
                
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
        let indicator = ProgressViewController.instantiate(storyboard: "ProgressView")
        indicator.setup(progress: progress, message: "Replace All".localized)
        textView.viewControllerForSheet?.presentAsSheet(indicator)
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let result = self.replace(string: string, ranges: selectedRanges, inSelection: inSelection) { (stop) in
                guard !progress.isCancelled else {
                    stop = true
                    return
                }
                
                progress.completedUnitCount += 1
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
                                     actionName: "Replace All".localized)
                } else {
                    NSSound.beep()
                    progress.localizedDescription = "Not Found".localized
                }
                
                let resultMessage = (result.count > 0)
                    ? String(format: "%@ replaced".localized, String.localizedStringWithFormat("%li", result.count))
                    : "Not Replaced".localized
                
                indicator.done()
                
                if UserDefaults.standard[.findClosesIndicatorWhenDone] {
                    indicator.dismiss(nil)
                }
                
                completionHandler(resultMessage)
            }
        }
    }
    
}
