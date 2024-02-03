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
//  © 2018-2024 1024jp
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

/// Column identifiers for outline view
private extension NSUserInterfaceItemIdentifier {
    
    static let title = NSUserInterfaceItemIdentifier("title")
}


final class OutlineViewController: NSViewController, DocumentOwner {
    
    // MARK: Public Properties
    
    var document: Document {
        
        didSet {
            if self.isViewShown {
                self.observeDocument()
            }
        }
    }
    
    
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
    @objc dynamic var hasFilteredItems = false
    @objc dynamic var filterString: String = ""
    
    private var documentObserver: AnyCancellable?
    private var syntaxObserver: AnyCancellable?
    private var selectionObserver: AnyCancellable?
    private var fontSizeObserver: AnyCancellable?
    private var isOwnSelectionChange = false
    
    @IBOutlet private weak var outlineView: NSOutlineView?
    
    
    
    // MARK: Lifecycle
    
    required init?(document: Document, coder: NSCoder) {
        
        self.document = document
        
        super.init(coder: coder)
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // set accessibility
        self.view.setAccessibilityElement(true)
        self.view.setAccessibilityRole(.group)
        self.view.setAccessibilityLabel(String(localized: "Outline", table: "Inspector"))
    }
    
    
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        // workaround a long-standing issue in single column table views (2022-09, macOS 13)
        // cf. [#1365](https://github.com/coteditor/CotEditor/pull/1365)
        self.outlineView?.sizeLastColumnToFit()
        
        self.observeDocument()
        
        self.fontSizeObserver = UserDefaults.standard.publisher(for: .outlineViewFontSize, initial: true)
            .sink { [weak self] _ in
                self?.outlineView?.reloadData()
                self?.invalidateCurrentLocation()
            }
        
        self.selectionObserver = NotificationCenter.default.publisher(for: NSTextView.didChangeSelectionNotification)
            .map { $0.object as! NSTextView }
            .filter { [weak self] in $0.textStorage == self?.document.textStorage }
            .filter { !$0.hasMarkedText() }
            // avoid updating outline item selection before finishing outline parse
            // -> Otherwise, a wrong item can be selected because of using the outdated outline ranges.
            //    You can ignore text selection change at this time point as the outline selection will be updated when the parse finished.
            .filter { $0.textStorage?.editedMask.contains(.editedCharacters) == false }
            .debounce(for: .seconds(0.05), scheduler: RunLoop.main)
            .sink { [weak self] in self?.invalidateCurrentLocation(in: $0) }
    }
    
    
    override func viewDidDisappear() {
        
        super.viewDidDisappear()
        
        self.documentObserver = nil
        self.syntaxObserver = nil
        self.selectionObserver = nil
        self.fontSizeObserver = nil
    }
    
    
    
    // MARK: Actions
    
    /// Item in outlineView was clicked.
    @IBAction func selectOutlineItem(_ sender: NSOutlineView) {
        
        self.selectOutlineItem(at: sender.clickedRow)
    }
    
    
    /// The search field text did update.
    @IBAction func searchFieldDidUpdate(_ sender: NSSearchField) {
        
        self.filterItems(with: sender.stringValue)
    }
    
    
    
    // MARK: Private Methods
    
    /// The `OutlineItem`s currently shown in the view.
    private var items: [OutlineItem] {
        
        self.filterString.isEmpty ? self.outlineItems : self.filteredOutlineItems
    }
    
    
    /// Paragraph style for outline items.
    private let itemParagraphStyle: NSParagraphStyle = {
        
        let paragraphStyle = NSParagraphStyle.default.mutable
        paragraphStyle.lineBreakMode = .byTruncatingTail
        
        return paragraphStyle
    }()
    
    
    /// Selects correspondence range of the outline item in textView.
    ///
    /// - Parameter row: The index of the outline item to select.
    private func selectOutlineItem(at row: Int) {
        
        guard
            let item = self.items[safe: row],
            item.title != .separator
        else { return }
        
        // cancel if text became shorter than range to select
        guard
            let textView = self.document.textView,
            item.range.upperBound <= textView.string.length
        else { return }
        
        textView.selectedRange = item.range
        textView.centerSelectionInVisibleArea(self)
    }
    
    
    /// Updates document observation for syntax.
    private func observeDocument() {
        
        self.documentObserver = self.document.didChangeSyntax
            .merge(with: Just(""))  // initial
            .sink { [weak self] _ in
                self?.syntaxObserver = self?.document.syntaxParser.$outlineItems
                    .compactMap { $0 }
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] in self?.outlineItems = $0 }
            }
    }
    
    
    /// Updates row selection to synchronize with editor's cursor location.
    ///
    /// - Parameter textView: The text view to apply the selection. when nil, the current focused editor will be used (the document can have multiple editors).
    private func invalidateCurrentLocation(in textView: NSTextView? = nil) {
        
        guard self.filterString.isEmpty else { return }
        guard let outlineView = self.outlineView else { return }
        
        guard
            let textView = textView ?? self.document.textView,
            let row = self.outlineItems.indexOfItem(at: textView.selectedRange.location),
            outlineView.numberOfRows > row
        else { return outlineView.deselectAll(nil) }
        
        self.isOwnSelectionChange = true
        outlineView.selectRowIndexes([row], byExtendingSelection: false)
        outlineView.scrollRowToVisible(row)
        self.isOwnSelectionChange = false
    }
    
    
    /// Filters outline items in table.
    ///
    /// - Parameter searchString: The string to search.
    private func filterItems(with searchString: String) {
        
        self.filteredOutlineItems = self.outlineItems.filterItems(with: searchString)
        self.hasFilteredItems = (!searchString.isEmpty && self.filteredOutlineItems.isEmpty)
    }
}



extension OutlineViewController: NSOutlineViewDelegate {
    
    /// Invoked when selection changed.
    func outlineViewSelectionDidChange(_ notification: Notification) {
        
        guard
            !self.isOwnSelectionChange,
            let outlineView = notification.object as? NSOutlineView
        else { return }
        
        self.selectOutlineItem(at: outlineView.selectedRow)
    }
    
    
    /// Avoids selecting separator item.
    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        
        (item as? OutlineItem)?.title != .separator
    }
}



extension OutlineViewController: NSOutlineViewDataSource {
    
    /// Returns number of child items.
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        
        self.items.count
    }
    
    
    /// Returns if item is expandable.
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        
        false
    }
    
    
    /// Returns child items.
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        
        self.items[index]
    }
    
    
    /// Returns suitable item for cell to display.
    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        
        guard
            let identifier = tableColumn?.identifier,
            let outlineItem = item as? OutlineItem
        else { return nil }
        
        switch identifier {
            case .title:
                let fontSize = UserDefaults.standard[.outlineViewFontSize]
                let font = outlineView.font?.withSize(fontSize) ?? .systemFont(ofSize: fontSize)
                var attrTitle = outlineItem.attributedTitle(for: font, paragraphStyle: self.itemParagraphStyle)
                
                guard let ranges = outlineItem.filteredRanges else { return NSAttributedString(attrTitle) }
                
                let attributes = AttributeContainer()
                    .font(.systemFont(ofSize: fontSize, weight: .semibold))
                    .backgroundColor(.findHighlightColor)
                    .foregroundColor(.black.withAlphaComponent(0.9))  // for legibility in Dark Mode
                
                for range in ranges {
                    guard let attrRange = Range(range, in: attrTitle) else { continue }
                    
                    attrTitle[attrRange].setAttributes(attributes)
                }
                
                return NSAttributedString(attrTitle)
                
            default:
                preconditionFailure()
        }
    }
}



extension OutlineViewController {
    
    /// Increases outline view's font size.
    @IBAction func biggerFont(_ sender: Any?) {
        
        UserDefaults.standard[.outlineViewFontSize] += 1
    }
    
    
    /// Decreases outline view's font size.
    @IBAction func smallerFont(_ sender: Any?) {
        
        guard UserDefaults.standard[.outlineViewFontSize] > NSFont.smallSystemFontSize else { return }
        
        UserDefaults.standard[.outlineViewFontSize] -= 1
    }
    
    
    /// Restores outline view's font size to default.
    @IBAction func resetFont(_ sender: Any?) {
        
        UserDefaults.standard.restore(key: .outlineViewFontSize)
    }
}
