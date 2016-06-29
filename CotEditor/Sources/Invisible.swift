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

@objc enum InvisibleType: Int {
    
    case space
    case tab
    case newLine
    case fullWidthSpace
    case verticalTab
    case replacement
}


class Invisible: NSObject {
    
    static let spaces = ["·", "°", "ː", "␣"]
    static let tabs = ["¬", "⇥", "‣", "▹"]
    static let newLines = ["¶", "↩", "↵", "⏎"]
    static let fullWidthSpaces = ["□", "⊠", "■", "•"]
    static let verticalTab = "␋"
    static let replacement = "�"
    
    
    /// returns substitute character as String
    class func space(index: Int) -> String {
        
        return self.spaces[index] ?? self.spaces.first!
    }
    
    class func tab(index: Int) -> String {
        
        return self.tabs[index] ?? self.tabs.first!
    }
    
    class func newLine(index: Int) -> String {
        
        return self.newLines[index] ?? self.newLines.first!
    }
    
    class func fullWidthSpace(index: Int) -> String {
        
        return self.fullWidthSpaces[index] ?? self.fullWidthSpaces.first!
    }
    
}
