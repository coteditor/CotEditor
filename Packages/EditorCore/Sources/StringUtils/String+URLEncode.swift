//
//  String+URLEncode.swift
//  StringUtils
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-07-12.
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

public extension String {
    
    /// The URL-percent-encoded representation without double-encoding well-formed percent sequences.
    var urlPercentEncoded: String {
        
        var result = ""
        var index = self.startIndex
        for match in self.matches(of: /(?:%[0-9A-Fa-f]{2})+/) {
            // encode the raw text preceding the percent-encoded run
            result += String(self[index..<match.range.lowerBound]).addingURLEncoding
            
            // decode the run first to avoid double-encoding, or keep it as-is if undecodable
            let run = String(self[match.range])
            result += run.removingPercentEncoding.map(\.addingURLEncoding) ?? run
            index = match.range.upperBound
        }
        result += String(self[index...]).addingURLEncoding
        
        return result
    }
    
    
    /// The string made by percent-encoding all but the URL-unreserved characters.
    private var addingURLEncoding: String {
        
        self.addingPercentEncoding(withAllowedCharacters: .alphanumerics.union(.init(charactersIn: "-._~"))) ?? self
    }
}
