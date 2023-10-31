//
//  NSRegularExpression+Additions.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-12-06.
//
//  ---------------------------------------------------------------------------
//
//  © 2018-2023 1024jp
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

extension NSRegularExpression {
    
    /// Returns an array of all the matches of the regular expression in the string.
    ///
    /// - Parameters:
    ///   - string: The string to search.
    ///   - options: The matching options to use.
    ///   - range: The range of the string to search.
    /// - Throws: `CancellationError`
    /// - Returns: An array of all the matches.
    final func cancellableMatches(in string: String, options: MatchingOptions = [], range: NSRange) throws -> [NSTextCheckingResult] {
        
        var matches: [NSTextCheckingResult] = []
        self.enumerateMatches(in: string, options: options, range: range) { (match, _, stopPointer) in
            if Task.isCancelled {
                stopPointer.pointee = ObjCBool(true)
                return
            }
            
            if let match {
                matches.append(match)
            }
        }
        
        try Task.checkCancellation()
        
        return matches
    }
}
