/*
 
 OutlineItem.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-05-12.
 
 ------------------------------------------------------------------------------
 
 © 2016-2018 1024jp
 
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

struct OutlineItem: Equatable {
    
    struct Style: OptionSet {
        
        let rawValue: Int
        
        static let bold      = Style(rawValue: 1 << 0)
        static let italic    = Style(rawValue: 1 << 1)
        static let underline = Style(rawValue: 1 << 2)
    }
    

    let title: String
    let range: NSRange
    let style: Style
    
    
    init(title: String, range: NSRange, style: Style = []) {
        
        self.title = title
        self.range = range
        self.style = style
    }
  
    
    static func == (lhs: OutlineItem, rhs: OutlineItem) -> Bool {
        
        return lhs.range == rhs.range &&
            lhs.style == rhs.style &&
            lhs.title == rhs.title
    }
    
}
