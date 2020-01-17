//
//  FindPanelResultViewController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2015-01-04.
//
//  ---------------------------------------------------------------------------
//
//  © 2015-2020 1024jp
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

/// the maximum number of characters to add to the left of the matched string
private let maxLeftMargin = 32

/// maximal number of characters for the result line
private let maxMatchedStringLength = 256



final class FindPanelResultViewController: NSViewController, NSTableViewDataSource {
    
    // MARK: Public Properties
    
    weak var target: NSTextView?
    
    
    // MARK: Private Properties
    
    private var results = [TextFindResult]()
    @objc private dynamic var findString: String?
    @objc private dynamic var resultMessage: String?
    
    @IBOutlet private weak var disclosureButton: NSButton?
    @IBOutlet private weak var tableView: NSTableView?
    
    
    
    // MARK: -
    // MARK: View Controller Methods
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // set accessibility
        self.view.setAccessibilityElement(true)
        self.view.setAccessibilityRole(.group)
        self.view.setAccessibilityLabel("find result".localized)
    }
    
    /// prepare for display
    override func viewWillAppear() {
        
        // make sure the disclosure button points up before open result
        // (The buttom may point down if the view was closed by dragging.)
        self.disclosureButton?.state = .on
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
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        
        guard row < self.results.count else { return nil }
        
        let result = self.results[row]
        
        switch tableColumn?.identifier {
        case NSUserInterfaceItemIdentifier("line"):
            return result.lineNumber
            
        default:
            let lineAttrString = result.attributedLineString.mutable
            
            // truncate
            let leadingOverflow = result.inlineRange.location - maxLeftMargin
            if leadingOverflow > 0 {
                lineAttrString.replaceCharacters(in: NSRange(..<leadingOverflow), with: "…")
            }
            if lineAttrString.length > maxMatchedStringLength {
                lineAttrString.replaceCharacters(in: NSRange(maxMatchedStringLength..<lineAttrString.length), with: "…")
            }
            
            // truncate tail
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineBreakMode = .byTruncatingTail
            lineAttrString.addAttribute(.paragraphStyle, value: paragraphStyle, range: lineAttrString.range)
            
            return lineAttrString
        }
    }
    
    
    
    // MARK: Public Methods
    
    /// set new find results
    func setResults(_ results: [TextFindResult], findString: String, target: NSTextView) {
        
        self.target = target
        self.findString = findString
        self.results = results
        
        let documentName = (target.window?.windowController?.document as? NSDocument)?.displayName ?? "Unknown"  // This should never be nil.
        let resultMessage: String = {
            switch results.count {
            case 0:
                return String(format: "No strings found in “%@”.".localized, documentName)
            case 1:
                return String(format: "Found one string in “%@”.".localized, documentName)
            default:
                let countStr = String.localizedStringWithFormat("%li", results.count)  // localize to add thousand separators
                return String(format: "Found %@ strings in “%@”.".localized, countStr, documentName)
            }
        }()
        self.resultMessage = resultMessage
        
        // feedback for VoiceOver
        if let findPanel = self.view.window {
            NSAccessibility.post(element: findPanel, notification: .announcementRequested, userInfo: [.announcement: resultMessage])
        }
        
        self.tableView?.reloadData()
    }
    
    
    /// remove current highlight by Find All
    private func unhighlight() {
        
        guard let textView = self.target else { return }
        
        textView.layoutManager?.removeTemporaryAttribute(.backgroundColor, forCharacterRange: textView.string.nsRange)
    }
    
    
    
    // MARK: Action Messages
    
    /// select matched string in text view
    @IBAction func selectMatch(_ tableView: NSTableView) {
        
        let row = tableView.clickedRow
        
        guard -1 < row, row < self.results.count else { return }
        
        let range = self.results[row].range
        
        // abandon if text became shorter than range to select
        guard
            let textView = self.target,
            textView.string.nsRange.upperBound >= range.upperBound
            else { return }
        
        textView.selectedRange = range
        textView.scrollRangeToVisible(range)
        textView.showFindIndicator(for: range)
    }
    
}
