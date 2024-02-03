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
//  © 2018-2024 1024jp
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

struct FilePermissions: Equatable {
    
    var user: Permission
    var group: Permission
    var others: Permission
    
    
    struct Permission: OptionSet {
        
        let rawValue: Int16
        
        static let read    = Self(rawValue: 0b100)
        static let write   = Self(rawValue: 0b010)
        static let execute = Self(rawValue: 0b001)
        
        
        var symbolic: String {
            
            (self.contains(.read) ? "r" : "-") +
            (self.contains(.write) ? "w" : "-") +
            (self.contains(.execute) ? "x" : "-")
        }
    }
    
    
    init(mask: Int16) {
        
        self.user   = Permission(rawValue: (mask & 0b111 << 6) >> 6)
        self.group  = Permission(rawValue: (mask & 0b111 << 3) >> 3)
        self.others = Permission(rawValue: (mask & 0b111))
    }
    
    
    /// The `Int16` value.
    var mask: Int16 {
        
        let userMask = self.user.rawValue << 6
        let groupMask = self.group.rawValue << 3
        let othersMask = self.others.rawValue
        
        return userMask + groupMask + othersMask
    }
    
    
    /// The human-readable permission expression like “rwxr--r--”.
    var symbolic: String {
        
        self.user.symbolic + self.group.symbolic + self.others.symbolic
    }
    
    
    /// The octal value expression like “644”.
    var octal: String {
        
        String(self.mask, radix: 8)
    }
}



extension FilePermissions: CustomStringConvertible {
    
    var description: String {
        
        self.symbolic
    }
}
