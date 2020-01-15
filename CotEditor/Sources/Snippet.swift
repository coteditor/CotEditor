//
//  Snippet.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2017-02-27.
//
//  ---------------------------------------------------------------------------
//
//  © 2017-2020 1024jp
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

struct Snippet {
    
    enum Variable: String, TokenRepresentable {
        
        static let prefix = "<<<"
        static let suffix = ">>>"
        
        case cursor = "CURSOR"
        
        
        var description: String {
            
            switch self {
            case .cursor:
                return "The cursor position after inserting the snippet."
            }
        }
        
    }
    
    
    let string: String
    let selection: NSRange?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    init(_ string: String) {
        
        // cursor position
        if let range = string.range(of: Variable.cursor.token) {
            let location = range.lowerBound.utf16Offset(in: string)
            
            self.string = string.replacingCharacters(in: range, with: "")
            self.selection = NSRange(location: location, length: 0)
        } else {
            self.string = string
            self.selection = nil
        }
    }
}
