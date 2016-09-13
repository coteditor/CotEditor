/*
 
 IncompatibleCharacterScanner.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-05-28.
 
 ------------------------------------------------------------------------------
 
 © 2016 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import AppKit

protocol IncompatibleCharacterScannerDelegate: class {
    
    func needsUpdateIncompatibleCharacter(_ document: Document) -> Bool
    
    func document(_ document: Document, didUpdateIncompatibleCharacters incompatibleCharacers: [IncompatibleCharacter])
}



final class IncompatibleCharacterScanner: CustomDebugStringConvertible {
    
    // MARK: Public Properties
    
    weak var delegate: IncompatibleCharacterScannerDelegate?
    
    private(set) weak var document: Document?  // weak to avoid cycle retain
    private(set) var incompatibleCharacers = [IncompatibleCharacter]()  // line endings applied
    
    
    // MARK: Private Properties
    
    static let UpdateInterval: TimeInterval = 0.42
    
    private weak var updateTimer: Timer?
    private var needsUpdate = true
    
    
    
    // MARK:
    // MARK: Lifecycle
    
    required init(document: Document) {
        
        self.document = document
    }
    
    
    deinit {
        self.updateTimer?.invalidate()
    }
    
    
    var debugDescription: String {
        
        return "<\(self): \(self.document?.displayName)>"
    }
    
    
    
    // MARK: Public Methods
    
    /// set update timer
    func invalidate() {
        
        self.needsUpdate = true
        
        guard
            let document = self.document,
            self.delegate?.needsUpdateIncompatibleCharacter(document) ?? false else { return }
        
        let interval = type(of: self).UpdateInterval
        
        if let timer = self.updateTimer, timer.isValid {
            timer.fireDate = Date(timeIntervalSinceNow: interval)
        } else {
            self.updateTimer = Timer.scheduledTimer(timeInterval: interval,
                                                    target: self,
                                                    selector: #selector(scan(timer:)),
                                                    userInfo: nil,
                                                    repeats: false)
        }
    }
    
    
    /// scan immediately
    func scan() {
        
        self.updateTimer?.invalidate()
        
        guard let document = self.document else { return }
        
        self.incompatibleCharacers = document.string.scanIncompatibleCharacters(for: document.encoding) ?? []
        self.needsUpdate = false
        
        self.delegate?.document(document, didUpdateIncompatibleCharacters: self.incompatibleCharacers)
    }
    
    
    
    // MARK: Private Methods
    
    /// update incompatible chars afer interval
    @objc func scan(timer: Timer) {
        
        self.updateTimer?.invalidate()
        self.scan()
    }
    
}
