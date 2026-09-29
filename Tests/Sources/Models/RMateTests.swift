//
//  RMateTests.swift
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
import Testing
import Defaults
import URLUtils
@testable import RMate
@testable import CotEditor

struct RMateTests {
    
    /// Tests that remote documents support the same native file types as ordinary documents.
    @Test @MainActor func remoteDocumentSupportsNativeTypes() {
        
        #expect(!RemoteDocument.readableTypes.isEmpty)
        #expect(RemoteDocument.readableTypes == Document.readableTypes)
        #expect(RemoteDocument.writableTypes == Document.writableTypes)
        
        for type in Document.writableTypes {
            #expect(RemoteDocument.isNativeType(type) == Document.isNativeType(type))
        }
        #expect(!RemoteDocument.isNativeType("com.coteditor.unsupported"))
    }
    
    
    /// Tests that ordinary files use the local document class and save normally.
    ///
    /// - Throws: An error if creating, opening, or saving the file fails.
    @Test @MainActor func ordinaryFileUsesDocument() async throws {
        
        let url = FileManager.default.temporaryDirectory.appending(component: UUID().uuidString + ".txt")
        try Data("old".utf8).write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }
        let document = try #require(DocumentController.shared.makeDocument(withContentsOf: url, ofType: "public.plain-text") as? Document)
        defer { document.close() }
        #expect(!(document is RemoteDocument))
        
        document.textStorage.replaceCharacters(in: NSRange(location: 0, length: 3), with: "local")
        document.updateChangeCount(.changeDone)
        try await self.save(document, to: url, operation: .saveOperation)
        #expect(!document.isDocumentEdited)
        #expect(try Data(contentsOf: url) == Data("local".utf8))
        #expect(document.printingDocumentInfo.filePath == url.pathAbbreviatingWithTilde)
    }
    
    
    /// Tests that reopening a working copy or its autosave restores the remote document class.
    ///
    /// - Parameter usesAutosavedContents: Whether to read unsaved content from a separate file.
    /// - Throws: An error if creating or restoring the document fails.
    @Test(arguments: [false, true]) @MainActor func restorationUsesRemoteDocument(usesAutosavedContents: Bool) throws {
        
        let (document, url) = try self.makeDisconnectedDocument()
        defer { self.remove(document, url: url) }
        let backup = FileManager.default.temporaryDirectory.appending(component: UUID().uuidString + ".txt")
        try Data("recovery".utf8).write(to: backup)
        defer { try? FileManager.default.removeItem(at: backup) }
        
        let contentsURL = usesAutosavedContents ? backup : url
        let restored = try #require(DocumentController.shared.makeDocument(for: url, withContentsOf: contentsURL, ofType: "public.plain-text") as? RemoteDocument)
        defer { self.remove(restored, url: url) }
        #expect(restored.remoteState?.file.isConnected == false)
        #expect(restored.remoteState?.file.metadata.path == "/tmp/test.txt")
        #expect(restored.displayName == "host:test.txt")
        #expect(restored.textStorage.string == (usesAutosavedContents ? "recovery" : "old"))
        #expect(restored.isDocumentEdited == usesAutosavedContents)
        #expect(restored.printingDocumentInfo.filePath == "/tmp/test.txt")
        #expect(restored.printingDocumentInfo.lastModifiedDate == nil)
    }
    
    
    /// Tests that a duplicate is a local document without a remote association.
    ///
    /// - Throws: An error if creating or duplicating the document fails.
    @Test @MainActor func duplicateUsesDocument() throws {
        
        let (document, url) = try self.makeDisconnectedDocument()
        defer { self.remove(document, url: url) }
        
        let duplicate = try #require(DocumentController.shared.makeDocument(for: nil, withContentsOf: url, ofType: "public.plain-text") as? Document)
        defer { duplicate.close() }
        #expect(!(duplicate is RemoteDocument))
        #expect(duplicate.fileURL == nil)
        #expect(duplicate.textStorage.string == "old")
    }
    
    
    @Test @MainActor func disconnectedSaveKeepsChanges() async throws {
        
        let (document, url) = try self.makeDisconnectedDocument()
        defer { self.remove(document, url: url) }
        
        document.textStorage.replaceCharacters(in: NSRange(location: 0, length: 3), with: "changed")
        document.updateChangeCount(.changeDone)
        
        await #expect(throws: CocoaError.self) {
            try await self.save(document, to: url, operation: .saveOperation)
        }
        #expect(document.isDocumentEdited)
        #expect(try Data(contentsOf: url) == Data("old".utf8))
    }
    
    
    @Test(arguments: [true, false]) @MainActor func disconnectedAutosaveKeepsRecoveryCopy(implicitlyCancellable: Bool) async throws {
        
        let (document, url) = try self.makeDisconnectedDocument()
        defer { self.remove(document, url: url) }
        
        document.textStorage.replaceCharacters(in: NSRange(location: 0, length: 3), with: "recovery")
        document.updateChangeCount(.changeDone)
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
            document.autosave(withImplicitCancellability: implicitlyCancellable) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
        let backup = try #require(document.autosavedContentsFileURL)
        #expect(try Data(contentsOf: backup) == Data("recovery".utf8))
        #expect(try Data(contentsOf: url) == Data("old".utf8))
        #expect(document.isDocumentEdited)
        #expect(!document.hasUnautosavedChanges)
        
        let delegate = CloseDelegate()
        document.canClose(withDelegate: delegate, shouldClose: #selector(CloseDelegate.document(_:shouldClose:contextInfo:)), contextInfo: nil)
        #expect(delegate.result == false)
    }
    
    
    @Test @MainActor func saveAsDetachesRemoteIdentity() async throws {
        
        let (document, url) = try self.makeDisconnectedDocument()
        defer { self.remove(document, url: url) }
        #expect(document.writableTypes(for: .saveAsOperation).contains("public.plain-text"))
        
        let destination = FileManager.default.temporaryDirectory.appending(component: UUID().uuidString + ".txt")
        defer { try? FileManager.default.removeItem(at: destination) }
        
        document.textStorage.replaceCharacters(in: NSRange(location: 0, length: 3), with: "local")
        document.updateChangeCount(.changeDone)
        
        try await self.save(document, to: destination, operation: .saveAsOperation)
        #expect(document.remoteState == nil)
        #expect(document.fileURL == destination)
        #expect(document.writableTypes(for: .saveAsOperation).contains("public.plain-text"))
        #expect(!document.isDocumentEdited)
        #expect(try Data(contentsOf: destination) == Data("local".utf8))
        #expect(!FileManager.default.fileExists(atPath: url.path(percentEncoded: false)))
        #expect(throws: CocoaError.self) { try RemoteEditingController.fileStore.metadata(for: url) }
        #expect(document.printingDocumentInfo.filePath == destination.pathAbbreviatingWithTilde)
        #expect(document.printingDocumentInfo.lastModifiedDate != nil)
        #expect(document.validateUserInterfaceItem(NSMenuItem(title: "", action: #selector(DataDocument.showInFinder(_:)), keyEquivalent: "")))
        
        document.textStorage.append(NSAttributedString(string: " edit"))
        document.updateChangeCount(.changeDone)
        try await self.save(document, to: destination, operation: .autosaveInPlaceOperation)
        #expect(!document.isDocumentEdited)
        #expect(try Data(contentsOf: destination) == Data("local edit".utf8))
        
        let restored = try DocumentController.shared.makeDocument(for: destination, withContentsOf: destination, ofType: "public.plain-text")
        defer { restored.close() }
        #expect(restored is Document)
        #expect(!(restored is RemoteDocument))
    }
    
    
    /// Tests that saving a local copy neither sends changes nor detaches the remote file.
    ///
    /// - Throws: An error if creating or saving the document fails.
    @Test(.timeLimit(.minutes(1))) @MainActor func saveToKeepsRemoteIdentity() async throws {
        
        let (document, url) = try self.makeDisconnectedDocument()
        defer { self.remove(document, url: url) }
        
        let connection = TestConnection()
        let file = RMateFile(metadata: try #require(document.remoteState?.file.metadata), connection: connection)
        document.remoteState = RemoteDocumentState(file: file)
        document.textStorage.replaceCharacters(in: NSRange(location: 0, length: 3), with: "copy")
        document.updateChangeCount(.changeDone)
        
        let destination = FileManager.default.temporaryDirectory.appending(component: UUID().uuidString + ".txt")
        defer { try? FileManager.default.removeItem(at: destination) }
        
        try await self.save(document, to: destination, operation: .saveToOperation)
        #expect(document.remoteState?.file === file)
        #expect(file.isConnected)
        #expect(document.remoteState?.isSaving == false)
        #expect(document.fileURL == url)
        #expect(document.isDocumentEdited)
        #expect(connection.data == nil)
        #expect(try Data(contentsOf: destination) == Data("copy".utf8))
        #expect(try Data(contentsOf: url) == Data("old".utf8))
    }
    
    
    @Test @MainActor func failedSaveAsKeepsWorkingCopy() async throws {
        
        let (document, url) = try self.makeDisconnectedDocument()
        defer { self.remove(document, url: url) }
        
        let parentURL = FileManager.default.temporaryDirectory.appending(component: UUID().uuidString)
        try Data().write(to: parentURL)
        defer { try? FileManager.default.removeItem(at: parentURL) }
        
        await #expect(throws: CocoaError.self) {
            try await self.save(document, to: parentURL.appending(component: "test.txt"), operation: .saveAsOperation)
        }
        #expect(document.remoteState != nil)
        #expect(document.fileURL == url)
        #expect(try Data(contentsOf: url) == Data("old".utf8))
        #expect(try RemoteEditingController.fileStore.metadata(for: url)?.path == "/tmp/test.txt")
    }
    
    
    /// Tests that a failed local write does not leave the remote save in progress.
    ///
    /// - Throws: An error if preparing the working copy or retrying the save fails.
    @Test(.timeLimit(.minutes(1))) @MainActor func failedWorkingCopySaveAllowsRetry() async throws {
        
        let (document, url) = try self.makeDisconnectedDocument()
        defer { self.remove(document, url: url) }
        
        let connection = TestConnection()
        document.remoteState = RemoteDocumentState(file: RMateFile(metadata: try #require(document.remoteState?.file.metadata), connection: connection))
        document.textStorage.replaceCharacters(in: NSRange(location: 0, length: 3), with: "retry")
        document.updateChangeCount(.changeDone)
        
        let parentURL = FileManager.default.temporaryDirectory.appending(component: UUID().uuidString)
        try Data().write(to: parentURL)
        defer { try? FileManager.default.removeItem(at: parentURL) }
        
        let invalidURL = parentURL.appending(component: "test.txt")
        document.fileURL = invalidURL
        defer { document.fileURL = url }
        
        await #expect(throws: CocoaError.self) {
            try await self.save(document, to: invalidURL, operation: .saveOperation)
        }
        #expect(document.remoteState?.isSaving == false)
        #expect(document.isDocumentEdited)
        #expect(connection.data == nil)
        
        document.fileURL = url
        let task = Task { try await self.save(document, to: url, operation: .saveOperation) }
        await connection.waitForSave()
        #expect(connection.data == Data("retry".utf8))
        connection.finishSave(succeeded: true)
        try await task.value
        #expect(document.remoteState?.isSaving == false)
        #expect(!document.isDocumentEdited)
    }
    
    
    @Test @MainActor func closeRemovesOnlyItsWorkingCopy() throws {
        
        let (document, url) = try self.makeDisconnectedDocument()
        let (otherDocument, otherURL) = try self.makeDisconnectedDocument()
        defer { self.remove(otherDocument, url: otherURL) }
        
        document.close()
        document.close()
        #expect(!FileManager.default.fileExists(atPath: url.path(percentEncoded: false)))
        #expect(throws: CocoaError.self) { try RemoteEditingController.fileStore.metadata(for: url) }
        #expect(try Data(contentsOf: otherURL) == Data("old".utf8))
        #expect(try RemoteEditingController.fileStore.metadata(for: otherURL)?.path == "/tmp/test.txt")
    }
    
    
    @Test(arguments: [
        (true, true, false, false),
        (true, true, true, false),
        (true, false, false, false),
        (true, false, true, true),
        (false, true, false, false),
        (false, true, true, false),
        (false, false, false, false),
        (false, false, true, false),
    ])
    @MainActor func terminationKeepsWorkingCopyForRestoration(keepsWindows: Bool, isConnected: Bool, hasChanges: Bool, restores: Bool) throws {
        
        let (document, url) = try self.makeDisconnectedDocument()
        let connection = TestConnection()
        connection.isConnected = isConnected
        document.remoteState = RemoteDocumentState(file: RMateFile(metadata: try #require(document.remoteState?.file.metadata), connection: connection))
        if hasChanges {
            document.textStorage.append(NSAttributedString(string: " edit"))
            document.updateChangeCount(.changeDone)
        }
        
        defer { try? RemoteEditingController.fileStore.removeBackingFile(at: url) }
        
        self.withQuitAlwaysKeepsWindows(keepsWindows) {
            document.close()
        }
        
        if restores {
            #expect(try Data(contentsOf: url) == Data("old".utf8))
            #expect(try RemoteEditingController.fileStore.metadata(for: url)?.path == "/tmp/test.txt")
        } else {
            #expect(!FileManager.default.fileExists(atPath: url.path(percentEncoded: false)))
            #expect(throws: CocoaError.self) { try RemoteEditingController.fileStore.metadata(for: url) }
        }
    }
    
    
    @Test(arguments: [NSDocument.SaveOperationType.saveOperation, .autosaveInPlaceOperation])
    @MainActor func changesRemainUnsavedUntilTransmissionCompletes(operation: NSDocument.SaveOperationType) async throws {
        
        let (document, url) = try self.makeDisconnectedDocument()
        defer { self.remove(document, url: url) }
        
        let connection = TestConnection()
        document.remoteState = RemoteDocumentState(file: RMateFile(metadata: try #require(document.remoteState?.file.metadata), connection: connection))
        document.textStorage.replaceCharacters(in: NSRange(location: 0, length: 3), with: "snapshot")
        document.updateChangeCount(.changeDone)
        
        let task = Task { try await self.save(document, to: url, operation: operation) }
        await connection.waitForSave()
        #expect(document.remoteState?.isSaving == true)
        #expect(document.isDocumentEdited)
        #expect(connection.data == Data("snapshot".utf8))
        await #expect(throws: CocoaError(.userCancelled)) {
            try await self.save(document, to: url, operation: operation)
        }
        connection.finishSave(succeeded: true)
        try await task.value
        #expect(document.remoteState?.isSaving == false)
        #expect(!document.isDocumentEdited)
    }
    
    
    /// Tests that closing waits for a pending save without blocking transmission.
    ///
    /// - Parameters:
    ///   - operation: The pending save operation.
    ///   - succeeds: Whether the transmission succeeds.
    /// - Throws: An error if creating or saving the document fails unexpectedly.
    @Test(.timeLimit(.minutes(1)), arguments: [NSDocument.SaveOperationType.saveOperation, .autosaveInPlaceOperation], [true, false])
    @MainActor func closingWaitsForTransmission(operation: NSDocument.SaveOperationType, succeeds: Bool) async throws {
        
        let (document, url) = try self.makeDisconnectedDocument()
        defer { self.remove(document, url: url) }
        
        let connection = TestConnection()
        document.remoteState = RemoteDocumentState(file: RMateFile(metadata: try #require(document.remoteState?.file.metadata), connection: connection))
        document.textStorage.replaceCharacters(in: NSRange(location: 0, length: 3), with: "pending")
        document.updateChangeCount(.changeDone)
        
        let task = Task { try await self.save(document, to: url, operation: operation) }
        await connection.waitForSave()
        
        let delegate = CloseDelegate()
        document.canClose(withDelegate: delegate, shouldClose: #selector(CloseDelegate.document(_:shouldClose:contextInfo:)), contextInfo: nil)
        #expect(delegate.result == nil)
        #expect(document.isDocumentEdited)
        
        connection.finishSave(succeeded: succeeds)
        if succeeds {
            try await task.value
        } else {
            await #expect(throws: CocoaError(.userCancelled)) { try await task.value }
        }
        #expect(await delegate.waitForResult() == succeeds)
        #expect(document.isDocumentEdited == !succeeds)
        #expect(document.remoteState?.isSaving == false)
    }
    
    
    /// Tests that closing also saves edits made while the first transmission is pending.
    ///
    /// - Throws: An error if creating or saving the document fails.
    @Test(.timeLimit(.minutes(1))) @MainActor func closingSavesEditsDuringTransmission() async throws {
        
        let (document, url) = try self.makeDisconnectedDocument()
        defer { self.remove(document, url: url) }
        
        let connection = TestConnection()
        document.remoteState = RemoteDocumentState(file: RMateFile(metadata: try #require(document.remoteState?.file.metadata), connection: connection))
        document.textStorage.replaceCharacters(in: NSRange(location: 0, length: 3), with: "snapshot")
        document.updateChangeCount(.changeDone)
        
        let task = Task { try await self.save(document, to: url, operation: .saveOperation) }
        await connection.waitForSave()
        
        let delegate = CloseDelegate()
        document.canClose(withDelegate: delegate, shouldClose: #selector(CloseDelegate.document(_:shouldClose:contextInfo:)), contextInfo: nil)
        document.textStorage.append(NSAttributedString(string: " later edit"))
        document.updateChangeCount(.changeDone)
        connection.finishSave(succeeded: true)
        try await task.value
        
        await connection.waitForSave()
        #expect(delegate.result == nil)
        #expect(document.isDocumentEdited)
        #expect(connection.data == Data("snapshot later edit".utf8))
        connection.finishSave(succeeded: true)
        #expect(await delegate.waitForResult())
        #expect(!document.isDocumentEdited)
    }
    
    
    @Test @MainActor func editsDuringTransmissionRemainUnsaved() async throws {
        
        let (document, url) = try self.makeDisconnectedDocument()
        defer { self.remove(document, url: url) }
        
        let connection = TestConnection()
        document.remoteState = RemoteDocumentState(file: RMateFile(metadata: try #require(document.remoteState?.file.metadata), connection: connection))
        document.textStorage.replaceCharacters(in: NSRange(location: 0, length: 3), with: "snapshot")
        document.updateChangeCount(.changeDone)
        
        let task = Task { try await self.save(document, to: url, operation: .saveOperation) }
        await connection.waitForSave()
        document.textStorage.append(NSAttributedString(string: " later edit"))
        document.updateChangeCount(.changeDone)
        connection.finishSave(succeeded: true)
        try await task.value
        #expect(connection.data == Data("snapshot".utf8))
        #expect(document.isDocumentEdited)
        #expect(document.textStorage.string == "snapshot later edit")
    }
    
    
    @Test @MainActor func transmissionFailureKeepsChanges() async throws {
        
        let (document, url) = try self.makeDisconnectedDocument()
        defer { self.remove(document, url: url) }
        
        let connection = TestConnection()
        document.remoteState = RemoteDocumentState(file: RMateFile(metadata: try #require(document.remoteState?.file.metadata), connection: connection))
        document.textStorage.replaceCharacters(in: NSRange(location: 0, length: 3), with: "unsent")
        document.updateChangeCount(.changeDone)
        
        let task = Task { try await self.save(document, to: url, operation: .autosaveInPlaceOperation) }
        await connection.waitForSave()
        connection.finishSave(succeeded: false)
        await #expect(throws: CocoaError.self) { try await task.value }
        #expect(document.remoteState?.isSaving == false)
        #expect(document.isDocumentEdited)
        #expect(document.textStorage.string == "unsent")
    }
    
    
    // MARK: Private Methods
    
    /// Performs a synchronous operation with a temporary window restoration setting.
    ///
    /// - Parameters:
    ///   - keepsWindows: Whether the application keeps windows for restoration during the operation.
    ///   - operation: The synchronous operation to perform before restoring the previous setting.
    @MainActor private func withQuitAlwaysKeepsWindows(_ keepsWindows: Bool, perform operation: () -> Void) {
        
        let defaults = UserDefaults.standard
        let key = DefaultKeys.quitAlwaysKeepsWindows.rawValue
        let previousValue = defaults.persistentDomain(forName: Bundle.main.bundleIdentifier!)?[key]
        defer {
            if let previousValue {
                defaults.set(previousValue, forKey: key)
            } else {
                defaults.removeObject(forKey: key)
            }
        }
        
        defaults[.quitAlwaysKeepsWindows] = keepsWindows
        operation()
    }
    
    /// Creates a document from a disconnected remote file.
    ///
    /// - Returns: The document and its working copy URL.
    /// - Throws: A filesystem or decoding error.
    @MainActor private func makeDisconnectedDocument() throws -> (RemoteDocument, URL) {
        
        let metadata = RMateFile.Metadata(displayName: "host:test.txt", path: "/tmp/test.txt")
        let url = try RemoteEditingController.fileStore.makeBackingFile(data: Data("old".utf8), metadata: metadata)
        let document = try #require(DocumentController.shared.makeDocument(withContentsOf: url, ofType: "public.plain-text") as? RemoteDocument)
        #expect(document.remoteState?.file.isConnected == false)
        #expect(document.displayName == "host:test.txt")
        
        return (document, url)
    }
    
    
    /// Saves a document and waits for completion.
    ///
    /// - Parameters:
    ///   - document: The document to save.
    ///   - url: The destination URL.
    ///   - operation: The AppKit save operation.
    /// - Throws: The save error returned by the document.
    @MainActor private func save(_ document: Document, to url: URL, operation: NSDocument.SaveOperationType) async throws {
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
            document.save(to: url, ofType: "public.plain-text", for: operation) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    
    /// Closes a document and removes its working copy and backup.
    ///
    /// - Parameters:
    ///   - document: The test document.
    ///   - url: The working copy URL.
    @MainActor private func remove(_ document: Document, url: URL) {
        
        let backup = document.autosavedContentsFileURL
        
        document.close()
        
        if let backup {
            try? FileManager.default.removeItem(at: backup)
        }
        try? RemoteEditingController.fileStore.removeBackingFile(at: url)
    }
}


/// A test connection with manual save completion.
@MainActor private final class TestConnection: RMateFileConnection {
    
    var isConnected = true
    private(set) var data: Data?
    
    private var saveContinuation: CheckedContinuation<Void, any Error>?
    private var continuation: CheckedContinuation<Void, Never>?
    
    
    /// Stores the file content and waits for completion.
    ///
    /// - Parameters:
    ///   - data: The saved bytes.
    ///   - file: The remote file.
    /// - Throws: An error if sending fails.
    func save(_ data: Data, for file: RMateFile) async throws {
        
        self.data = data
        try await withCheckedThrowingContinuation {
            self.saveContinuation = $0
            self.continuation?.resume()
            self.continuation = nil
        }
    }
    
    
    /// Waits until a save is requested.
    func waitForSave() async {
        
        guard self.saveContinuation == nil else { return }
        
        await withCheckedContinuation { self.continuation = $0 }
    }
    
    
    /// Completes the pending save.
    ///
    /// - Parameter succeeded: Whether sending succeeded.
    func finishSave(succeeded: Bool) {
        
        self.isConnected = succeeded
        if succeeded {
            self.saveContinuation?.resume()
        } else {
            self.saveContinuation?.resume(throwing: URLError(.networkConnectionLost))
        }
        self.saveContinuation = nil
    }
    
    
    /// Closes the test connection.
    ///
    /// - Parameter file: The file being closed.
    func close(_ file: RMateFile) {
        
        self.isConnected = false
    }
}


/// A delegate that records the document's close decision.
@MainActor private final class CloseDelegate: NSObject {
    
    private(set) var result: Bool?
    private var continuation: CheckedContinuation<Bool, Never>?
    
    
    /// Receives the document's close decision.
    ///
    /// - Parameters:
    ///   - document: The document being closed.
    ///   - shouldClose: Whether the document can close.
    ///   - contextInfo: The context passed to the close request.
    @objc func document(_ document: NSDocument, shouldClose: Bool, contextInfo: UnsafeMutableRawPointer?) {
        
        self.result = shouldClose
        self.continuation?.resume(returning: shouldClose)
        self.continuation = nil
    }
    
    
    /// Waits for the document's close decision.
    ///
    /// - Returns: Whether the document can close.
    func waitForResult() async -> Bool {
        
        if let result { return result }
        
        return await withCheckedContinuation { self.continuation = $0 }
    }
}
