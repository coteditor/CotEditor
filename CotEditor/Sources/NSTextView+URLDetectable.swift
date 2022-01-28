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
//  © 2020-2022 1024jp
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
    
    var urlDetectionTask: Task<Void, Error>? { get set }
}


extension URLDetectable {
    
    /// Detect URLs in content asynchronously.
    @MainActor func detectLink() {
        
        guard let textStorage = self.textStorage else { return assertionFailure() }
        guard textStorage.length > 0 else { return }
        
        let string = textStorage.string.immutable
        
        self.urlDetectionTask?.cancel()
        self.urlDetectionTask = Task.detached(priority: .userInitiated) {
            var links: [(url: URL, range: NSRange)] = []
            let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
            
            detector.enumerateMatches(in: string, options: [.reportProgress], range: string.range) { (result, _, stop) in
                if Task.isCancelled {
                    stop.pointee = true
                }
                guard let result = result, let url = result.url else { return }
                
                links.append((url, result.range))
            }
            try Task.checkCancellation()
            
            Task { @MainActor [links] in
                assert(textStorage.string.length == string.length, "textStorage was edited after starting URL detection")
                
                textStorage.beginEditing()
                textStorage.removeAttribute(.link, range: textStorage.range)
                for link in links {
                    textStorage.addAttribute(.link, value: link.url, range: link.range)
                }
                textStorage.endEditing()
            }
        }
    }
    
}
