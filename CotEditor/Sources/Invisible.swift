/*
 
 Invisible.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-01-03.
 
 ------------------------------------------------------------------------------
 
 © 2014-2016 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Foundation

enum Invisible {
    
    static let spaces = ["·", "°", "ː", "␣"]
    static let tabs = ["¬", "⇥", "‣", "▹"]
    static let newLines = ["¶", "↩", "↵", "⏎"]
    static let fullWidthSpaces = ["□", "⊠", "■", "•"]
    static let verticalTab = "␋"
    static let replacement = "�"
}



// MARK: User Defaults

extension Invisible {
    
    static var userSpace: String {
        
        let index = Defaults[.invisibleSpace]
        return self.spaces[safe: index] ?? self.spaces.first!
    }
    
    
    static var userTab: String {
        
        let index = Defaults[.invisibleTab]
        return self.tabs[safe: index] ?? self.tabs.first!
    }
    
    
    static var userNewLine: String {
        
        let index = Defaults[.invisibleNewLine]
        return self.newLines[safe: index] ?? self.newLines.first!
    }
    
    
    static var userFullWidthSpace: String {
        
        let index = Defaults[.invisibleFullwidthSpace]
        return self.fullWidthSpaces[safe: index] ?? self.fullWidthSpaces.first!
    }
    
}
