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
//  © 2015-2023 1024jp
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
import Combine

final class FindPanelResultViewController: NSViewController, NSTableViewDataSource {
    
    // MARK: Public Properties
    
    weak var target: NSTextView?
    
    
    // MARK: Private Properties
    
    private var matches: [TextFindAllResult.Match] = []
    @objc private dynamic var findString: String?
    @objc private dynamic var resultMessage: String?
    @objc private dynamic var fontSize: CGFloat = NSFont.smallSystemFontSize
    
    private var fontSizeObserver: AnyCancellable?
    
    @IBOutlet private weak var disclosureButton: NSButton?
    @IBOutlet private weak var tableView: NSTableView?
    
    
    
    // MARK: -
    // MARK: View Controller Methods
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // set accessibility
        self.view.setAccessibilityElement(true)
        self.view.setAccessibilityRole(.group)
        self.view.setAccessibilityLabel("Find Result".localized)
    }
    
    
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        // make sure the disclosure button points up before open result
        // (The button may point down if the view was closed by dragging.)
        self.disclosureButton?.state = .on
        
        self.fontSizeObserver = UserDefaults.standard.publisher(for: .findResultViewFontSize, initial: true)
            .sink { [weak self] in
                self?.fontSize = $0
                self?.tableView?.reloadData()
            }
    }
    
    
    override func viewWillDisappear() {
        
        super.viewWillDisappear()
        
        // remove also find result highlights in the text view
        self.target?.unhighlight(nil)
        
        self.fontSizeObserver = nil
    }
    
    
    
    // MARK: Table View Data Source Protocol
    
    /// return number of row (required)
    func numberOfRows(in tableView: NSTableView) -> Int {
        
        (self.target != nil) ? self.matches.count : 0
    }
    
    
    /// return value of cell (required)
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        
        guard let match = self.matches[safe: row] else { return nil }
        
        switch tableColumn?.identifier {
            case NSUserInterfaceItemIdentifier("line"):
                return self.target?.lineNumber(at: match.range.location)
                
            default:
                let attrString = match.attributedLineString.mutable
                
                // truncate tail
                let paragraphStyle = NSParagraphStyle.default.mutable
                paragraphStyle.lineBreakMode = .byTruncatingTail
                attrString.addAttribute(.paragraphStyle, value: paragraphStyle, range: attrString.range)
                
                return attrString
        }
    }
    
    
    
    // MARK: Public Methods
    
    /// set new find matches
    func setResult(_ result: TextFindAllResult, for client: NSTextView) {
        
        self.target = client
        self.findString = result.findString
        self.matches = result.matches
        self.resultMessage = self.message
        
        self.tableView?.reloadData()
    }
    
    
    
    // MARK: Action Messages
    
    /// select matched string in text view
    @IBAction func selectMatch(_ tableView: NSTableView) {
        
        let row = tableView.clickedRow
        
        guard -1 < row, row < self.matches.count else { return }
        
        let range = self.matches[row].range
        
        // abandon if text became shorter than range to select
        guard
            let textView = self.target,
            textView.string.nsRange.upperBound >= range.upperBound
        else { return }
        
        textView.select(range: range)
        textView.window?.makeKeyAndOrderFront(nil)
    }
    
    
    
    // MARK: Private Methods
    
    private var message: String? {
        
        guard let documentName = (self.target?.window?.windowController?.document as? NSDocument)?.displayName else { return nil }
        
        switch self.matches.count {
            case 0:
                return String(localized: "No strings found in “\(documentName).”")
            case 1:
                return String(localized: "Found one string in “\(documentName).”")
            default:
                return String(localized: "Found \(self.matches.count) strings in “\(documentName).”")
        }
    }
}



extension FindPanelResultViewController {
    
    /// Increase result's font size.
    @IBAction func biggerFont(_ sender: Any?) {
        
        UserDefaults.standard[.findResultViewFontSize] += 1
    }
    
    
    /// Decrease result's font size.
    @IBAction func smallerFont(_ sender: Any?) {
        
        guard UserDefaults.standard[.findResultViewFontSize] > NSFont.smallSystemFontSize else { return }
        
        UserDefaults.standard[.findResultViewFontSize] -= 1
    }
    
    
    /// Restore result's font size to default.
    @IBAction func resetFont(_ sender: Any?) {
        
        UserDefaults.standard.restore(key: .findResultViewFontSize)
    }
}
