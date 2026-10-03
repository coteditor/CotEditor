//
//  RemoteEditingController.swift
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

public import Foundation
public import RMate
import AppKit
import Combine
import Network
import OSLog
import UniformTypeIdentifiers
import Defaults
import LineEnding

/// Manages remote editing settings and incoming files.
@MainActor final class RemoteEditingController {
    
    // MARK: Public Properties
    
    static let shared = RemoteEditingController()
    nonisolated static let fileStore = RMateFileStore(directory: .applicationSupportDirectory
        .appending(component: "CotEditor", directoryHint: .isDirectory)
        .appending(path: "Remote Documents", directoryHint: .isDirectory))
    
    
    // MARK: Private Properties
    
    private let server = RMateServer(applicationName: Bundle.main.bundleName, onOpen: RemoteEditingController.open, onError: { NSApp.presentError($0) })
    private var settingsObserver: AnyCancellable?
    
    
    // MARK: Public Methods
    
    /// The error message for the remote editing settings.
    var errorMessage: String? {
        
        self.server.error.map { $0.recoverySuggestion ?? $0.localizedDescription }
    }
    
    
    /// Starts the receiver, removes discarded working copies, and observes settings.
    func start() {
        
        guard self.settingsObserver == nil else { return }
        
        Task(priority: .background) { @concurrent in
            do {
                try Self.fileStore.removeDiscardedFiles()
            } catch {
                Logger.app.error("Failed deleting discarded remote working copies: \(error)")
            }
        }
        
        let defaults = UserDefaults.standard
        self.settingsObserver = defaults.publisher(for: .enablesRemoteEditing)
            .prepend(defaults[.enablesRemoteEditing])
            .combineLatest(defaults.publisher(for: .remoteEditingPort).prepend(defaults[.remoteEditingPort]))
            .sink { [weak self] enabled, port in
                self?.server.listen(port: enabled ? port : nil)
            }
    }
    
    
    // MARK: Private Methods
    
    /// Opens a received file as a document.
    ///
    /// - Parameters:
    ///   - file: The remote file.
    ///   - request: The file content and opening options.
    /// - Throws: An error if creating or reading the working copy failed, or `CancellationError` if opening was canceled.
    private static func open(_ file: RMateFile, request: RMateOpenRequest) async throws {
        
        try Task.checkCancellation()
        
        // use a local working copy for the NSDocument file operations
        let url = try await { @concurrent [metadata = file.metadata] () async throws in
            try self.fileStore.makeBackingFile(data: request.data, metadata: metadata)
        }()
        
        let document: RemoteDocument
        do {
            try Task.checkCancellation()
            guard file.isConnected else { throw CancellationError() }
            
            document = try RemoteDocument(contentsOf: url, ofType: UTType.plainText.identifier)
        } catch {
            try? self.fileStore.removeBackingFile(at: url)
            throw error
        }
        
        document.remoteState = RemoteDocumentState(file: file)
        if let name = request.fileType, name == SyntaxName.none || SyntaxManager.shared.settingNames.contains(name) {
            document.setSyntax(name: name)
        }
        DocumentController.shared.addDocument(document)
        document.didMakeDocumentForExistingFile(url: url)
        document.makeWindowControllers()
        document.showWindows()
        
        if let lineNumber = request.lineNumber, let textView = document.textView {
            let location = document.lineEndingScanner.lineRange(for: lineNumber)?.location ?? document.textStorage.length
            let range = NSRange(location: location, length: 0)
            
            textView.setSelectedRange(range)
            textView.scrollRangeToVisible(range)
        }
        
        NSApp.activate()
    }
}


extension RMateServer.ListenError: @retroactive LocalizedError {
    
    public var errorDescription: String? {
        
        switch self {
            case .invalidPort:
                String(localized: "RMateServer.ListenError.invalidPort.description",
                       defaultValue: "The port number is invalid.",
                       comment: "Refer the same expression by Apple.")
            case .failed(NWError.posix(.EADDRINUSE)):
                String(localized: "RMateServer.ListenError.addressInUse.description",
                       defaultValue: "The port is already in use.")
            case .failed(NWError.posix(let code)):
                (POSIXError(code) as NSError).localizedFailureReason ?? POSIXError(code).localizedDescription
            case .failed(let error):
                (error as NSError).localizedFailureReason ?? error.localizedDescription
        }
    }
    
    
    public var recoverySuggestion: String? {
        
        switch self {
            case .invalidPort:
                String(localized: "RMateServer.ListenError.invalidPort.recoverySuggestion",
                       defaultValue: "Enter a port number from 1 to 65535.")
            case .failed(let error):
                (error as NSError).localizedRecoverySuggestion
        }
    }
}


extension RMateServer.ReceiveError: @retroactive LocalizedError {
    
    public var errorDescription: String? {
        
        switch self {
            case .fileTooLarge:
                String(localized: "RMateServer.ReceiveError.fileTooLarge.description",
                       defaultValue: "The remote file is too large to open.")
        }
    }
    
    
    public var recoverySuggestion: String? {
        
        switch self {
            case .fileTooLarge(let maximumSize):
                String(localized: "RMateServer.ReceiveError.fileTooLarge.recoverySuggestion",
                       defaultValue: "Remote editing supports files up to \(Int64(maximumSize), format: .byteCount(style: .binary)).",
                       comment: "%@ is file size, such as \"100 MB\"")
        }
    }
    
    
    public var helpAnchor: String? {
        
        "howto_edit_remote"
    }
}
