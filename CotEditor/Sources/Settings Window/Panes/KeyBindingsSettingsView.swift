//
//  KeyBindingsSettingsView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2014-08-20.
//
//  ---------------------------------------------------------------------------
//
//  © 2014-2025 1024jp
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

import SwiftUI
import AppKit
import OSLog
import Shortcut

struct KeyBindingsSettingsView: View {
    
    @State private var model = KeyBindingModel()
    
    
    var body: some View {
        
        VStack(alignment: .leading) {
            Text("To change a shortcut, click the key column, and then type the new keys.", tableName: "KeyBindingsSettings")
                .lineLimit(10)
                .fixedSize(horizontal: false, vertical: true)
            
            KeyBindingTreeView(model: $model)
                .frame(height: 260)
            
            HStack(alignment: .firstTextBaseline) {
                Button(String(localized: "Action.restoreDefaults.label", defaultValue: "Restore Defaults"), action: self.model.restore)
                    .disabled(!self.model.isRestorable)
                    .fixedSize()
                
                Spacer()
                
                if let error = self.model.error {
                    Text(error.localizedDescription)
                        .foregroundStyle(.red)
                        .controlSize(.small)
                }
                HelpLink(anchor: "settings_keybindings")
            }.frame(minHeight: 20)
        }
        .onAppear {
            self.model.load()
        }
        .scenePadding()
        .frame(width: 610)
    }
}


@MainActor @Observable private final class KeyBindingModel {
    
    typealias Item = Node<KeyBindingItem>
    
    private(set) var tree: [Item] = []
    private(set) var isRestorable: Bool = false
    var error: (any Error)?
    
    var rootIndex: Int?
    
    private let manager: KeyBindingManager = .shared
    
    
    /// Loads data from the user defaults.
    func load() {
        
        self.tree = self.manager.menuTree
        self.isRestorable = self.manager.isCustomized
    }
    
    
    /// Restores key binding setting to default.
    func restore() {
        
        try? self.manager.restoreDefaults()
        
        self.tree = self.manager.menuTree
        self.isRestorable = false
        self.error = nil
    }
    
    
    /// Saves the current settings.
    func save() {
        
        do {
            try self.manager.save(tree: self.tree)
        } catch {
            Logger.app.error("\(error.localizedDescription)")
        }
        
        self.isRestorable = self.manager.isCustomized
    }
}


private struct KeyBindingTreeView: NSViewControllerRepresentable {
    
    typealias NSViewControllerType = NSViewController
    
    
    @Binding var model: KeyBindingModel
    
    
    func makeNSViewController(context: Context) -> NSViewController {
        
        NSStoryboard(name: "KeyBindingTreeView", bundle: nil).instantiateInitialController { coder in
            KeyBindingTreeViewController(model: self.model, coder: coder)
        }!
    }
    
    
    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {
        
    }
}


// MARK: -

/// Column identifiers for outline view.
private extension NSUserInterfaceItemIdentifier {
    
    static let command = NSUserInterfaceItemIdentifier("command")
    static let key = NSUserInterfaceItemIdentifier("key")
}


final class KeyBindingTreeViewController: NSViewController, NSOutlineViewDataSource, NSOutlineViewDelegate {
    
    // MARK: Private Properties
    
    private let model: KeyBindingModel
    
    @IBOutlet private weak var listView: NSTableView?
    @IBOutlet private weak var outlineView: NSOutlineView?
    
    
    // MARK: Lifecycle
    
    fileprivate init?(model: KeyBindingModel, coder: NSCoder) {
        
        self.model = model
        
        super.init(coder: coder)
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.listView?.rowSizeStyle = .medium
        self.outlineView?.rowSizeStyle = .medium
    }
    
    
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        self.listView?.reloadData()
        self.outlineView?.reloadData()
        
        self.observe()
    }
    
    
    // MARK: Outline View Data Source
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        
        if let node = item as? Node<KeyBindingItem> {
            node.children?.count ?? 0
        } else if let rootIndex = self.model.rootIndex, rootIndex >= 0 {
            self.model.tree[rootIndex].children?.count ?? 0
        } else {
            0
        }
    }
    
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        
        (item as? Node<KeyBindingItem>)?.children != nil
    }
    
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        
        if let node = item as? Node<KeyBindingItem> {
            node.children![index]
        } else if let rootIndex = self.model.rootIndex {
            self.model.tree[rootIndex].children![index]
        } else {
            preconditionFailure()
        }
    }
    
    
    // MARK: Outline View Delegate
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        
        guard
            let node = item as? Node<KeyBindingItem>,
            let identifier = tableColumn?.identifier,
            let cellView = outlineView.makeView(withIdentifier: identifier, owner: self) as? NSTableCellView
        else { return nil }
        
        switch identifier {
            case .command:
                cellView.objectValue = node.name
                
            case .key:
                switch node.item {
                    case .value(let item):
                        cellView.objectValue = item.shortcut
                        cellView.textField?.placeholderString = item.defaultShortcut?.symbol
                        
                    case .children:
                        cellView.textField?.isEditable = false
                }
                
            default:
                preconditionFailure()
        }
        
        return cellView
    }
    
    
    // MARK: Action Messages
    
    /// Validates and apply new shortcut key input.
    @IBAction func didEditShortcut(_ sender: ShortcutTextField) {
        
        guard let outlineView = self.outlineView else { return assertionFailure() }
        
        let row = outlineView.row(for: sender)
        let column = outlineView.column(for: sender)
        
        guard
            let node = outlineView.item(atRow: row) as? Node<KeyBindingItem>,
            let item = node.value
        else { return }
        
        let oldShortcut = item.shortcut
        let shortcut = sender.objectValue as? Shortcut
        
        // reset once warning
        self.model.error = nil
        
        // not edited
        guard shortcut != oldShortcut else { return }
        
        if let shortcut {
            do {
                try shortcut.checkCustomizationAvailability(for: NSApp.mainMenu)
            } catch {
                self.model.error = error
                sender.objectValue = oldShortcut  // reset text field
                NSSound.beep()
                
                // make text field edit mode again
                Task {
                    outlineView.editColumn(column, row: row, with: nil, select: true)
                }
                return
            }
        }
        
        // successfully update data
        item.shortcut = shortcut
        self.model.save()
        outlineView.reloadData(forRowIndexes: [row], columnIndexes: [column])
    }
    
    
    // MARK: Private Methods
    
    /// Recursively observes the `.isRestorable` flag.
    private func observe() {
        
        withObservationTracking { [weak self] in
            if self?.model.isRestorable == false {
                self?.outlineView?.reloadData()
            }
        } onChange: {
            Task { @MainActor [weak self] in
                self?.observe()
            }
        }
    }
}


extension KeyBindingTreeViewController: NSTableViewDataSource, NSTableViewDelegate {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        
        self.model.tree.count
    }
    
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        
        self.model.tree[row].name
    }
    
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        
        guard let tableView = notification.object as? NSTableView else { return }
        
        tableView.window?.makeFirstResponder(nil)
        self.model.rootIndex = tableView.selectedRow
        self.outlineView?.reloadData()
    }
}


// MARK: - Preview

#Preview {
    KeyBindingsSettingsView()
}
