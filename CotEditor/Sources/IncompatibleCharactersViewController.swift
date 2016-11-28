/*
 
 IncompatibleCharsViewController.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2014-12-18.
 
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014-2016 1024jp
 
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

final class IncompatibleCharactersViewController: NSViewController, IncompatibleCharacterScannerDelegate {
    
    // MARK: Private Properties
    
    private weak var scanner: IncompatibleCharacterScanner? {
        
        return self.representedObject as? IncompatibleCharacterScanner
    }
    
    private dynamic var incompatibleCharacters: [IncompatibleCharacter] = []
    private dynamic var isCharacterAvailable = false
    private var isVisible = false
    
    @IBOutlet private var incompatibleCharsController: NSArrayController?
    
    
    
    // MARK:
    // MARK: Lifecycle
    
    override var nibName: String? {
        
        return "IncompatibleCharsView"
    }
    
    
    
    // MARK: View Controller Methods
    
    /// update content before display
    override func viewWillAppear() {
        
        self.isVisible = true
        self.scanner?.scan()
        
        super.viewWillAppear()
    }
    
    
    /// clear incompatible chars markup
    override func viewDidDisappear() {
        
        self.isVisible = false
        self.scanner?.document?.textStorage.clearAllMarkup()
        
        super.viewDidDisappear()
    }
    
    
    /// set delegate
    override var representedObject: Any? {
        
        willSet (newObject) {
            guard newObject is IncompatibleCharacterScanner else {
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
    func document(_ document: Document, didUpdateIncompatibleCharacters incompatibleCharacers: [IncompatibleCharacter]) {
        
        self.incompatibleCharacters = incompatibleCharacers
        self.isCharacterAvailable = !incompatibleCharacers.isEmpty
        
        let ranges = incompatibleCharacers.map { $0.range }
        
        document.textStorage.clearAllMarkup()
        document.textStorage.markup(ranges: ranges, lineEnding: document.lineEnding)
    }
    
    
    
    // MARK: Action Messages
    
    /// select correspondent char in text view
    @IBAction func selectCharacter(_ table: NSTableView) {
        
        guard
            table.clickedRow > -1,  // invalid click
            let incompatibles = self.incompatibleCharsController?.arrangedObjects as? [IncompatibleCharacter],
            let selectedIncompatible = incompatibles[safe: table.clickedRow],
            let editor = self.scanner?.document else { return }
        
        let range = selectedIncompatible.range
        editor.selectedRange = range
        
        // focus result
        // -> use textView's `selectedRange` since `range` is incompatible with CR/LF
        if let textView = editor.textView {
            textView.scrollRangeToVisible(textView.selectedRange)
            textView.showFindIndicator(for: textView.selectedRange)
        }
    }
    
}



private extension NSTextStorage {
    
    /// change background color of pased-in ranges (incompatible chars scannar may use this method)
    func markup(ranges: [NSRange], lineEnding: LineEnding = .LF) {
        
        guard let color = self.layoutManagers.first?.firstTextView?.textColor?.withAlphaComponent(0.2) else { return }
        
        for range in ranges {
            let viewRange = self.string.convert(from: lineEnding, to: .LF, range: range)
            
            for manager in self.layoutManagers {
                manager.addTemporaryAttribute(NSBackgroundColorAttributeName, value: color, forCharacterRange: viewRange)
            }
        }
    }
    
    
    /// clear all background highlight (including text finder's highlights)
    func clearAllMarkup() {
        
        let range = self.string.nsRange
        
        for manager in self.layoutManagers {
            manager.removeTemporaryAttribute(NSBackgroundColorAttributeName, forCharacterRange: range)
        }
    }
    
}
