//
//  NSDocument.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-11-26.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2025 1024jp
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

import AppKit.NSDocument

extension NSDocument {
    
    nonisolated static let didChangeFileURLNotification = Notification.Name("DocumentDidChangeFileURLNotification")
    nonisolated static let didMakeWindowNotification = Notification.Name("DocumentDidMakeWindowNotification")
}


extension NSDocument.SaveOperationType {
    
    /// The save operation is a kind of an autosave.
    var isAutosave: Bool {
        
        switch self {
            case .autosaveElsewhereOperation, .autosaveInPlaceOperation, .autosaveAsOperation:
                true
            case .saveOperation, .saveAsOperation, .saveToOperation:
                false
            @unknown default:
                fatalError()
        }
    }
    
    
    /// The save operation is an autosave but not overwrites the actual document file.
    var isAutosaveElsewhere: Bool {
        
        switch self {
            case .autosaveElsewhereOperation, .autosaveAsOperation:
                true
            case .autosaveInPlaceOperation, .saveOperation, .saveAsOperation, .saveToOperation:
                false
            @unknown default:
                fatalError()
        }
    }
}


extension NSDocument {
    
    /// Invokes the passed-in block with `continueAsynchronousWorkOnMainThread` by marking it as `@MainActor`.
    ///
    /// - Parameter block: The block to be invoked.
    nonisolated final func continueAsynchronousWorkOnMainActor(_ block: @MainActor @escaping () -> Void) {
        
        self.continueAsynchronousWorkOnMainThread {
            MainActor.assumeIsolated(block)
        }
    }
    
    
    /// Reverts the receiver with the current document file without asking to the user in advance.
    ///
    /// - Parameter fileURL: The location from which the document contents are read, or `nil` to revert at the same location.
    /// - Returns: `true` if succeeded.
    @discardableResult final func revert(fileURL: URL? = nil) -> Bool {
        
        guard
            let fileURL = fileURL ?? self.fileURL,
            let fileType = self.fileType
        else { return false }
        
        do {
            try self.revert(toContentsOf: fileURL, ofType: fileType)
        } catch {
            self.presentErrorAsSheet(error)
            return false
        }
        
        return true
    }
}


// MARK: Close

extension NSDocument {
    
    /// Asks the user for the handling unsaved changes and waits for the answer.
    ///
    /// - Returns: Returns `false` when the user cancels the operation, otherwise `true`.
    final func canClose() async -> Bool {
        
        await withCheckedContinuation { continuation in
            self.canClose(withDelegate: self,
                          shouldClose: #selector(self.document(_:shouldClose:contextInfo:)),
                          contextInfo: bridgeWrapped(continuation))
        }
    }
    
    
    @objc private final func document(_ document: NSDocument, shouldClose: Bool, contextInfo: UnsafeRawPointer) {
        
        let continuation: CheckedContinuation<Bool, Never> = bridgeUnwrapped(contextInfo)
        
        continuation.resume(returning: shouldClose)
    }
}


// MARK: Error Handling

extension NSDocument {
    
    typealias RecoveryHandler = ((_ didRecover: Bool) -> Void)
    
    
    /// Presents an error alert as document modal sheet.
    final func presentErrorAsSheet(_ error: some Error, recoveryHandler: RecoveryHandler? = nil) {
        
        guard let window = self.windowForSheet else {
            let didRecover = self.presentError(error)
            recoveryHandler?(didRecover)
            return
        }
        
        // close previous sheet if exists
        window.attachedSheet?.orderOut(self)
        
        if let recoveryHandler {
            self.presentError(error, modalFor: window,
                              delegate: self,
                              didPresent: #selector(didPresentErrorWithRecovery(didRecover:contextInfo:)),
                              contextInfo: bridgeWrapped(recoveryHandler))
        } else {
            self.presentError(error, modalFor: window,
                              delegate: nil, didPresent: nil, contextInfo: nil)
        }
    }
    
    
    // MARK: Private Methods
    
    /// Performs didRecoverBlock after recovering presented error.
    @objc private func didPresentErrorWithRecovery(didRecover: Bool, contextInfo: UnsafeMutableRawPointer) {
        
        let recoveryHandler: RecoveryHandler = bridgeUnwrapped(contextInfo)
        
        recoveryHandler(didRecover)
    }
}
