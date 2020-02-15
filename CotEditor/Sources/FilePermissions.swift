//
//  FilePermissions.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-02-16.
//
//  ---------------------------------------------------------------------------
//
//  © 2018 1024jp
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

struct FilePermissions {
    
    var user: Permission
    var group: Permission
    var others: Permission
    
    
    struct Permission: OptionSet {
        
        let rawValue: UInt16
        
        static let read    = Permission(rawValue: 0b100)
        static let write   = Permission(rawValue: 0b010)
        static let execute = Permission(rawValue: 0b001)
        
        
        var humanReadable: String {
            
            return (self.contains(.read) ? "r" : "-") +
                   (self.contains(.write) ? "w" : "-") +
                   (self.contains(.execute) ? "x" : "-")
        }
    }
    
    
    init(mask: UInt16) {
        
        self.user   = Permission(rawValue: (mask & 0b111 << 6) >> 6)
        self.group  = Permission(rawValue: (mask & 0b111 << 3) >> 3)
        self.others = Permission(rawValue: (mask & 0b111))
    }
    
    
    var mask: UInt16 {
        
        let userMask = self.user.rawValue << 6
        let groupMask = self.group.rawValue << 3
        let othersMask = self.others.rawValue
        
        return userMask + groupMask + othersMask
    }
    
    
    /// human-readable permission expression like "rwxr--r--"
    var humanReadable: String {
        
        return self.user.humanReadable + self.group.humanReadable + self.others.humanReadable
    }
    
}



extension FilePermissions: CustomStringConvertible {
    
    var description: String {
        
        return self.humanReadable
    }
    
}
