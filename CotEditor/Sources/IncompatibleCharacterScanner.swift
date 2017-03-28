/*
 
 IncompatibleCharacterScanner.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-05-28.
 
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

protocol IncompatibleCharacterScannerDelegate: class {
    
    func needsUpdateIncompatibleCharacter(_ document: Document) -> Bool
    
    func document(_ document: Document, didUpdateIncompatibleCharacters incompatibleCharacters: [IncompatibleCharacter])
}



final class IncompatibleCharacterScanner: CustomDebugStringConvertible {
    
    // MARK: Public Properties
    
    weak var delegate: IncompatibleCharacterScannerDelegate?
    
    private(set) weak var document: Document?  // weak to avoid cycle retain
    private(set) var incompatibleCharacters = [IncompatibleCharacter]()  // line endings applied
    
    
    // MARK: Private Properties
    
    private lazy var updateTask: Debouncer = Debouncer(delay: 0.4) { [weak self] in self?.scan() }
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    required init(document: Document) {
        
        self.document = document
    }
    
    
    var debugDescription: String {
        
        return "<\(self): \(self.document?.displayName ?? "NO DOCUMENT")>"
    }
    
    
    
    // MARK: Public Methods
    
    /// set update timer
    func invalidate() {
        
        guard
            let document = self.document,
            self.delegate?.needsUpdateIncompatibleCharacter(document) ?? false else { return }
        
        self.updateTask.schedule()
    }
    
    
    /// scan immediately
    func scan() {
        
        guard let document = self.document else { return }
        
        self.incompatibleCharacters = document.string.scanIncompatibleCharacters(for: document.encoding) ?? []
        self.updateTask.cancel()
        
        self.delegate?.document(document, didUpdateIncompatibleCharacters: self.incompatibleCharacters)
    }
    
}
