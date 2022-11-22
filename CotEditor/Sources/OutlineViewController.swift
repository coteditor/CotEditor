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
//  © 2018-2022 1024jp
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

/// outlineView column identifiers
private extension NSUserInterfaceItemIdentifier {
    
    static let title = NSUserInterfaceItemIdentifier("title")
}


final class OutlineViewController: NSViewController {
    
    // MARK: Private Properties
    
    private var outlineItems: [OutlineItem] = [] {
        
        didSet {
            guard outlineItems != oldValue, self.isViewShown else { return }
            
            self.filterItems(with: self.filterString)
            self.outlineView?.reloadData()
            self.invalidateCurrentLocation()
        }
    }
    
    private var filteredOutlineItems: [OutlineItem] = []  { didSet { self.outlineView?.reloadData() } }
    @objc dynamic var filteringMessage: String?
    
    private var documentObserver: AnyCancellable?
    private var syntaxStyleObserver: AnyCancellable?
    private var selectionObserver: AnyCancellable?
    private var fontSizeObserver: AnyCancellable?
    private var isOwnSelectionChange = false
    
    @IBOutlet private weak var outlineView: NSOutlineView?
    @IBOutlet private weak var searchField: NSSearchField?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    override var representedObject: Any? {
        
        didSet {
            assert(representedObject == nil || representedObject is Document,
                   "representedObject of \(self.className) must be an instance of \(Document.className())")
            
            self.observeDocument()
            self.observeSyntaxStyle()
        }
    }
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // set accessibility
        self.view.setAccessibilityElement(true)
        self.view.setAccessibilityRole(.group)
        self.view.setAccessibilityLabel("Outline".localized)
    }
    
    
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        // workaround a long-standing issue in single column table views (2022-09, macOS 13)
        // cf. [#1365](https://github.com/coteditor/CotEditor/pull/1365)
        self.outlineView?.sizeLastColumnToFit()
        
        self.fontSizeObserver = UserDefaults.standard.publisher(for: .outlineViewFontSize, initial: true)
            .sink { [weak self] _ in
                self?.outlineView?.reloadData()
                self?.invalidateCurrentLocation()
            }
        
        self.selectionObserver = NotificationCenter.default.publisher(for: NSTextView.didChangeSelectionNotification)
            .map { $0.object as! NSTextView }
            .filter { [weak self] in $0.textStorage == self?.document?.textStorage }
            .filter { !$0.hasMarkedText() }
            // avoid updating outline item selection before finishing outline parse
            // -> Otherwise, a wrong item can be selected because of using the outdated outline ranges.
            //    You can ignore text selection change at this time point as the outline selection will be updated when the parse finished.
            .filter { $0.textStorage?.editedMask.contains(.editedCharacters) == false }
            .debounce(for: .seconds(0.05), scheduler: RunLoop.main)
            .sink { [weak self] in self?.invalidateCurrentLocation(textView: $0) }
    }
    
    
    override func viewDidDisappear() {
        
        super.viewDidDisappear()
        
        self.selectionObserver = nil
        self.fontSizeObserver = nil
    }
    
    
    
    // MARK: Actions
    
    /// Item in outlineView was clicked.
    @IBAction func selectOutlineItem(_ sender: NSOutlineView) {
        
        self.selectOutlineItem(at: sender.clickedRow)
    }
    
    
    /// Search field text did update.
    @IBAction func searchFieldDidUpdate(_ sender: NSSearchField) {
        
        self.filterItems(with: sender.stringValue)
    }
    
    
    
    // MARK: Private Methods
    
    /// Current outline items.
    private var document: Document? {
        
        return self.representedObject as? Document
    }
    
    
    /// User input string for filtering.
    private var filterString: String {
        
        self.searchField?.stringValue ?? ""
    }
    
    
    /// Paragraph style for outline items.
    private let itemParagraphStyle: NSParagraphStyle = {
        
        let paragraphStyle = NSParagraphStyle.default.mutable
        paragraphStyle.lineBreakMode = .byTruncatingTail
        
        return paragraphStyle
    }()
    
    
    /// Select correspondence range of the outline item in textView.
    ///
    /// - Parameter row: The index of the outline item to select.
    private func selectOutlineItem(at row: Int) {
        
        guard
            let item = self.filterString.isEmpty
                ? self.outlineItems[safe: row]
                : self.filteredOutlineItems[safe: row],
            item.title != .separator
        else { return }
        
        // cancel if text became shorter than range to select
        guard
            let textView = self.document?.textView,
            item.range.upperBound <= textView.string.length
        else { return }
        
        textView.selectedRange = item.range
        textView.centerSelectionInVisibleArea(self)
    }
    
    
    /// Update document observation for syntax style
    private func observeDocument() {
        
        self.documentObserver = nil
        
        guard let document = self.document else { return assertionFailure() }
        
        self.documentObserver = document.didChangeSyntaxStyle
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.observeSyntaxStyle() }
    }
    
    
    /// Update syntax style observation for outline
    private func observeSyntaxStyle() {
        
        self.syntaxStyleObserver = nil
        
        guard let syntaxParser = self.document?.syntaxParser else { return assertionFailure() }
        
        self.syntaxStyleObserver = syntaxParser.$outlineItems
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.outlineItems = $0 }
    }
    
    
    /// Update row selection to synchronize with editor's cursor location.
    ///
    /// - Parameter textView: The text view to apply the selection. when nil, the current focused editor will be used (the document can have multiple editors).
    private func invalidateCurrentLocation(textView: NSTextView? = nil) {
        
        guard self.filterString.isEmpty else { return }
        guard let outlineView = self.outlineView else { return }
        
        guard
            let textView = textView ?? self.document?.textView,
            let row = self.outlineItems.indexOfItem(at: textView.selectedRange.location),
            outlineView.numberOfRows > row
            else { return outlineView.deselectAll(nil) }
        
        self.isOwnSelectionChange = true
        outlineView.selectRowIndexes([row], byExtendingSelection: false)
        outlineView.scrollRowToVisible(row)
        self.isOwnSelectionChange = false
    }
    
    
    /// Filter outline items in table.
    ///
    /// - Parameter searchString: The string to search.
    private func filterItems(with searchString: String) {
        
        self.filteredOutlineItems = self.outlineItems.filterItems(with: searchString)
        self.filteringMessage = (!searchString.isEmpty && self.filteredOutlineItems.isEmpty)
            ? "No Filter Results".localized
            : nil
    }
    
}



extension OutlineViewController: NSOutlineViewDelegate {
    
    /// selection changed
    func outlineViewSelectionDidChange(_ notification: Notification) {
        
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
        
        if !self.filterString.isEmpty { return self.filteredOutlineItems.count }
        
        return self.outlineItems.count
    }
    
    
    /// return if item is expandable
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        
        return false
    }
    
    
    /// return child items
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        
        if !self.filterString.isEmpty { return self.filteredOutlineItems[index] }
        
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
                let font = outlineView.font?.withSize(fontSize) ?? .systemFont(ofSize: fontSize)
                let attrTitle = outlineItem.attributedTitle(for: font, attributes: [.paragraphStyle: self.itemParagraphStyle])
                
                guard let ranges = outlineItem.filteredRanges else { return attrTitle }
                
                let mutableAttrTitle = attrTitle.mutable
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: fontSize, weight: .semibold),
                    .backgroundColor: NSColor.findHighlightColor,
                ]
                for range in ranges {
                    mutableAttrTitle.addAttributes(attributes, range: range)
                }
                
                return mutableAttrTitle
                
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
