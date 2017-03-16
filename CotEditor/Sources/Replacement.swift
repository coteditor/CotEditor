/*
 
 Replacement.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2017-02-19.
 
 ------------------------------------------------------------------------------
 
 © 2017 1024jp
 
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

import Foundation

struct Replacement {
    
    let findString: String
    let replacementString: String
    let usesRegularExpression: Bool
    let ignoresCase: Bool
    let enabled: Bool
    
    
    init(findString: String, replacementString: String, usesRegularExpression: Bool, ignoresCase: Bool, enabled: Bool = true) {
        
        self.findString = findString
        self.replacementString = replacementString
        self.ignoresCase = ignoresCase
        self.usesRegularExpression = usesRegularExpression
        self.enabled = enabled
    }
    
}



extension Replacement: Equatable {
    
    static func == (lhs: Replacement, rhs: Replacement) -> Bool {
        
        return lhs.findString == rhs.findString &&
            lhs.replacementString == rhs.replacementString &&
            lhs.usesRegularExpression == rhs.usesRegularExpression &&
            lhs.ignoresCase == rhs.ignoresCase &&
            lhs.enabled == rhs.enabled
    }
    
}



// MARK: Validation

extension Replacement {
    
    /// check if replacement definition is valid
    ///
    /// - Throws: TextFindError
    func validate(regexOptions: NSRegularExpression.Options = []) throws {
        
        guard !self.findString.isEmpty else {
            throw TextFindError.emptyFindString
        }
        
        if self.usesRegularExpression {
            do {
                let _ = try NSRegularExpression(pattern: self.findString, options: regexOptions)
            } catch {
                let failureReason: String? = (error as? LocalizedError)?.failureReason
                throw TextFindError.regularExpression(reason: failureReason)
            }
        }
    }
    
}
