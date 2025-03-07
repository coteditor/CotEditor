//
//  FilePermissions.swift
//  FilePermissions
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

public struct FilePermissions: Equatable, Sendable {
    
    public var user: Permission
    public var group: Permission
    public var others: Permission
    
    
    public struct Permission: OptionSet, Sendable {
        
        public let rawValue: Int16
        
        public static let read    = Self(rawValue: 0b100)
        public static let write   = Self(rawValue: 0b010)
        public static let execute = Self(rawValue: 0b001)
        
        
        public init(rawValue: Int16) {
            
            self.rawValue = rawValue
        }
        
        
        /// The human-readable permission expression like “rwx”.
        public var symbolic: String {
            
            (self.contains(.read) ? "r" : "-") +
            (self.contains(.write) ? "w" : "-") +
            (self.contains(.execute) ? "x" : "-")
        }
    }
    
    
    public init(mask: Int16) {
        
        self.user   = Permission(rawValue: (mask & 0b111 << 6) >> 6)
        self.group  = Permission(rawValue: (mask & 0b111 << 3) >> 3)
        self.others = Permission(rawValue: (mask & 0b111))
    }
    
    
    /// The `Int16` value.
    public var mask: Int16 {
        
        let userMask = self.user.rawValue << 6
        let groupMask = self.group.rawValue << 3
        let othersMask = self.others.rawValue
        
        return userMask + groupMask + othersMask
    }
    
    
    /// The human-readable permission expression like “rwxr--r--”.
    public var symbolic: String {
        
        self.user.symbolic + self.group.symbolic + self.others.symbolic
    }
    
    
    /// The octal value expression like “644”.
    public var octal: String {
        
        String(self.mask, radix: 8)
    }
}


extension FilePermissions: CustomStringConvertible {
    
    public var description: String {
        
        self.symbolic
    }
}
