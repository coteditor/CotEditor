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
        
        let index = UserDefaults.standard.integer(forKey: DefaultKey.invisibleSpace)
        return self.spaces[index] ?? self.spaces.first!
    }
    
    
    static var userTab: String {
        
        let index = UserDefaults.standard.integer(forKey: DefaultKey.invisibleTab)
        return self.tabs[index] ?? self.tabs.first!
    }
    
    
    static var userNewLine: String {
        
        let index = UserDefaults.standard.integer(forKey: DefaultKey.invisibleNewLine)
        return self.newLines[index] ?? self.newLines.first!
    }
    
    
    static var userFullWidthSpace: String {
        
        let index = UserDefaults.standard.integer(forKey: DefaultKey.invisibleFullwidthSpace)
        return self.fullWidthSpaces[index] ?? self.fullWidthSpaces.first!
    }
    
}
