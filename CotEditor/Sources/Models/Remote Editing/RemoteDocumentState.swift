//
//  RemoteDocumentState.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-09-28.
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

import AppKit
import RMate

/// The document state for a remote file.
@MainActor final class RemoteDocumentState {
    
    // MARK: Public Properties
    
    weak var document: RemoteDocument?
    
    
    // MARK: Readonly Properties
    
    let file: RMateFile
    private(set) var isSaving = false
    
    
    // MARK: Private Properties
    
    private var pendingChangeCountToken: Any?
    private var hasShownDisconnectAlert = false
    private var isShowingDisconnectAlert = false
    
    
    // MARK: Lifecycle
    
    /// Initializes the state for a remote file.
    ///
    /// - Parameter file: The remote file.
    init(file: RMateFile) {
        
        self.file = file
        
        file.onDisconnect = { [weak self] in self?.didDisconnect() }
    }
    
    
    // MARK: Public Methods
    
    /// Begins a save operation before writing the local working copy.
    func beginSaving() {
        
        self.isSaving = true
    }
    
    
    /// Clears the pending save state after a failed write or transmission.
    func cancelSaving() {
        
        self.isSaving = false
        self.pendingChangeCountToken = nil
    }
    
    
    /// Defers clearing the document's changes until transmission completes.
    ///
    /// - Parameter token: The change count token for the saved snapshot.
    /// - Returns: Whether the change count update was deferred.
    func deferChangeCountUpdate(withToken token: Any) -> Bool {
        
        guard self.isSaving else { return false }
        
        self.pendingChangeCountToken = token
        
        return true
    }
    
    
    /// Sends the saved content and updates the document's change count on success.
    ///
    /// - Parameters:
    ///   - data: The file content written to the working copy.
    ///   - operation: The original document save operation.
    /// - Throws: `CocoaError.userCancelled` after presenting the disconnect alert if sending fails.
    func send(_ data: Data, for operation: NSDocument.SaveOperationType) async throws(CocoaError) {
        
        do {
            try await self.file.save(data)
        } catch {
            self.cancelSaving()
            self.presentDisconnectAlert(explicitly: operation == .saveOperation)
            throw CocoaError(.userCancelled)
        }
        
        self.isSaving = false
        if let token = self.pendingChangeCountToken {
            self.document?.updateChangeCount(withToken: token, for: operation)
        }
        self.pendingChangeCountToken = nil
    }
    
    
    /// Presents an alert for a disconnected file.
    ///
    /// - Parameter explicitly: Whether to show the alert again for an explicit save attempt.
    func presentDisconnectAlert(explicitly: Bool = false) {
        
        guard
            explicitly || !self.hasShownDisconnectAlert,
            !self.isShowingDisconnectAlert,
            let document, let window = document.windowForSheet
        else { return }
        
        self.hasShownDisconnectAlert = true
        self.isShowingDisconnectAlert = true
        
        let alert = NSAlert()
        alert.messageText = String(localized: "RemoteDocumentDisconnectAlert.messageText",
                                   defaultValue: "The remote connection for “\(self.file.metadata.displayName)” was disconnected.")
        alert.informativeText = String(localized: "RemoteDocumentDisconnectAlert.informativeText",
                                       defaultValue: "Changes can no longer be saved remotely. To keep your changes, save the document on this Mac.")
        alert.addButton(withTitle: String(localized: "Action.saveAs.label",
                                          defaultValue: "Save As…"))
        alert.addButton(withTitle: String(localized: "RemoteDocumentDisconnectAlert.button.later",
                                          defaultValue: "Later", comment: "button"))
        alert.helpAnchor = "howto_edit_remote"
        alert.showsHelp = true
        
        alert.beginSheetModal(for: window) { [weak self, weak document] response in
            self?.isShowingDisconnectAlert = false
            
            if response == .alertFirstButtonReturn {
                document?.saveAs(nil)
            }
        }
    }
    
    
    // MARK: Private Methods
    
    /// Updates the document after the connection is lost.
    private func didDisconnect() {
        
        self.document?.windowController?.synchronizeWindowTitleWithDocumentName()
        
        if self.document?.isDocumentEdited == true {
            self.presentDisconnectAlert()
        }
    }
}
