//
//  FileBrowserViewController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-05-01.
//
//  ---------------------------------------------------------------------------
//
//  © 2024-2025 1024jp
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
import SwiftUI
import QuickLookUI
import Combine
import AudioToolbox
import Defaults
import ControlUI
import URLUtils

final class FileBrowserViewController: NSViewController, NSMenuItemValidation {
    
    let document: DirectoryDocument
    
    @ViewLoading private(set) var outlineView: NSOutlineView
    @ViewLoading private var bottomSeparator: NSView
    @ViewLoading private var addButton: NSPopUpButton
    
    private var showsHiddenFiles: Bool
    
    private var expandingNodes: [FileNode: [FileNode]] = [:]
    
    private var defaultObservers: Set<AnyCancellable> = []
    private var scrollObservers: [any NSObjectProtocol] = []
    
    
    // MARK: Lifecycle
    
    init(document: DirectoryDocument) {
        
        self.document = document
        self.showsHiddenFiles = UserDefaults.standard[.fileBrowserShowsHiddenFiles]
        
        super.init(nibName: nil, bundle: nil)
        
        document.fileBrowserViewController = self
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func loadView() {
        
        let footerHeight: CGFloat = 23
        
        let outlineView = NSOutlineView()
        outlineView.headerView = nil
        outlineView.addTableColumn(NSTableColumn())
        outlineView.setAccessibilityLabel(String(localized: "File Browser", table: "Document", comment: "accessibility label"))
        outlineView.target = self
        outlineView.doubleAction = #selector(outlineViewDoubleClicked)
        
        let scrollView = NSScrollView()
        scrollView.documentView = outlineView
        scrollView.contentView.automaticallyAdjustsContentInsets = false
        scrollView.contentView.contentInsets.bottom = footerHeight
        
        let bottomSeparator = NSBox()
        bottomSeparator.boxType = .separator
        
        let addButton = NSPopUpButton()
        (addButton.cell as! NSPopUpButtonCell).arrowPosition = .noArrow
        addButton.pullsDown = true
        addButton.isBordered = false
        addButton.addItem(withTitle: "")
        addButton.item(at: 0)!.image = NSImage(systemSymbolName: "plus",
                                               accessibilityDescription: String(localized: "Add", table: "Document"))
        addButton.setAccessibilityLabel(String(localized: "Add", table: "Document"))
        
        let footerView = NSVisualEffectView()
        footerView.material = .sidebar
        footerView.addSubview(addButton)
        
        addButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            addButton.centerYAnchor.constraint(equalTo: footerView.centerYAnchor),
            addButton.leadingAnchor.constraint(equalTo: footerView.leadingAnchor, constant: 6),
        ])
        
        self.view = NSView()
        self.view.addSubview(scrollView)
        self.view.addSubview(bottomSeparator)
        self.view.addSubview(footerView)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        bottomSeparator.translatesAutoresizingMaskIntoConstraints = false
        footerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: self.view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            bottomSeparator.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            bottomSeparator.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            bottomSeparator.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -footerHeight),
            footerView.heightAnchor.constraint(equalToConstant: footerHeight),
            footerView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            footerView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            footerView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
        ])
        
        self.outlineView = outlineView
        self.bottomSeparator = bottomSeparator
        self.addButton = addButton
    }
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.outlineView.allowsMultipleSelection = true
        self.outlineView.dataSource = self
        self.outlineView.delegate = self
        self.outlineView.autosaveName = "FileBrowserOutlineView"
        self.outlineView.autosaveExpandedItems = true
        
        self.outlineView.registerForDraggedTypes([.fileURL])
        self.outlineView.setDraggingSourceOperationMask([.copy, .move, .delete], forLocal: false)
        
        let contextMenu = NSMenu()
        contextMenu.items = [
            NSMenuItem(title: String(localized: "Show in Finder", table: "Document", comment: "menu item label"),
                       action: #selector(showInFinder), keyEquivalent: ""),
            .separator(),
            
            NSMenuItem(title: String(localized: "Open in New Window", table: "Document", comment: "menu item label"),
                       action: #selector(openInNewWindow), keyEquivalent: ""),
            NSMenuItem(title: String(localized: "Open with External Editor", table: "Document", comment: "menu item label"),
                       action: #selector(openWithExternalEditor), keyEquivalent: ""),
            .separator(),
            
            NSMenuItem(title: String(localized: "Move to Trash", table: "Document", comment: "menu item label"),
                       action: #selector(moveToTrash), keyEquivalent: ""),
            NSMenuItem(title: String(localized: "Duplicate", table: "Document", comment: "menu item label"),
                       action: #selector(duplicate), keyEquivalent: ""),
            .separator(),
            
            NSMenuItem(title: String(localized: "New File", table: "Document", comment: "menu item label"),
                       action: #selector(addFile), keyEquivalent: ""),
            NSMenuItem(title: String(localized: "New Folder", table: "Document", comment: "menu item label"),
                       action: #selector(addFolder), keyEquivalent: ""),
            .separator(),
            
            NSMenuItem(title: String(localized: "Share…", table: "Document", comment: "menu item label"),
                       action: #selector(share), keyEquivalent: ""),
            .separator(),
            
            NSMenuItem(title: String(localized: "Show Hidden Files", table: "Document", comment: "menu item label"),
                       action: #selector(toggleHiddenFileVisibility), keyEquivalent: ""),
        ]
        for item in contextMenu.items where !item.isSeparatorItem {
            item.target = self
        }
        self.outlineView.menu = contextMenu
        
        self.addButton.menu!.items += [
            NSMenuItem(title: String(localized: "New File", table: "Document", comment: "menu item label"),
                       action: #selector(addFile), keyEquivalent: ""),
            NSMenuItem(title: String(localized: "New Folder", table: "Document", comment: "menu item label"),
                       action: #selector(addFolder), keyEquivalent: ""),
        ]
        for item in self.addButton.menu!.items where !item.isSeparatorItem {
            item.target = self
        }
        
        // set accessibility
        self.view.setAccessibilityElement(true)
        self.view.setAccessibilityRole(.group)
        self.view.setAccessibilityLabel(String(localized: "Sidebar", table: "Document", comment: "accessibility label"))
    }
    
    
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        self.outlineView.reloadData()
        self.invalidateSeparatorVisibility()
        
        self.defaultObservers = [
            UserDefaults.standard.publisher(for: .fileBrowserShowsHiddenFiles)
                .sink { [unowned self] showsHiddenFiles in
                    self.showsHiddenFiles = showsHiddenFiles
                    self.outlineView.reloadData()
                },
        ]
        
        let scrollView = self.outlineView.enclosingScrollView!
        for observer in self.scrollObservers {
            NotificationCenter.default.removeObserver(observer)
        }
        self.scrollObservers = [
            NotificationCenter.default.addObserver(forName: NSView.boundsDidChangeNotification, object: scrollView.contentView, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.invalidateSeparatorVisibility()
                }
            },
            NotificationCenter.default.addObserver(forName: NSView.frameDidChangeNotification, object: scrollView.documentView, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.invalidateSeparatorVisibility()
                }
            },
        ]
    }
    
    
    override func viewDidDisappear() {
        
        super.viewDidDisappear()
        
        self.defaultObservers.removeAll()
        
        for observer in self.scrollObservers {
            NotificationCenter.default.removeObserver(observer)
        }
        self.scrollObservers.removeAll()
    }
    
    
    // MARK: Public Methods
    
    /// Selects the current document in the outline view.
    func selectCurrentDocument() {
        
        guard
            let fileURL = self.document.currentDocument?.fileURL,
            let node = self.document.fileNode?.node(at: fileURL)
        else { return }
        
        self.select(node: node)
    }
    
    
    /// Invoked when the file node did updated externally.
    ///
    /// - Parameter node: The file node whose children were changed.
    func didUpdateNode(at node: FileNode) {
        
        // -> reload later in viewWillAppear
        guard !self.view.isHiddenOrHasHiddenAncestor else { return }
        
        self.outlineView.reloadItem((self.document.fileNode == node) ? nil : node, reloadChildren: true)
    }
    
    
    // MARK: Actions
    
    override func responds(to aSelector: Selector!) -> Bool {
        
        switch aSelector {
            case #selector(copy(_:)):
                MainActor.assumeIsolated {
                    !self.outlineView.selectedRowIndexes.isEmpty
                }
            default:
                super.responds(to: aSelector)
        }
    }
    
    
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        
        switch menuItem.action {
            case #selector(copy(_:)):
                return !self.targetRows(for: menuItem).isEmpty
                
            case #selector(showInFinder):
                menuItem.isHidden = self.targetRows(for: menuItem).isEmpty
                
            case #selector(openWithExternalEditor):
                menuItem.isHidden = !self.targetNodes(for: menuItem).contains { !$0.isFolder }
                
            case #selector(openInNewWindow):
                menuItem.isHidden = self.targetRows(for: menuItem).isEmpty
                
            case #selector(addFile):
                return self.targetFolderNode(for: menuItem)?.isWritable == true
                
            case #selector(addFolder):
                return self.targetFolderNode(for: menuItem)?.isWritable == true
                
            case #selector(duplicate):
                menuItem.isHidden = self.targetRows(for: menuItem).count != 1
                
            case #selector(moveToTrash):
                let targetNodes = self.targetNodes(for: menuItem)
                menuItem.isHidden = targetNodes.isEmpty
                return targetNodes.contains(where: \.isWritable)
                
            case #selector(share):
                menuItem.isHidden = self.targetRows(for: menuItem).isEmpty
                
            case #selector(toggleHiddenFileVisibility):
                menuItem.state = self.showsHiddenFiles ? .on : .off
                
            case nil:
                return false
                
            default:
                break
        }
        
        return true
    }
    
    
    @IBAction func copy(_ sender: Any?) {
        
        let fileURLs = self.targetNodes(for: sender).map(\.fileURL)
        
        guard !fileURLs.isEmpty else { return }
        
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects(fileURLs as [NSURL])
    }
    
    
    @IBAction func showInFinder(_ sender: Any?) {
        
        let fileURLs = self.targetNodes(for: sender).map(\.fileURL)
        
        guard !fileURLs.isEmpty else { return }
        
        NSWorkspace.shared.activateFileViewerSelecting(fileURLs)
    }
    
    
    @IBAction func openWithExternalEditor(_ sender: Any?) {
        
        let nodes = self.targetNodes(for: sender)
        
        guard !nodes.isEmpty else { return }
        
        let bundleIdentifier = Bundle.main.bundleIdentifier!
        let configuration = NSWorkspace.OpenConfiguration()
        
        for node in nodes {
            let fileURL = node.fileURL
            guard
                let appURL = NSWorkspace.shared.urlsForApplications(toOpen: fileURL)
                    .first(where: { Bundle(url: $0)?.bundleIdentifier != bundleIdentifier })
            else { continue }
            
            NSWorkspace.shared.open([fileURL], withApplicationAt: appURL, configuration: configuration)
        }
    }
    
    
    @IBAction func openInNewWindow(_ sender: Any?) {
        
        let nodes = self.targetNodes(for: sender)
        
        for node in nodes {
            self.document.openInWindow(at: node)
        }
    }
    
    
    @IBAction func addFile(_ sender: NSMenuItem) {
        
        guard let folderNode = self.targetFolderNode(for: sender) else { return }
        
        let node: FileNode
        do {
            node = try self.document.addFile(at: folderNode)
        } catch {
            return self.presentErrorAsSheet(error)
        }
        
        // update UI
        if let index = self.children(of: folderNode)?.firstIndex(of: node) {
            let parent = (folderNode == self.document.fileNode) ? nil : folderNode
            self.outlineView.insertItems(at: [index], inParent: parent, withAnimation: .slideDown)
        }
        self.select(node: node, edit: true)
    }
    
    
    @IBAction func addFolder(_ sender: NSMenuItem) {
        
        guard let folderNode = self.targetFolderNode(for: sender) else { return }
        
        let node: FileNode
        do {
            node = try self.document.addFolder(at: folderNode)
        } catch {
            return self.presentErrorAsSheet(error)
        }
        
        // update UI
        if let index = self.children(of: folderNode)?.firstIndex(of: node) {
            let parent = (folderNode == self.document.fileNode) ? nil : folderNode
            self.outlineView.insertItems(at: [index], inParent: parent, withAnimation: .slideDown)
        }
        self.select(node: node, edit: true)
    }
    
    
    @IBAction func duplicate(_ sender: Any?) {
        
        let nodes = self.targetNodes(for: sender)
        
        // accept only single item
        guard nodes.count == 1, let node = nodes.first else { return }
        
        let newNode: FileNode
        do {
            newNode = try self.document.duplicateItem(at: node)
        } catch {
            return self.presentErrorAsSheet(error)
        }
        
        // update UI
        if let index = self.children(of: newNode.parent)?.firstIndex(of: newNode) {
            let parent = (newNode.parent == self.document.fileNode) ? nil : newNode.parent
            self.outlineView.insertItems(at: [index], inParent: parent, withAnimation: .slideDown)
        }
        self.select(node: newNode)
    }
    
    
    @IBAction func moveToTrash(_ sender: Any?) {
        
        let nodes = self.targetNodes(for: sender)
        
        self.trashNodes(nodes)
    }
    
    
    @IBAction func share(_ menuItem: NSMenuItem) {
        
        let fileURLs = self.targetNodes(for: menuItem).map(\.fileURL)
        
        guard
            !fileURLs.isEmpty,
            let view = self.outlineView.rowView(atRow: self.outlineView.clickedRow, makeIfNecessary: false)
        else { return }
        
        let picker = NSSharingServicePicker(items: fileURLs)
        picker.show(relativeTo: .zero, of: view, preferredEdge: .minX)
    }
    
    
    @IBAction func toggleHiddenFileVisibility(_ sender: Any?) {
        
        UserDefaults.standard[.fileBrowserShowsHiddenFiles].toggle()
    }
    
    
    @objc private func outlineViewDoubleClicked(_ outlineView: NSOutlineView) {
        
        guard let item = outlineView.item(atRow: outlineView.clickedRow) else { return }
        
        if outlineView.isItemExpanded(item) {
            outlineView.animator().collapseItem(item)
        } else {
            outlineView.animator().expandItem(item)
        }
    }
    
    
    // MARK: Private Methods
    
    /// Returns the target outline rows for the menu action.
    ///
    /// - Parameter menuItem: The sender of the action.
    /// - Returns: The outline row indexes.
    private func targetRows(for sender: Any?) -> IndexSet {
        
        let isContextMenu = ((sender as? NSMenuItem)?.menu == self.outlineView.menu)
        let clickedRow = self.outlineView.clickedRow
        let selectedRows = self.outlineView.selectedRowIndexes
        
        return if isContextMenu {
            if clickedRow >= 0 {
                selectedRows.contains(clickedRow) ? selectedRows : [clickedRow]
            } else {
                []
            }
        } else {
            selectedRows
        }
    }
    
    
    /// Returns the target file nodes to perform the for the menu action.
    ///
    /// - Parameter menuItem: The sender of the action.
    /// - Returns: File nodes.
    private func targetNodes(for sender: Any?) -> [FileNode] {
        
        self.targetRows(for: sender)
            .compactMap { self.outlineView.item(atRow: $0) as? FileNode }
    }
    
    
    /// Returns the folder node to perform the menu item action.
    ///
    /// - Parameter menuItem: The sender of the action.
    /// - Returns: A file node, or `nil` if the target is multiple nodes.
    private func targetFolderNode(for sender: NSMenuItem) -> FileNode? {
        
        let targetNodes = self.targetNodes(for: sender)
        
        if targetNodes.isEmpty {
            return self.document.fileNode
        }
        
        guard
            targetNodes.count == 1,
            let targetNode = targetNodes.first
        else { return nil }
        
        return targetNode.isDirectory ? targetNode : targetNode.parent
    }
    
    
    /// Selects the specified item in the outline view.
    ///
    /// - Parameters:
    ///   - node: The note item to select.
    ///   - edit: If `true`, the text field will be in the editing mode.
    private func select(node: FileNode, edit: Bool = false) {
        
        node.parents.reversed().forEach { self.outlineView.expandItem($0) }
        
        let row = self.outlineView.row(forItem: node)
        
        guard row >= 0 else { return assertionFailure() }
        
        self.outlineView.selectRowIndexes([row], byExtendingSelection: false)
        
        if edit {
            self.outlineView.editColumn(0, row: row, with: nil, select: false)
        }
    }
    
    
    /// Moves the given nodes to the Trash.
    ///
    /// - Parameter nodes: The file nodes to move to the Trash.
    private func trashNodes(_ nodes: [FileNode]) {
        
        guard !nodes.isEmpty else { return }
        
        self.outlineView.beginUpdates()
        for node in nodes {
            do {
                try self.document.trashItem(node)
            } catch {
                self.presentErrorAsSheet(error)
                continue
            }
            
            let parent = self.outlineView.parent(forItem: node)
            let index = self.outlineView.childIndex(forItem: node)
            
            guard index >= 0 else { continue }
            
            self.outlineView.removeItems(at: [index], inParent: parent, withAnimation: .slideUp)
        }
        self.outlineView.endUpdates()
        AudioServicesPlaySystemSound(.moveToTrash)
    }
    
    
    /// Updates the visibility of the separators by considering the outline scroll state.
    private func invalidateSeparatorVisibility() {
        
        guard let clipView = self.outlineView.enclosingScrollView?.contentView else { return assertionFailure() }
        
        let visibleRect = clipView.documentVisibleRect
        let inset = clipView.contentInsets.bottom
        
        self.bottomSeparator.animator().alphaValue = (visibleRect.maxY < clipView.documentRect.maxY + inset) ? 1 : 0
    }
}


// MARK: Outline View Data Source

extension FileBrowserViewController: NSOutlineViewDataSource {
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        
        self.children(of: item as? FileNode)?.count ?? 0
    }
    
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        
        (item as! FileNode).isDirectory
    }
    
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        
        let node = item as? FileNode
        
        // use available cache when expanding a folder
        if let node, let children = self.expandingNodes[node] {
            return children[index]
        }
        
        return self.children(of: node)![index]
    }
    
    
    func outlineView(_ outlineView: NSOutlineView, pasteboardWriterForItem item: Any) -> (any NSPasteboardWriting)? {
        
        (item as? FileNode)?.fileURL as? NSURL
    }
    
    
    func outlineView(_ outlineView: NSOutlineView, validateDrop info: any NSDraggingInfo, proposedItem item: Any?, proposedChildIndex index: Int) -> NSDragOperation {
        
        guard
            index == NSOutlineViewDropOnItemIndex,
            let fileURLs = info.draggingPasteboard.readObjects(forClasses: [NSURL.self]) as? [URL],
            let rootNode = self.document.fileNode
        else { return [] }
        
        var destNode = item as? FileNode ?? rootNode
        
        // avoid dropping on a leaf
        if !destNode.isDirectory {
            let parent = outlineView.parent(forItem: item)
            outlineView.setDropItem(parent, dropChildIndex: NSOutlineViewDropOnItemIndex)
            destNode = parent as? FileNode ?? rootNode
        }
        
        guard
            destNode.isWritable,
            !fileURLs.contains(destNode.fileURL),
            !fileURLs.contains(where: { $0.isAncestor(of: destNode.fileURL) })
        else { return [] }
        
        if info.draggingSourceOperationMask == .copy { return .copy }
        
        let isInternal = info.draggingSource as? NSOutlineView == outlineView
        
        return isInternal ? .move : .copy
    }
    
    
    func outlineView(_ outlineView: NSOutlineView, acceptDrop info: any NSDraggingInfo, item: Any?, childIndex index: Int) -> Bool {
        
        guard
            let fileURLs = info.draggingPasteboard.readObjects(forClasses: [NSURL.self]) as? [URL],
            let destNode = item as? FileNode ?? self.document.fileNode
        else { return false }
        
        let isInternal = info.draggingSource as? NSOutlineView == outlineView
        let operation: NSDragOperation = (info.draggingSourceOperationMask == .copy || !isInternal) ? .copy : .move
        
        var didProcess = false
        
        self.outlineView.beginUpdates()
        for fileURL in fileURLs {
            if operation == .move {
                guard
                    let node = self.document.fileNode?.node(at: fileURL),
                    node.parent != destNode  // ignore same location
                else { continue }
                
                do {
                    try self.document.moveItem(at: node, to: destNode)
                } catch {
                    self.presentErrorAsSheet(error)
                    continue
                }
                
                let oldIndex = self.outlineView.childIndex(forItem: node)
                let oldParent = self.outlineView.parent(forItem: node)
                let childIndex = self.children(of: destNode)?.firstIndex(of: node)
                self.outlineView.moveItem(at: oldIndex, inParent: oldParent, to: childIndex ?? 0, inParent: item)
                
            } else {
                let node: FileNode
                do {
                    node = try self.document.copyItem(at: fileURL, to: destNode)
                } catch {
                    self.presentErrorAsSheet(error)
                    continue
                }
                
                let childIndex = self.children(of: destNode)?.firstIndex(of: node)
                self.outlineView.insertItems(at: [childIndex ?? 0], inParent: item, withAnimation: .slideDown)
            }
            
            didProcess = true
        }
        self.outlineView.endUpdates()
        
        return didProcess
    }
    
    
    func outlineView(_ outlineView: NSOutlineView, draggingSession session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        
        switch operation {
            case .delete:  // ended at the Trash
                guard let fileURLs = session.draggingPasteboard.readObjects(forClasses: [NSURL.self]) as? [URL] else { return }
                
                let nodes = fileURLs.compactMap { self.document.fileNode?.node(at: $0) }
                self.trashNodes(nodes)
                
            default:
                break
        }
    }
    
    
    func outlineView(_ outlineView: NSOutlineView, itemForPersistentObject object: Any) -> Any? {
       
        guard
            let rootURL = self.document.fileURL,
            let path = object as? String
        else { return nil }
        
        let url = URL(filePath: path, relativeTo: rootURL)
        
        return self.document.fileNode?.node(at: url)
    }
    
    
    func outlineView(_ outlineView: NSOutlineView, persistentObjectForItem item: Any?) -> Any? {
        
        guard
            let rootURL = self.document.fileURL,
            let node = item as? FileNode
        else { return nil }
        
        return node.fileURL.path(relativeTo: rootURL)
    }
    
    
    /// Returns the casted children of the given item.
    ///
    /// - Parameter node: An item in the data source, or `nil` for the root.
    /// - Returns: An array of file nodes, or `nil` if no data source is provided yet.
    private func children(of node: FileNode?) -> [FileNode]? {
        
        guard let children = (node ?? self.document.fileNode)?.children else { return nil }
        
        return self.filterNodes(children)
    }
    
    
    /// Filters given file nodes according to the current settings.
    ///
    /// - Parameter nodes: The nodes to filter.
    /// - Returns: An array of file nodes.
    private func filterNodes(_ nodes: [FileNode]) -> [FileNode] {
        
        self.showsHiddenFiles
            ? nodes
            : nodes.filter { !$0.isHidden }
    }
}


// MARK: Outline View Delegate

extension FileBrowserViewController: NSOutlineViewDelegate {
    
    func outlineView(_ outlineView: NSOutlineView, rowViewForItem item: Any) -> NSTableRowView? {
        
        FileBrowserTableRowView()
    }
    
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        
        let node = item as! FileNode
        let cellView = outlineView.makeView(withIdentifier: .node, owner: self) as? FileBrowserTableCellView ?? .init()
        cellView.textField?.delegate = self
        
        cellView.imageView!.image = NSImage(systemSymbolName: node.kind.symbolName, accessibilityDescription: node.kind.label)!
        cellView.imageView!.alphaValue = node.isHidden ? 0.5 : 1
        cellView.isAlias = node.isAlias
        cellView.tags = node.tags
        
        cellView.textField!.stringValue = node.name
        cellView.textField!.textColor = node.isHidden ? .tertiaryLabelColor : .labelColor
        
        return cellView
    }
    
    
    func outlineViewSelectionDidChange(_ notification: Notification) {
        
        if QLPreviewPanel.sharedPreviewPanelExists(),
           QLPreviewPanel.shared().delegate is FileBrowserViewController
        {
            QLPreviewPanel.shared().reloadData()
        }
        
        let outlineView = notification.object as! NSOutlineView
        
        guard
            outlineView.numberOfSelectedRows == 1,
            let node = outlineView.item(atRow: outlineView.selectedRow) as? FileNode,
            !node.isDirectory
        else { return }
        
        Task {
            await self.document.openDocument(at: node.fileURL)
        }
    }
    
    
    func outlineViewItemWillExpand(_ notification: Notification) {
        
        guard
            let node = notification.userInfo?["NSObject"] as? FileNode,
            let children = node.children
        else { return }
        
        // cache filtered children to avoid taking time for expanding a folder with large number of items
        // cf. [#1711](https://github.com/coteditor/CotEditor/issues/1711)
        self.expandingNodes[node] = self.filterNodes(children)
    }
    
    
    func outlineViewItemDidExpand(_ notification: Notification) {
        
        if let node = notification.userInfo?["NSObject"] as? FileNode {
            Task {
                self.expandingNodes[node] = nil
            }
        }
    }
}


// MARK: Text Field Delegate

extension FileBrowserViewController: NSTextFieldDelegate {
    
    func control(_ control: NSControl, textShouldBeginEditing fieldEditor: NSText) -> Bool {
        
        let row = self.outlineView.row(for: control)
        
        guard let node = self.outlineView.item(atRow: row) as? FileNode else { return false }
        
        // avoid renaming unsaved document
        guard self.document.openedDocument(at: node)?.isDocumentEdited != true else { return false }
        
        return node.isWritable
    }
    
    
    func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
        
        let row = self.outlineView.row(for: control)
        
        guard let node = self.outlineView.item(atRow: row) as? FileNode else { return false }
        
        if fieldEditor.string == node.name { return true }  // not changed
        
        do {
            try self.document.renameItem(at: node, with: fieldEditor.string)
        } catch {
            fieldEditor.string = node.name
            self.presentErrorAsSheet(error)
            return false
        }
        
        return true
    }
    
    
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        
        guard self.outlineView.row(for: control) >= 0 else { return false }
        
        switch commandSelector {
            case #selector(NSTextView.insertTabIgnoringFieldEditor):
                // avoid inserting tab
                textView.insertTab(nil)
                return true
                
            default:
                return false
        }
    }
}


// MARK: -

/// Column identifiers for outline view.
private extension NSUserInterfaceItemIdentifier {
    
    static let node = NSUserInterfaceItemIdentifier("node")
}


private final class FileBrowserTableRowView: NSTableRowView {
    
    override var isSelected: Bool {
        
        didSet {
            self.subviews
                .compactMap { $0 as? FileBrowserTableCellView }
                .forEach { $0.isSelected = isSelected }
        }
    }
}


private final class FileBrowserTableCellView: NSTableCellView {
    
    var isAlias: Bool = false  { didSet { self.aliasArrowView?.isHidden = !isAlias } }
    var tags: [FinderTag] = []  { didSet { self.updateTagsView() } }
    var isSelected = false  { didSet { self.updateTagsView() } }
    
    private var aliasArrowView: NSImageView?
    private var tagsView: NSHostingView<TagsView>?
    private var tagsLayoutConstraint: NSLayoutConstraint?
    
    
    override init(frame frameRect: NSRect) {
        
        super.init(frame: frameRect)
        
        self.identifier = .node
        self.setupSubviews()
    }
    
    
    required init?(coder: NSCoder) {
        
        super.init(coder: coder)
        
        self.identifier = .node
        self.setupSubviews()
    }
    
    
    /// Sets up subviews.
    private func setupSubviews() {
        
        let imageView = NSImageView()
        imageView.alignment = .center
        imageView.setAccessibilityRoleDescription(nil)  // omit "image" automatically added after the label utterance
        
        let textField = FilenameTextField()
        textField.usesSingleLineMode = true
        textField.drawsBackground = false
        textField.isBordered = false
        textField.lineBreakMode = .byTruncatingMiddle
        textField.isEditable = true
        
        let aliasArrowView = NSImageView()
        aliasArrowView.alignment = .center
        aliasArrowView.image = .arrowAliasFill
        aliasArrowView.symbolConfiguration = .init(paletteColors: [.labelColor, .controlBackgroundColor])
        aliasArrowView.setAccessibilityLabel(String(localized: "Alias", table: "Document", comment: "accessibility label"))
        aliasArrowView.setAccessibilityRoleDescription(nil)
        
        let tagsView = NSHostingView(rootView: TagsView(tags: self.tags))
        tagsView.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        
        self.addSubview(textField)
        self.addSubview(imageView)
        self.addSubview(aliasArrowView)
        self.addSubview(tagsView)
        self.textField = textField
        self.imageView = imageView
        self.aliasArrowView = aliasArrowView
        self.tagsView = tagsView
        
        textField.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        aliasArrowView.translatesAutoresizingMaskIntoConstraints = false
        tagsView.translatesAutoresizingMaskIntoConstraints = false
        
        let textFieldTrailingAnchor = textField.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -2)
        textFieldTrailingAnchor.priority = .defaultLow
        self.tagsLayoutConstraint = tagsView.leadingAnchor.constraint(equalToSystemSpacingAfter: textField.trailingAnchor, multiplier: 1)
        
        NSLayoutConstraint.activate([
            imageView.firstBaselineAnchor.constraint(equalTo: textField.firstBaselineAnchor),
            aliasArrowView.firstBaselineAnchor.constraint(equalTo: textField.firstBaselineAnchor),
            textField.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            tagsView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            imageView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 2),
            imageView.widthAnchor.constraint(equalToConstant: 17),  // the value used in a sample code by Apple
            aliasArrowView.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            textField.leadingAnchor.constraint(equalToSystemSpacingAfter: imageView.trailingAnchor, multiplier: 1),
            textFieldTrailingAnchor,
            tagsView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -2),
        ])
    }
    
    
    /// Updates the tags view.
    private func updateTagsView() {
        
        self.tagsView?.rootView = TagsView(tags: self.tags, isSelected: self.isSelected)
        self.tagsLayoutConstraint?.isActive = !self.tags.isEmpty
    }
}
