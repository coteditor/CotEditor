//
//  NSTextView+URLDetectable.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2020-02-15.
//
//  ---------------------------------------------------------------------------
//
//  © 2020 1024jp
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

import Cocoa

protocol URLDetectable: NSTextView {
    
    var urlDetectionQueue: OperationQueue { get }
}


extension URLDetectable {
    
    /// Invalidate the current detection task and restart if needed.
    func invalidateURLDetection() {
        
        guard self.urlDetectionQueue.operationCount > 0 else { return }
        
        self.urlDetectionQueue.cancelAllOperations()
        self.detectLink()
    }
    
    
    /// Detect URLs in content asynchronously.
    func detectLink() {
        
        guard let textStorage = self.textStorage else { return assertionFailure() }
        guard textStorage.length > 0 else { return }
        
        let operation = URLDetectionOperation(textStorage: textStorage)
        
        self.urlDetectionQueue.cancelAllOperations()
        self.urlDetectionQueue.addOperation(operation)
    }
    
}



final class URLDetectionOperation: AsynchronousOperation {
     
    // MARK: Private Properties
    
    private weak var textStorage: NSTextStorage?
    private let string: String
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    init(textStorage: NSTextStorage) {
        
        self.textStorage = textStorage
        self.string = textStorage.string.immutable
    }
    
    
    
    // MARK: Operation Methods
    
    override func main() {
        
        guard self.textStorage != nil else { return assertionFailure() }
        
        var links: [(url: URL, range: NSRange)] = []
        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        
        detector.enumerateMatches(in: self.string, options: [.reportProgress], range: self.string.range) { (result, flag, stop) in
            if self.isCancelled {
                stop.pointee = true
            }
            guard let result = result, let url = result.url else { return }
            
            links.append((url, result.range))
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return assertionFailure() }
            
            guard
                !self.isCancelled,
                let textStorage = self.textStorage
                else { return self.finish() }
            
            assert(textStorage.string.length == self.string.length, "textStorage was edited after starting URL detection")
            
            textStorage.beginEditing()
            textStorage.removeAttribute(.link, range: textStorage.range)
            for link in links {
                textStorage.addAttribute(.link, value: link.url, range: link.range)
            }
            textStorage.endEditing()
            
            self.finish()
        }
    }
    
}
