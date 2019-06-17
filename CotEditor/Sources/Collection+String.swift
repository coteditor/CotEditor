//
//  Collection+String.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2017-03-19.
//
//  ---------------------------------------------------------------------------
//
//  © 2017-2019 1024jp
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

extension Collection where Element == String {
    
    /// Create a name adding a number suffix not to be contained in the receiver.
    ///
    /// - Parameters:
    ///   - proposedName: The name candidate.
    ///   - suffix: The suffix string being appended before the number.
    /// - Returns: The created name.
    func createAvailableName(for proposedName: String, suffix: String? = nil) -> String {
        
        let spaceSuffix = suffix.flatMap { " " + $0 } ?? ""
        
        let (rootName, baseCount): (String, Int?) = {
            let regex = try! NSRegularExpression(pattern: spaceSuffix + "( ([0-9]+))?$")
            
            guard let result = regex.firstMatch(in: proposedName, range: proposedName.nsRange) else { return (proposedName, nil) }
            
            let root = (proposedName as NSString).substring(to: result.range.location)
            
            let numberRange = result.range(at: 2)
            
            guard numberRange.location != NSNotFound else { return (root, nil) }
            
            let number = Int((proposedName as NSString).substring(with: numberRange))
            
            return (root, number)
        }()
        
        let baseName = rootName + spaceSuffix
        
        guard baseCount != nil || self.contains(baseName) else { return baseName }
        
        return sequence(first: baseCount ?? 2) { $0 + 1 }.lazy
            .map { (count: Int) -> String in baseName + " " + String(count) }
            .first { !self.contains($0) }!
    }
    
}
