//
//  Syntax+Sanitization.swift
//  Syntax
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-02-13.
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

extension Syntax {
    
    /// Sorted and removed empty items for serialization.
    public var sanitized: Self {
        
        var syntax = self
        
        syntax.fileMap.sanitize()
        syntax.commentDelimiters.sanitize()
        syntax.indentation.sanitize()
        
        for type in SyntaxType.allCases {
            syntax.highlights[type]?.removeAll(where: \.isEmpty)
            syntax.highlights[type]?.caseInsensitiveSort(\.begin)
            if syntax.highlights[type]?.isEmpty == true {
                syntax.highlights[type] = nil
            }
        }
        
        syntax.outlines.removeAll(where: \.isEmpty)
        syntax.outlines.caseInsensitiveSort(\.pattern)
        
        syntax.completions.removeAll(where: \.text.isEmpty)
        syntax.completions.caseInsensitiveSort(\.text)
        
        return syntax
    }
}


extension Syntax.Comment {
    
    /// Removes empty items for serialization.
    mutating func sanitize() {
        
        self.inlines.removeAll(where: \.begin.isEmpty)
        self.blocks.removeAll(where: \.begin.isEmpty)
        self.blocks.removeAll(where: \.end.isEmpty)
    }
}


extension Syntax.Indentation {
    
    mutating func sanitize() {
        
        for index in self.blockDelimiters.indices {
            if self.blockDelimiters[index].end?.isEmpty == true {
                self.blockDelimiters[index].end = nil
            }
        }
        self.blockDelimiters.removeAll(where: \.begin.isEmpty)
    }
}


extension Syntax.FileMap {
    
    /// Removes empty items for serialization.
    mutating func sanitize() {
        
        self.extensions?.removeAll(where: \.isEmpty)
        if self.extensions?.isEmpty == true {
            self.extensions = nil
        }
        self.filenames?.removeAll(where: \.isEmpty)
        if self.filenames?.isEmpty == true {
            self.filenames = nil
        }
        self.interpreters?.removeAll(where: \.isEmpty)
        if self.interpreters?.isEmpty == true {
            self.interpreters = nil
        }
    }
}


// MARK: -

private extension MutableCollection where Self: RandomAccessCollection {
    
    /// Sorts the collection in place, using the string value that the given key path refers as the comparison between elements.
    ///
    /// - Parameters:
    ///   - keyPath: The key path to the string to compare.
    mutating func caseInsensitiveSort(_ keyPath: KeyPath<Element, String>) {
        
        self.sort { $0[keyPath: keyPath].caseInsensitiveCompare($1[keyPath: keyPath]) == .orderedAscending }
    }
}
