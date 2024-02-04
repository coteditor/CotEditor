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

import AppKit
import Combine

final class IncompatibleCharacterScanner {
    
    // MARK: Public Properties
    
    let document: Document
    
    @Published private(set) var incompatibleCharacters: [ValueRange<IncompatibleCharacter>] = []
    @Published private(set) var isScanning = false
    
    
    // MARK: Private Properties
    
    private var task: Task<Void, any Error>?
    private var observers: AnyCancellable?
    
    
    
    // MARK: Lifecycle
    
    init(document: Document) {
        
        self.document = document
        
        self.observe()
    }
    
    
    deinit {
        self.task?.cancel()
    }
    
    
    
    // MARK: Private Methods
    
    /// Observes the document.
    private func observe() {
        
        self.observers = Publishers.Merge3(
            Just(Void()),  // initial scan
            NotificationCenter.default.publisher(for: NSTextStorage.didProcessEditingNotification, object: self.document.textStorage)
                .map { $0.object as! NSTextStorage }
                .filter { $0.editedMask.contains(.editedCharacters) }
                .debounce(for: .seconds(0.3), scheduler: RunLoop.current)
                .eraseToVoid(),
            self.document.$fileEncoding
                .map(\.encoding)
                .debounce(for: .seconds(0.1), scheduler: RunLoop.current)
                .removeDuplicates()
                .eraseToVoid()
        )
        .sink { [weak self] _ in self?.scan() }
    }
    
    
    /// Scans the characters incompatible with the current encoding in the document contents.
    private func scan() {
        
        self.task?.cancel()
        
        let encoding = self.document.fileEncoding.encoding
        
        guard !self.document.textStorage.string.canBeConverted(to: encoding) else {
            self.incompatibleCharacters = []
            return
        }
        
        let document = self.document
        self.isScanning = true
        self.task = Task {
            defer { self.isScanning = false }
            let string = await MainActor.run { document.textStorage.string.immutable }
            self.incompatibleCharacters = try string.charactersIncompatible(with: encoding)
        }
    }
}
