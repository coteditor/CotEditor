//
//  SuspendedFilePresenter.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-10-17.
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

import Foundation
import Synchronization

/// A presenter that suspends coordinated access until the test allows it to proceed.
final class SuspendedFilePresenter: NSObject, NSFilePresenter {
    
    let presentedItemURL: URL?
    let presentedItemOperationQueue = OperationQueue()
    private let state = Mutex<(accessor: (@Sendable ((@Sendable () -> Void)?) -> Void)?, resumed: Bool)>((nil, false))
    
    /// Whether coordinated access is currently suspended.
    var isWaiting: Bool {
        
        self.state.withLock { $0.accessor != nil }
    }
    
    
    /// Creates a presenter for the file being accessed.
    ///
    /// - Parameter fileURL: The file URL to coordinate.
    init(fileURL: URL) {
        
        self.presentedItemURL = fileURL
        super.init()
    }
    
    
    /// Holds a coordinated reader until the test resumes it.
    ///
    /// - Parameter reader: The accessor to invoke when the item can be read.
    func relinquishPresentedItem(toReader reader: @escaping @Sendable ((@Sendable () -> Void)?) -> Void) {
        
        self.suspend(reader)
    }
    
    
    /// Holds a coordinated writer until the test resumes it.
    ///
    /// - Parameter writer: The accessor to invoke when the item can be written.
    func relinquishPresentedItem(toWriter writer: @escaping @Sendable ((@Sendable () -> Void)?) -> Void) {
        
        self.suspend(writer)
    }
    
    
    /// Allows the suspended accessor and all subsequent accessors to proceed.
    func resume() {
        
        let accessor = self.state.withLock {
            let accessor = $0.accessor
            $0.accessor = nil
            $0.resumed = true
            return accessor
        }
        accessor?(nil)
    }
    
    
    /// Suspends access unless the presenter has already resumed.
    ///
    /// - Parameter accessor: The accessor to invoke when access can proceed.
    private func suspend(_ accessor: @escaping @Sendable ((@Sendable () -> Void)?) -> Void) {
        
        let resumed = self.state.withLock {
            guard !$0.resumed else { return true }
            $0.accessor = accessor
            return false
        }
        if resumed { accessor(nil) }
    }
}
