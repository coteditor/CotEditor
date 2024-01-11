//
//  NSDocument+ErrorHandling.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-11-26.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2024 1024jp
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
            case  .autosaveInPlaceOperation, .saveOperation, .saveAsOperation, .saveToOperation:
                false
            @unknown default:
                fatalError()
        }
    }
}



extension NSDocument {
    
    typealias RecoveryHandler = ((_ didRecover: Bool) -> Void)
    
    
    /// Presents an error alert as document modal sheet.
    @MainActor final func presentErrorAsSheet(_ error: some Error, recoveryHandler: RecoveryHandler? = nil) {
        
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
