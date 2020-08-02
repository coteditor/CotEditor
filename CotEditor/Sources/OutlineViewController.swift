//
//  OutlineViewController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-02-27.
//
//  ---------------------------------------------------------------------------
//
//  © 2018-2020 1024jp
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

import Combine
import Cocoa

/// outilneView column identifiers
private extension NSUserInterfaceItemIdentifier {
    
    static let title = NSUserInterfaceItemIdentifier("title")
}


final class OutlineViewController: NSViewController {
    
    // MARK: Private Properties
    
    private var outlineItems: [OutlineItem] = [] {
        
        didSet {
            guard outlineItems != oldValue, self.isViewShown else { return }
            
            self.outlineView?.reloadData()
            self.invalidateCurrentLocation()
        }
    }
    
    private var documentObserver: AnyCancellable?
    private var syntaxStyleObserver: AnyCancellable?
    private var selectionObserver: AnyCancellable?
    private var fontSizeObserver: UserDefaultsObservation?
    private var isOwnSelectionChange = false
    
    @IBOutlet private weak var outlineView: NSOutlineView?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    override var representedObject: Any? {
        
        didSet {
            assert(representedObject == nil || representedObject is Document,
                   "representedObject of \(self.className) must be an instance of \(Document.className())")
            
            self.observeDocument()
            self.observeSyntaxStyle()
            
            self.outlineItems = (representedObject as? Document)?.syntaxParser.outlineItems ?? []
        }
    }
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // set accessibility
        self.view.setAccessibilityElement(true)
        self.view.setAccessibilityRole(.group)
        self.view.setAccessibilityLabel("outline".localized)
    }
    
    
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        self.outlineItems = self.document?.syntaxParser.outlineItems ?? []
        
        self.invalidateCurrentLocation()
        
        // make sure the last observer is invalidated before a new one is set to the property.
        // -> Although the previous observer must be invalidated in `viewDidDisappear()`,
        //    it can remain somehow and, consequently, cause a crash. (2018-05 macOS 10.13)
        self.selectionObserver = NotificationCenter.default.publisher(for: NSTextView.didChangeSelectionNotification)
            .map { $0.object as! NSTextView }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (textView) in
                guard let self = self else { return assertionFailure() }
                guard textView.window == self.view.window else { return }
                
                // avoid updating outline item selection before finishing outline parse
                // -> Otherwise, a wrong item can be selected because of using the outdated outline ranges.
                //    You can ignore text selection change at this time point as the outline selection will be updated when the parse finished.
                guard
                    !textView.hasMarkedText(),
                    let textStorage = textView.textStorage,
                    !textStorage.editedMask.contains(.editedCharacters)
                    else { return }
                
                self.invalidateCurrentLocation(textView: textView)
            }
        
        self.fontSizeObserver?.invalidate()
        self.fontSizeObserver = UserDefaults.standard.observe(key: .outlineViewFontSize) { [weak self] _ in
            self?.outlineView?.reloadData()
            self?.invalidateCurrentLocation()
        }
    }
    
    
    override func viewDidDisappear() {
        
        super.viewDidDisappear()
        
        self.selectionObserver = nil
        
        self.fontSizeObserver?.invalidate()
        self.fontSizeObserver = nil
    }
    
    
    
    // MARK: Actions
    
    /// Item in outlineView was clicked.
    @IBAction func selectOutlineItem(_ outlineView: NSOutlineView) {
        
        self.selectOutlineItem(at: outlineView.clickedRow)
    }
    
    
    
    // MARK: Private Methods
    
    /// Current outline items.
    private var document: Document? {
        
        return self.representedObject as? Document
    }
    
    
    /// Paragraph style for outline items.
    private var itemParagraphStyle: NSParagraphStyle = {
        
        let paragraphStyle = NSParagraphStyle.default.mutable
        paragraphStyle.lineBreakMode = .byTruncatingTail
        
        return paragraphStyle
    }()
    
    
    /// Select correspondence range of the outline item in textView.
    ///
    /// - Parameter row: The index of outline items to select.
    private func selectOutlineItem(at row: Int) {
        
        guard
            let item = self.outlineItems[safe: row],
            item.title != .separator
            else { return }
        
        // abandon if text became shorter than range to select
        guard
            let textView = self.document?.textView,
            textView.string.nsRange.upperBound >= item.range.upperBound
            else { return }
        
        textView.selectedRange = item.range
        textView.scrollRangeToVisible(item.range)
        textView.showFindIndicator(for: item.range)
    }
    
    
    /// Update document observation for syntax style
    private func observeDocument() {
        
        self.documentObserver = nil
        
        guard let document = self.document else { return assertionFailure() }
        
        self.documentObserver = NotificationCenter.default.publisher(for: Document.didChangeSyntaxStyleNotification, object: document)
            .map { $0.object as! Document }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (document) in
                self?.observeSyntaxStyle()
                self?.outlineItems = document.syntaxParser.outlineItems
            }
    }
    
    
    /// Update syntax style observation for outline menus
    private func observeSyntaxStyle() {
        
        self.syntaxStyleObserver = nil
        
        guard let syntaxParser = self.document?.syntaxParser else { return assertionFailure() }
        
        self.syntaxStyleObserver = NotificationCenter.default.publisher(for: SyntaxParser.didUpdateOutlineNotification, object: syntaxParser)
            .map { $0.object as! SyntaxParser }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (parser) in
                self?.outlineItems = parser.outlineItems
            }
    }
    
    
    /// Update row selection to synchronize with editor's cursor location.
    ///
    /// - Parameter textView: The text view to apply the selection. when nil, the current focused editor will be used (the document can have multiple editors).
    private func invalidateCurrentLocation(textView: NSTextView? = nil) {
        
        guard
            self.isViewShown,
            let outlineView = self.outlineView
            else { return }
        
        guard
            let textView = textView ?? self.document?.textView,
            let row = self.outlineItems.indexOfItem(for: textView.selectedRange, allowsSeparator: false),
            outlineView.numberOfRows > row
            else { return outlineView.deselectAll(nil) }
        
        self.isOwnSelectionChange = true
        outlineView.selectRowIndexes([row], byExtendingSelection: false)
        outlineView.scrollRowToVisible(row)
    }
    
}



extension OutlineViewController: NSOutlineViewDelegate {
    
    /// selection changed
    func outlineViewSelectionDidChange(_ notification: Notification) {
        
        defer {
            self.isOwnSelectionChange = false
        }
        
        guard
            !self.isOwnSelectionChange,
            let outlineView = notification.object as? NSOutlineView
            else { return }
        
        self.selectOutlineItem(at: outlineView.selectedRow)
    }
    
    
    /// avoid selecting separator item
    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        
        return (item as? OutlineItem)?.title != .separator
    }
    
}



extension OutlineViewController: NSOutlineViewDataSource {
    
    /// return number of child items
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        
        return self.outlineItems.count
    }
    
    
    /// return if item is expandable
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        
        return false
    }
    
    
    /// return child items
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        
        return self.outlineItems[index]
    }
    
    
    /// return suitable item for cell to display
    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        
        guard
            let identifier = tableColumn?.identifier,
            let outlineItem = item as? OutlineItem
            else { return nil }
        
        switch identifier {
            case .title:
                let fontSize = UserDefaults.standard[.outlineViewFontSize]
                let font = outlineView.font.flatMap { NSFont(name: $0.fontName, size: fontSize) } ?? .systemFont(ofSize: fontSize)
                
                return outlineItem.attributedTitle(for: font, attributes: [.paragraphStyle: self.itemParagraphStyle])
            
            default:
                preconditionFailure()
        }
    }
    
}



extension OutlineViewController {
    
    /// Increase outline view's font size.
    @IBAction func biggerFont(_ sender: Any?) {
        
        UserDefaults.standard[.outlineViewFontSize] += 1
    }
    
    
    /// Decrease outline view's font size.
    @IBAction func smallerFont(_ sender: Any?) {
        
        guard UserDefaults.standard[.outlineViewFontSize] > NSFont.smallSystemFontSize else { return }
        
        UserDefaults.standard[.outlineViewFontSize] -= 1
    }
    
    
    /// Restore outline view's font size to default.
    @IBAction func resetFont(_ sender: Any?) {
        
        UserDefaults.standard.restore(key: .outlineViewFontSize)
    }
    
}
