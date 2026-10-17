//
//  CloudSettingsCopiesView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-10-14.
//
//  ---------------------------------------------------------------------------
//
//  © 2026 1024jp
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
import SemanticVersioning

struct CloudSettingsCopiesView: View {
    
    typealias Item = CloudSettingsManager.Archive
    
    
    @Binding var archives: [Item]?
    var loadingError: any Error?
    
    @State var currentArchiveURL: URL?
    
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var selection: URL?
    @State private var deletingArchive: Item?
    @State private var deletingArchiveURL: URL?
    @State private var error: any Error?
    
    
    var body: some View {
        
        VStack(alignment: .leading) {
            List((self.archives ?? []).sortedBySource, selection: $selection) { archive in
                HStack {
                    VStack(alignment: .leading) {
                        Text(archive.displayName)
                        
                        if let info = archive.info {
                            Text([
                                info.date.formatted(date: .long, time: .omitted),
                                String(localized: "Version \(info.version, format: .version)",
                                       table: "CloudSettingsCopies", comment: "%@ is version number"),
                            ], format: .list(type: .and, width: .narrow))
                            .foregroundStyle(.secondary)
                            .font(.caption)
                            
                        }
                    }
                    
                    // -> Compare paths to ignore trailing slash differences between directory URLs.
                    if archive.url.standardizedFileURL.path == self.currentArchiveURL?.standardizedFileURL.path {
                        Spacer()
                        Text("This Mac", tableName: "CloudSettingsCopies",
                             comment: "label for the current Mac; refer to the same expression by Apple.")
                        .fontWeight(.medium)
                        .padding(.vertical, 2)
                        .padding(.horizontal, 4)
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(lineWidth: 0.5))
                        .foregroundStyle(.secondary)
                        .controlSize(.small)
                    }
                }
            }
            .clipShape(.rect(cornerRadius: 7, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 7, style: .continuous).strokeBorder(.separator))
            .overlay {
                if let loadingError {
                    Text(loadingError.localizedDescription)
                        .padding()
                } else if self.archives == nil {
                    ProgressView()
                } else if self.archives?.isEmpty == true {
                    Text("No Settings Copies in iCloud", tableName: "GeneralSettings")
                }
            }
            .frame(minHeight: 100, idealHeight: 220)
            .onChange(of: self.archives?.map(\.id)) {
                if self.selectedArchive == nil {
                    self.selection = nil
                    self.deletingArchive = nil
                }
            }
            
            HStack {
                Button(.init("Delete Copy", table: "CloudSettingsCopies", comment: "verb; button; refer to the same expression by Apple."), role: .destructive) {
                    self.deletingArchive = self.selectedArchive
                }
                .disabled(self.selectedArchive == nil || self.loadingError != nil)
                if self.deletingArchiveURL != nil {
                    ProgressView()
                        .controlSize(.small)
                }
            }
            .padding(.bottom, 4)
            
            Text("To stop saving a copy, turn off “Keep a copy in iCloud” on the Mac it comes from.", tableName: "CloudSettingsCopies")
                .fixedSize(horizontal: false, vertical: true)
            
            HStack {
                HelpLink(anchor: "howto_port_settings")
                
                Spacer()
                Button(role: .close) {
                    self.dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(.top)
        }
        .disabled(self.deletingArchiveURL != nil)
        .interactiveDismissDisabled(self.deletingArchiveURL != nil)
        .task {
            guard self.currentArchiveURL == nil else { return }
            self.currentArchiveURL = try? await CloudSettingsManager.shared.currentArchiveURL()
        }
        .task(id: self.deletingArchiveURL) {
            await self.deleteArchive()
        }
        .confirmationDialog(.init("Are you sure you want to delete “\(self.deletingArchive?.displayName ?? String(localized: .unknown))” from iCloud?",
                                  table: "CloudSettingsCopies",
                                  comment: "Refer to the same expression in FinderKit.framework by Apple."),
                            item: $deletingArchive) { archive in
            Button(.init("Action.delete.label", defaultValue: "Delete"), role: .destructive) {
                self.deletingArchiveURL = archive.url
            }
        } message: { _ in
            Text(.init("DeletionConfirmation.message", defaultValue: "This action cannot be undone."))
        }
        .alert(error: $error)
    }
    
    
    /// The selected settings copy, if it still exists in the current list.
    private var selectedArchive: Item? {
        
        self.archives?.first { $0.url == self.selection }
    }
    
    
    /// Deletes the requested copy and removes it from the shared archive list.
    private func deleteArchive() async {
        
        guard let url = self.deletingArchiveURL else { return }
        
        defer { self.deletingArchiveURL = nil }
        
        do {
            try await CloudSettingsManager.shared.delete(url)
            guard !Task.isCancelled else { return }
            self.archives?.removeAll { $0.url == url }
        } catch {
            guard !Task.isCancelled else { return }
            self.error = error
        }
    }
}


extension CloudSettingsManager.Archive {
    
    /// The source's display name, falling back to the filename for legacy or unreadable metadata.
    var displayName: String {
        
        let names = [self.info?.machineName, self.info?.userName].compactMap(\.self).filter { !$0.isEmpty }
        
        return names.isEmpty ? self.url.deletingPathExtension().lastPathComponent : names.joined(separator: " — ")
    }
}


extension [CloudSettingsManager.Archive] {
    
    /// The copies sorted by source name and then by the most recent save date.
    var sortedBySource: Self {
        
        self.sorted(using: [
            KeyPathComparator(\.displayName, comparator: .localizedStandard),
            KeyPathComparator(\.info?.date, order: .reverse),
        ])
    }
}


// MARK: - Preview

#Preview(traits: .fixedLayout(width: 420, height: 380)) {
    @Previewable @State var archives: [CloudSettingsManager.Archive]? = [
        .init(url: URL(filePath: "/Preview/Settings/MacBook Air.cotsettings", directoryHint: .isDirectory),
              info: .init(date: .now.addingTimeInterval(-86400), version: .init(7, 1, 0), machineName: "MacBook Air", userName: "alex")),
        .init(url: URL(filePath: "/Preview/Settings/MacBook Pro.cotsettings", directoryHint: .isDirectory),
              info: .init(date: .now, version: .init(7, 1, 0), machineName: "MacBook Pro", userName: "clarus")),
        .init(url: URL(filePath: "/Preview/Settings/Unknown.cotsettings", directoryHint: .isDirectory)),
    ]
    
    CloudSettingsCopiesView(archives: $archives, loadingError: nil, currentArchiveURL: archives?[1].url)
        .scenePadding()
}
