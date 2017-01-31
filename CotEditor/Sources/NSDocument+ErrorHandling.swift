/*
 
 NSDocument+ErrorHandling.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-11-26.
 
 ------------------------------------------------------------------------------
 
 © 2016-2017 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 https://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import AppKit

extension NSDocument {
    
    typealias RecoveryHandler = ((Bool) -> Void)
    
    
    /// present an error alert as document modal sheet
    func presentErrorAsSheet(_ error: Error, recoveryHandler: RecoveryHandler? = nil) {
        
        guard let window = self.windowForSheet else {
            let didRecover = self.presentError(error)
            recoveryHandler?(didRecover)
            return
        }
        
        // close previous sheet if exists
        window.attachedSheet?.orderOut(self)
        
        if let recoveryHandler = recoveryHandler {
            let block = UnsafeMutablePointer<RecoveryHandler>.allocate(capacity: 1)
            block.pointee = recoveryHandler
            
            self.presentError(error, modalFor: window,
                              delegate: self,
                              didPresent: #selector(didPresentErrorWithRecovery(didRecover:contextInfo:)),
                              contextInfo: UnsafeMutableRawPointer(mutating: block))
            
        } else {
            self.presentError(error, modalFor: window,
                              delegate: nil, didPresent: nil, contextInfo: nil)
        }
    }
    
    
    
    // MARK: Private Methods
    
    /// perform didRecoverBlock after recovering presented error
    @objc private func didPresentErrorWithRecovery(didRecover: Bool, contextInfo: UnsafeMutableRawPointer?) {
        
        if let recoveryHandler = contextInfo?.assumingMemoryBound(to: RecoveryHandler.self).pointee {
            recoveryHandler(didRecover)
        }
    }
    
}
