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
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Cocoa

class IncompatibleCharactersViewController: NSViewController, CEIncompatibleCharacterScannerDelegate, NSTableViewDelegate {
    
    // MARK: Private Properties
    
    private weak var scanner: CEIncompatibleCharacterScanner? {
        
        return self.representedObject as? CEIncompatibleCharacterScanner
    }
    
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
        self.scanner?.document?.editor?.clearAllMarkup()
        
        super.viewDidDisappear()
    }
    
    
    /// set delegate
    override var representedObject: AnyObject? {
        
        willSet (newObject) {
            guard newObject is CEIncompatibleCharacterScanner else {
                assertionFailure("representedObject of \(self.className) must be an instance of \(CEIncompatibleCharacterScanner.className())")
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
    func documentNeedsUpdateIncompatibleCharacter(_ document: NSDocument) -> Bool {
        
        return self.isVisible
    }
    
    
    /// incompatible characters list was updated
    func document(_ document: NSDocument, didUpdate incompatibleCharacers: [CEIncompatibleCharacter]) {
        
        self.incompatibleCharsController!.content = incompatibleCharacers
        self.isCharacterAvailable = !incompatibleCharacers.isEmpty
        
        var ranges = [NSValue]()
        for incompatible in incompatibleCharacers {
            ranges.append(NSValue(range: incompatible.range))
        }
        
        guard let editor = (document as? CEDocument)?.editor else { return }
        
        editor.clearAllMarkup()
        editor.markupRanges(ranges)
    }
    
    
    
    // MARK: Table View Delegate
    
    /// select correspondent char in text view
    func tableViewSelectionDidChange(_ notification: Notification) {
        
        guard let selectedIncompatible = self.incompatibleCharsController?.selectedObjects.first as? CEIncompatibleCharacter else { return }
        guard let editor = self.scanner?.document?.editor else { return }
        
        let range = selectedIncompatible.range
        editor.setSelectedRange(range)
        
        // focus result
        // -> use textView's `selectedRange` since `range` is incompatible with CR/LF
        if let textView = editor.focusedTextView {
            textView.scrollRangeToVisible(textView.selectedRange())
            textView.showFindIndicator(for: textView.selectedRange())
        }
    }
    
}
