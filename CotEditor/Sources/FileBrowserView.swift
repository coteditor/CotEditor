//
//  FileBrowserView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-05-01.
//
//  ---------------------------------------------------------------------------
//
//  © 2024 1024jp
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
import UniformTypeIdentifiers
import AudioToolbox
import Defaults
import URLUtils

struct FileBrowserView: View {
    
    @State var document: DirectoryDocument
    
    @AppStorage(.fileBrowserShowsHiddenFiles) private var showsHiddenFiles
    @AppStorage(.fileBrowserShowsFilenameExtensions) private var showsFilenameExtensions
    
    @State private var selection: FileNode.ID?
    
    @State private var error: (any Error)?
    
    
    var body: some View {
        
        VStack(spacing: 0) {
            let fileNodes = (self.document.fileNode?.children ?? [])
                .recursivelyFilter { self.showsHiddenFiles || !$0.isHidden }
            
            List(fileNodes, children: \.children, selection: $selection) { node in
                NodeView(node: node) { name in
                    do {
                        try self.document.renameItem(at: node.fileURL, with: name)
                    } catch {
                        self.error = error
                        return false
                    }
                    return true
                }
            }
            .listStyle(.sidebar)
            .contextMenu(forSelectionType: FileNode.ID.self) { ids in
                let node = ids.first.flatMap { self.document.fileNode?.node(with: $0, keyPath: \.id) }
                self.contextMenu(node: node)
            }
            
            HStack(spacing: 2) {
                Menu(String(localized: "Add", table: "Document"), systemImage: "plus") {
                    if let fileURL = self.selectedNode?.directoryURL ?? self.document.fileURL {
                        Button(String(localized: "New File", table: "Document", comment: "menu item label")) {
                            do {
                                let url = try self.document.addFile(at: fileURL)
                                Task {
                                    await self.document.openDocument(at: url)
                                }
                            } catch {
                                self.error = error
                            }
                        }
                        Button(String(localized: "New Folder", table: "Document", comment: "menu item label")) {
                            do {
                                try self.document.addFolder(at: fileURL)
                            } catch {
                                self.error = error
                            }
                        }
                    }
                }
                .menuIndicator(.hidden)
                .labelStyle(.iconOnly)
                
                Spacer()
            }
            .buttonStyle(.borderless)
            .padding(6)
        }
        .onChange(of: self.selection) { (oldValue, _) in
            guard let node = self.selectedNode, !node.isDirectory else { return }
            
            Task {
                guard await self.document.openDocument(at: node.fileURL) else {
                    self.selection = oldValue
                    return
                }
            }
        }
        .onChange(of: self.document.currentDocument) { (_, newValue) in
            guard
                let fileURL = newValue?.fileURL,
                let node = self.document.fileNode?.node(with: fileURL, keyPath: \.fileURL)
            else { return }
            
            self.selection = node.id
        }
        .alert(error: $error)
    }
    
    
    // MARK: Private Methods
    
    private var selectedNode: FileNode? {
        
        self.selection.flatMap { self.document.fileNode?.node(with: $0, keyPath: \.id) }
    }
    
    
    @ViewBuilder private func contextMenu(node: FileNode?) -> some View {
        
        if let node {
            Button(String(localized: "Show in Finder", table: "Document", comment: "menu item label")) {
                NSWorkspace.shared.activateFileViewerSelecting([node.fileURL])
            }
            
            Divider()
            
            if !node.isDirectory {
                Button(String(localized: "Open with External Editor", table: "Document", comment: "menu item label")) {
                    NSWorkspace.shared.open(node.fileURL)
                }
            }
            if NSDocumentController.shared.document(for: node.fileURL) == nil {
                Button(String(localized: "Open in New Window", table: "Document", comment: "menu item label")) {
                    NSDocumentController.shared.openDocument(withContentsOf: node.fileURL, display: true) { (_, _, error) in
                        self.error = error
                    }
                }
            }
            
            Divider()
            
            if node.isWritable {
                Button(String(localized: "Move to Trash", table: "Document", comment: "menu item label")) {
                    do {
                        try self.document.trashItem(at: node.fileURL)
                        AudioServicesPlaySystemSound(.moveToTrash)
                    } catch {
                        self.error = error
                    }
                }
            }
            
            Divider()
        }
        
        Toggle(String(localized: "Show Filename Extensions", table: "Document", comment: "menu item label (Check how Apple translates the term “filename extension.”)"), isOn: $showsFilenameExtensions)
        Toggle(String(localized: "Show Hidden Files", table: "Document", comment: "menu item label"), isOn: $showsHiddenFiles)
    }
}


private struct NodeView: View {
    
    var node: FileNode
    var onEdit: (String) -> Bool
    
    @AppStorage(.fileBrowserShowsFilenameExtensions) private var showsFilenameExtensions
    
    @FocusState var isFocused: Bool
    
    @State private var name: String
    
    
    init(node: FileNode, onEdit: @escaping (String) -> Bool) {
        
        self.node = node
        self.onEdit = onEdit
        self._name = State(initialValue: node.name)
        
        self.resetName()
    }
    
    
    var body: some View {
        
        Label {
            TextField(text: $name, label: EmptyView.init)
                .focused($isFocused)
        } icon: {
            Image(systemName: self.node.isDirectory
                  ? "folder"
                  : self.node.isWritable ? "doc" : "lock")
        }
        .opacity((self.node.isHidden && !self.isFocused) ? 0.5 : 1)
        .onChange(of: self.showsFilenameExtensions) {
            self.resetName()
        }
        .onChange(of: self.isFocused) { (_, newValue) in
            if newValue {
                // enter focus
                self.name = self.node.name
            } else {
                // exit focus
                guard
                    self.name != self.node.name,
                    self.onEdit(self.name)
                else {
                    self.resetName()
                    return
                }
            }
        }
    }
    
    
    private func resetName() {
        
        self.name = self.showsFilenameExtensions ? self.node.name : self.node.name.deletingPathExtension
    }
}



// MARK: - Preview

#Preview(traits: .fixedLayout(width: 200, height: 400)) {
    FileBrowserView(document: DirectoryDocument())
        .listStyle(.sidebar)
}
