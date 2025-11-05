//
//  Version.swift
//  SemanticVersioning
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-10-02.
//
//  ---------------------------------------------------------------------------
//
//  © 2024-2025 1024jp
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

public struct Version: Sendable {
    
    public enum Prerelease: Sendable {
        
        case alpha(Int?)
        case beta(Int?)
        case rc(Int?)
        case other(String)
        
        static let alpha = Self.alpha(nil)
        static let beta = Self.beta(nil)
        static let rc = Self.rc(nil)
    }
    
    
    public var major: Int
    public var minor: Int
    public var patch: Int
    public var prereleaseIdentifier: String?
    
    public var isPrerelease: Bool  { self.prereleaseIdentifier != nil }
    
    
    public init(_ major: Int, _ minor: Int, _ patch: Int, prereleaseIdentifier: String? = nil) {
        
        self.major = major
        self.minor = minor
        self.patch = patch
        self.prereleaseIdentifier = prereleaseIdentifier
    }
    
    
    public init(_ major: Int, _ minor: Int, _ patch: Int, prerelease: Prerelease?) {
        
        self.major = major
        self.minor = minor
        self.patch = patch
        self.prereleaseIdentifier = prerelease?.rawValue
    }
    
    
    public init?(_ string: String) {
        
        guard
            let match = string.wholeMatch(of: /(?<major>[0-9]+)\.(?<minor>[0-9]+)\.(?<patch>[0-9]+)(-(?<prerelease>[a-z.0-9]+))?/),
            let major = Int(match.major),
            let minor = Int(match.minor),
            let patch = Int(match.patch)
        else { return nil }
        
        self.major = major
        self.minor = minor
        self.patch = patch
        self.prereleaseIdentifier = match.prerelease.map(String.init)
    }
}


extension Version.Prerelease {
    
    init(rawValue: String) {
        
        if let match = rawValue.wholeMatch(of: /(?<token>[a-z]+)(\.(?<number>[0-9]+))?/) {
            let number = match.number.map(String.init).flatMap(Int.init)
            
            self = switch match.token {
                case "alpha": .alpha(number)
                case "beta": .beta(number)
                case "rc": .rc(number)
                default: .other(rawValue)
            }
        } else {
            self = .other(rawValue)
        }
    }
    
    
    var rawValue: String {
        
        switch self {
            case .alpha(let number):
                if let number { "alpha.\(number)" } else { "alpha" }
            case .beta(let number):
                if let number { "beta.\(number)" } else { "beta" }
            case .rc(let number):
                if let number { "rc.\(number)" } else { "rc" }
            case .other(let string):
                string
        }
    }
}


// MARK: Comparable

extension Version: Comparable {
    
    public static func < (lhs: Version, rhs: Version) -> Bool {
        
        if lhs.major != rhs.major {
            lhs.major < rhs.major
        } else if lhs.minor != rhs.minor {
            lhs.minor < rhs.minor
        } else if lhs.patch != rhs.patch {
            lhs.patch < rhs.patch
        } else {
            switch (lhs.prereleaseIdentifier, rhs.prereleaseIdentifier) {
                case (.none, .none): false
                case (.some, .none): true
                case (.none, .some): false
                case (.some(let lPrerelease), .some(let rPrerelease)): lPrerelease < rPrerelease
            }
        }
    }
}


extension Version.Prerelease: Comparable {
    
    public static func < (lhs: Self, rhs: Self) -> Bool {
        
        lhs.rawValue < rhs.rawValue
    }
}
