//
//  FolderFindProgress.swift
//  FolderFind
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-05-29.
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

import Synchronization

public final class FolderFindProgress: Sendable {
    
    // MARK: Private Properties
    
    private let storage: Mutex<FolderFind.Metrics>
    
    
    // MARK: Lifecycle
    
    /// Initializes folder find progress.
    ///
    /// - Parameter findString: The string to search for.
    public init(findString: String) {
        
        self.storage = .init(FolderFind.Metrics(findString: findString))
    }
    
    
    // MARK: Public Methods
    
    /// The current progress snapshot.
    public var snapshot: FolderFind.Metrics {
        
        self.storage.withLock { $0 }
    }
    
    
    // MARK: Internal Methods
    
    /// Updates the current progress snapshot.
    ///
    /// - Parameter snapshot: The new progress snapshot.
    func update(snapshot: FolderFind.Metrics) {
        
        self.storage.withLock { $0 = snapshot }
    }
}


extension FolderFindProgress: Equatable {
    
    public static func == (lhs: FolderFindProgress, rhs: FolderFindProgress) -> Bool {
        
        lhs === rhs
    }
}
