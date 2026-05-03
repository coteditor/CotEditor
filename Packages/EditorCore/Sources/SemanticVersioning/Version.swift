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
//  © 2024-2026 1024jp
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
            let match = string.wholeMatch(of: /(?<major>0|[1-9][0-9]*)\.(?<minor>0|[1-9][0-9]*)\.(?<patch>0|[1-9][0-9]*)(-(?<prerelease>.+))?/),
            let major = Int(match.major),
            let minor = Int(match.minor),
            let patch = Int(match.patch)
        else { return nil }
        
        let prerelease = match.prerelease.map(String.init)
        
        if let prerelease, prerelease.prereleaseIdentifiers == nil {
            return nil
        }
        
        self.major = major
        self.minor = minor
        self.patch = patch
        self.prereleaseIdentifier = prerelease
    }
}


extension Version.Prerelease {
    
    init(rawValue: String) {
        
        if let match = rawValue.wholeMatch(of: /(?<token>[a-z]+)(\.(?<number>[0-9]+))?/) {
            let rawNumber = match.number.map(String.init)
            
            if let rawNumber, rawNumber.count > 1, rawNumber.first == "0" {
                self = .other(rawValue)
                return
            }
            
            let number = rawNumber.flatMap(Int.init)
            
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
                case (.some(let lPrerelease), .some(let rPrerelease)):
                    Self.comparePrerelease(lPrerelease, rPrerelease)
            }
        }
    }
}


extension Version.Prerelease: Comparable {
    
    public static func < (lhs: Self, rhs: Self) -> Bool {
        
        Version.comparePrerelease(lhs.rawValue, rhs.rawValue)
    }
}


private extension Version {
    
    /// Compares two prerelease identifiers.
    ///
    /// - Parameters:
    ///   - lhs: The left prerelease identifier.
    ///   - rhs: The right prerelease identifier.
    /// - Returns: Whether `lhs` has lower precedence than `rhs`.
    static func comparePrerelease(_ lhs: String, _ rhs: String) -> Bool {
        
        guard
            let lhsIdentifiers = lhs.prereleaseIdentifiers,
            let rhsIdentifiers = rhs.prereleaseIdentifiers
        else { return lhs < rhs }
        
        for (lhsIdentifier, rhsIdentifier) in zip(lhsIdentifiers, rhsIdentifiers) where lhsIdentifier != rhsIdentifier {
            return lhsIdentifier.precedesPrereleaseIdentifier(rhsIdentifier)
        }
        
        return lhsIdentifiers.count < rhsIdentifiers.count
    }
}


private extension String {
    
    /// The SemVer prerelease identifiers.
    var prereleaseIdentifiers: [Substring]? {
        
        let identifiers = self.split(separator: ".", omittingEmptySubsequences: false)
        
        guard
            !identifiers.isEmpty,
            identifiers.allSatisfy(\.isPrereleaseIdentifier)
        else { return nil }
        
        return identifiers
    }
}


private extension Substring {
    
    /// Whether the string is a SemVer prerelease identifier.
    var isPrereleaseIdentifier: Bool {
        
        guard !self.isEmpty else { return false }
        
        var isNumeric = true
        for scalar in self.unicodeScalars {
            switch scalar {
                case "0"..."9":
                    break
                case "-", "A"..."Z", "a"..."z":
                    isNumeric = false
                default:
                    return false
            }
        }
        
        return !(isNumeric && self.count > 1 && self.first == "0")
    }
    
    
    /// The numeric value of the SemVer prerelease identifier.
    var numericPrereleaseIdentifier: Int? {
        
        guard self.unicodeScalars.allSatisfy({ "0"..."9" ~= $0 }) else { return nil }
        
        return Int(self)
    }
    
    
    /// Returns whether the receiver has lower precedence than another prerelease identifier.
    ///
    /// - Parameter other: The other prerelease identifier.
    /// - Returns: Whether the receiver has lower precedence than `other`.
    func precedesPrereleaseIdentifier(_ other: Self) -> Bool {
        
        switch (self.numericPrereleaseIdentifier, other.numericPrereleaseIdentifier) {
            case (.some(let lhs), .some(let rhs)):
                lhs < rhs
            case (.some, .none):
                true
            case (.none, .some):
                false
            case (.none, .none):
                self.unicodeScalars.lexicographicallyPrecedes(other.unicodeScalars)
        }
    }
}
