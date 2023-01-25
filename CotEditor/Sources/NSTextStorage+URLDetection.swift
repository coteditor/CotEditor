//
//  NSTextStorage+URLDetection.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2020-02-15.
//
//  ---------------------------------------------------------------------------
//
//  © 2020-2023 1024jp
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

import AppKit.NSTextStorage

extension NSTextStorage {
    
    /// Detect URLs in the string and link them.
    ///
    /// - Throws: `CancellationError`
    func linkURLs() throws {
        
        guard self.length > 0 else { return }
        
        let string = self.string.immutable
        
        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let links: [ValueRange<URL>] = try detector.cancellableMatches(in: string, range: string.range)
            .compactMap { (result) in
                guard let url = result.url else { return nil }
                return ValueRange(value: url, range: result.range)
            }
        
        Task { @MainActor in
            assert(self.string.length == string.length, "textStorage was edited after starting URL detection")
            
            guard !links.isEmpty || self.hasAttribute(.link) else { return }
            
            self.beginEditing()
            self.removeAttribute(.link, range: self.range)
            for link in links {
                self.addAttribute(.link, value: link.value, range: link.range)
            }
            self.endEditing()
        }
    }
}
