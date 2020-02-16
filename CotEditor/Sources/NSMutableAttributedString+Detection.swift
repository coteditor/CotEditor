//
//  NSMutableAttributedString+Detection.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2019-05-21.
//
//  ---------------------------------------------------------------------------
//
//  © 2019-2020 1024jp
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

extension NSMutableAttributedString {
    
    /// Detect and tag URLs in the receiver.
    func detectLink(in range: NSRange? = nil) {
        
        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let range = range.flatMap { (self.string as NSString).lineRange(for: $0) } ?? self.range
        let matches = detector.matches(in: self.string, range: range)
        
        guard !matches.isEmpty else { return }
        
        self.beginEditing()
        
        self.removeAttribute(.link, range: range)
        for match in matches {
            guard let url = match.url else { continue }
            
            self.addAttribute(.link, value: url, range: match.range)
        }
        
        self.endEditing()
    }
    
}
