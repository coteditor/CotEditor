//
//  IncompatibleCharacterScanner.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-05-28.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2022 1024jp
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

import Combine
import AppKit

final class IncompatibleCharacterScanner {
    
    // MARK: Public Properties
    
    @Published private(set) var incompatibleCharacters: [IncompatibleCharacter] = []  // line endings applied
    @Published private(set) var isScanning = false
    
    var shouldScan = false
    
    
    // MARK: Private Properties
    
    private weak var document: Document?  // weak to avoid cycle retain
    
    private var task: Task<Void, any Error>?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    required init(document: Document) {
        
        self.document = document
    }
    
    
    deinit {
        self.task?.cancel()
    }
    
    
    
    // MARK: Public Methods
    
    /// Scan only when needed.
    func invalidate() {
        
        guard self.shouldScan else { return }
        
        self.task?.cancel()
        
        guard let document = self.document else { return assertionFailure() }
        let encoding = document.fileEncoding.encoding
        
        guard !document.textStorage.string.canBeConverted(to: encoding) else {
            self.incompatibleCharacters = []
            return
        }
        
        self.isScanning = true
        self.task = Task {
            defer { self.isScanning = false }
            try await Task.sleep(nanoseconds: 400 * 1_000_000)  // debounce
            
            let string = document.textStorage.string.immutable
            let incompatibleCharacters = try string.scanIncompatibleCharacters(with: encoding)
            self.incompatibleCharacters = incompatibleCharacters
        }
    }
}
