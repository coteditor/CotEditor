//
//  IncompatibleCharsViewController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2014-12-18.
//
//  ---------------------------------------------------------------------------
//
//  © 2004-2007 nakamuxu
//  © 2014-2019 1024jp
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

final class IncompatibleCharactersViewController: NSViewController, IncompatibleCharacterScannerDelegate {
    
    // MARK: Private Properties
    
    private var scanner: IncompatibleCharacterScanner? {
        
        return self.representedObject as? IncompatibleCharacterScanner
    }
    
    @objc private dynamic var incompatibleCharacters: [IncompatibleCharacter] = []
    @objc private dynamic var characterAvailable = false
    private var isVisible = false
    
    @IBOutlet private var incompatibleCharsController: NSArrayController?
    
    
    
    // MARK: -
    // MARK: View Controller Methods
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // set accessibility
        self.view.setAccessibilityElement(true)
        self.view.setAccessibilityRole(.group)
        self.view.setAccessibilityLabel("incompatible characters".localized)
    }
    
    
    /// update content before display
    override func viewWillAppear() {
        
        self.isVisible = true
        self.scanner?.scan()
        
        super.viewWillAppear()
    }
    
    
    /// clear incompatible characters markup
    override func viewDidDisappear() {
        
        self.isVisible = false
        self.scanner?.document?.textStorage.clearAllMarkup()
        
        super.viewDidDisappear()
    }
    
    
    /// set delegate
    override var representedObject: Any? {
        
        willSet {
            guard newValue is IncompatibleCharacterScanner else {
                assertionFailure("representedObject of \(self.className) must be an instance of \(IncompatibleCharacterScanner.self)")
                return
            }
            self.scanner?.delegate = nil
        }
        
        didSet {
            self.scanner?.delegate = self
            self.scanner?.invalidate()
        }
    }
    
    
    
    // MARK: Scanner Delegate
    
    /// update list constantly only if the table is visible
    func needsUpdateIncompatibleCharacter(_ document: Document) -> Bool {
        
        return self.isVisible
    }
    
    
    /// incompatible characters list was updated
    func document(_ document: Document, didUpdateIncompatibleCharacters incompatibleCharacters: [IncompatibleCharacter]) {
        
        self.incompatibleCharacters = incompatibleCharacters
        self.characterAvailable = !incompatibleCharacters.isEmpty
        
        let ranges = incompatibleCharacters.map { $0.range }
        
        document.textStorage.clearAllMarkup()
        document.textStorage.markup(ranges: ranges, lineEnding: document.lineEnding)
    }
    
    
    
    // MARK: Action Messages
    
    /// select correspondent char in text view
    @IBAction func selectCharacter(_ tableView: NSTableView) {
        
        guard
            tableView.clickedRow > -1,  // invalid click
            let incompatibles = self.incompatibleCharsController?.arrangedObjects as? [IncompatibleCharacter],
            let selectedIncompatible = incompatibles[safe: tableView.clickedRow],
            let editor = self.scanner?.document else { return }
        
        let range = selectedIncompatible.range
        editor.selectedRange = range
        
        // focus result
        // -> use textView's `selectedRange` since `range` is incompatible with CRLF
        if let textView = editor.textView {
            textView.scrollRangeToVisible(textView.selectedRange)
            textView.showFindIndicator(for: textView.selectedRange)
        }
    }
    
}



private extension NSTextStorage {
    
    /// change background color of pased-in ranges
    func markup(ranges: [NSRange], lineEnding: LineEnding = .lf) {
        
        guard let color = self.layoutManagers.first?.firstTextView?.textColor?.withAlphaComponent(0.2) else { return }
        
        for range in ranges {
            let viewRange = self.string.convert(range: range, from: lineEnding, to: .lf)
            
            for manager in self.layoutManagers {
                manager.addTemporaryAttribute(.backgroundColor, value: color, forCharacterRange: viewRange)
            }
        }
    }
    
    
    /// clear all background highlight (including text finder's highlights)
    func clearAllMarkup() {
        
        let range = self.string.nsRange
        
        for manager in self.layoutManagers {
            manager.removeTemporaryAttribute(.backgroundColor, forCharacterRange: range)
        }
    }
    
}
