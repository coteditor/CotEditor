//
//  FilePermissions.swift
//  DocumentFile
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-02-16.
//
//  ---------------------------------------------------------------------------
//
//  © 2018-2026 1024jp
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
    
    private var special: SpecialPermission
    
    
    public struct Permission: OptionSet, Sendable {
        
        public var rawValue: Int16
        
        public static let read = Self(rawValue: 0o4)
        public static let write = Self(rawValue: 0o2)
        public static let execute = Self(rawValue: 0o1)
        
        
        public init(rawValue: Int16) {
            
            self.rawValue = rawValue
        }
        
        
        /// The human-readable permission expression like “rwx”.
        public var symbolic: String {
            
            self.symbolic(specialExecute: .none)
        }
        
        
        /// The human-readable permission expression with the special execute bit.
        ///
        /// - Parameters:
        ///   - specialExecute: The special permission bit represented in the execute position.
        /// - Returns: The symbolic permission.
        func symbolic(specialExecute: SpecialExecute) -> String {
            
            (self.contains(.read) ? "r" : "-")
            + (self.contains(.write) ? "w" : "-")
            + specialExecute.symbol(isExecutable: self.contains(.execute))
        }
    }
    
    
    enum SpecialExecute {
        
        case none
        case setID
        case sticky
        
        
        /// Returns the execute-position symbol.
        ///
        /// - Parameter isExecutable: Whether the regular execute bit is set.
        /// - Returns: The symbolic execute-position permission.
        func symbol(isExecutable: Bool) -> String {
            
            switch self {
                case .none: isExecutable ? "x" : "-"
                case .setID: isExecutable ? "s" : "S"
                case .sticky: isExecutable ? "t" : "T"
            }
        }
    }
    
    
    private struct SpecialPermission: OptionSet, Sendable {
        
        var rawValue: Int16
        
        static let setUserID = Self(rawValue: 0o4)
        static let setGroupID = Self(rawValue: 0o2)
        static let sticky = Self(rawValue: 0o1)
    }
    
    
    public init(mask: Int16) {
        
        self.special = SpecialPermission(rawValue: (mask & 0o7000) >> 9)
        self.user = Permission(rawValue: (mask & 0o0700) >> 6)
        self.group = Permission(rawValue: (mask & 0o0070) >> 3)
        self.others = Permission(rawValue: mask & 0o0007)
    }
    
    
    /// The `Int16` value.
    public var mask: Int16 {
        
        let specialMask = self.special.rawValue << 9
        let userMask = self.user.rawValue << 6
        let groupMask = self.group.rawValue << 3
        let othersMask = self.others.rawValue
        
        return specialMask + userMask + groupMask + othersMask
    }
    
    
    /// The human-readable permission expression like “rwxr--r--”.
    public var symbolic: String {
        
        self.user.symbolic(specialExecute: self.special.contains(.setUserID) ? .setID : .none) +
        self.group.symbolic(specialExecute: self.special.contains(.setGroupID) ? .setID : .none) +
        self.others.symbolic(specialExecute: self.special.contains(.sticky) ? .sticky : .none)
    }
    
    
    /// The octal value expression like “644”.
    public var octal: String {
        
        let octal = String(self.mask, radix: 8)
        let minimumLength = self.special.isEmpty ? 3 : 4
        
        return String(repeating: "0", count: max(0, minimumLength - octal.count)) + octal
    }
}


extension FilePermissions: CustomStringConvertible {
    
    public var description: String {
        
        self.symbolic
    }
}
