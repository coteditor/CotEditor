/*
 
 FindPanelResultViewController.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2015-01-04.
 
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

/// the maximum number of characters to add to the left of the matched string
private let MaxLeftMargin = 32

/// maximal number of characters for the result line
private let MaxMatchedStringLength = 256



final class FindPanelResultViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    
    // MARK: Public Properties
    
     weak var target: NSTextView? {
        // keep TextContainer as `weak` instaed to avoid handling unsafe_unretained TextView
        set (target) {
            self.layoutManager = target?.layoutManager
        }
        get {
            return self.layoutManager?.firstTextView
        }
    }
    
    
    // MARK: Private Properties
    
    private var results = [TextFindResult]()
    private dynamic var findString: String?
    private dynamic var resultMessage: String?
    
    private weak var layoutManager: NSLayoutManager?
    
    @IBOutlet private weak var disclosureButton: NSButton?
    @IBOutlet private weak var tableView: NSTableView?
    
    
    
    // MARK:
    // MARK: View Controller Methods
    
    /// prepare for display
    override func viewWillAppear() {
        
        // make sure the disclosure button points up before open result
        // (The buttom may point down if the view was closed by dragging.)
        self.disclosureButton?.state = NSOnState
    }
    
    
    /// remove also find result highlights in the text view when result view disappear
    override func viewWillDisappear() {
        
         self.unhighlight()
    }
    
    
    
    // MARK: Table View Data Source Protocol
    
    /// return number of row (required)
    func numberOfRows(in tableView: NSTableView) -> Int {
        
        return self.results.count
    }
    
    
    /// return value of cell (required)
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        
        guard row < self.results.count else { return nil }
        
        let result = self.results[row]
        
        switch tableColumn?.identifier {
        case "line"?:
            return result.lineNumber
            
        default:
            let lineAttrString = result.attributedLineString.mutableCopy() as! NSMutableAttributedString
            
            // trim
            if result.lineRange.location > MaxLeftMargin {
                let diff = result.lineRange.location - MaxLeftMargin
                lineAttrString.replaceCharacters(in: NSRange(location: 0, length: diff), with: "…")
            }
            if lineAttrString.length > MaxMatchedStringLength {
                let extra = lineAttrString.length - MaxMatchedStringLength
                lineAttrString.replaceCharacters(in: NSRange(location: MaxMatchedStringLength, length: extra), with: "…")
            }
            
            // truncate tail
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineBreakMode = .byTruncatingTail
            lineAttrString.addAttribute(NSParagraphStyleAttributeName, value: paragraphStyle, range: lineAttrString.string.nsRange)
            
            return lineAttrString
        }
    }
    
    
    
    // MARK: Table View Delegate
    
    /// select matched string in text view
    func tableViewSelectionDidChange(_ notification: Notification) {
        
        guard let tableView = notification.object as? NSTableView,
              let textView = self.target else { return }
        
        let row = tableView.selectedRow
        
        guard -1 < row && row < self.results.count else { return }
        
        let range = self.results[row].range
        
        DispatchQueue.main.async {
            textView.setSelectedRange(range)
            textView.centerSelectionInVisibleArea(nil)
            textView.showFindIndicator(for: range)
        }
    }
    
    
    
    // MARK: Public Methods
    
    /// set new find results
    func setResults(_ results: [TextFindResult], findString: String, target: NSTextView) {
        
        self.target = target
        self.findString = findString
        self.results = results
        
        let documentName = (target.window?.windowController?.document as? NSDocument)?.displayName ?? "Unknown"  // This should never be nil.
        switch results.count {
        case 0:
            self.resultMessage = String(format: NSLocalizedString("No strings found in “%@”.", comment: ""), documentName)
        case 1:
            self.resultMessage = String(format: NSLocalizedString("Found one string in “%@”.", comment: ""), documentName)
        default:
            let countStr = String.localizedStringWithFormat("%li", results.count)  // localize to add thousand separators
            self.resultMessage = String(format: NSLocalizedString("Found %@ strings in “%@”.", comment: ""), countStr, documentName)
        }
        
        self.tableView?.reloadData()
    }
    
    
    /// remove current highlight by Find All
    private func unhighlight() {
        
        guard let textView = self.target else { return }
        
        textView.layoutManager?.removeTemporaryAttribute(NSBackgroundColorAttributeName, forCharacterRange: textView.string!.nsRange)
    }
    
}
