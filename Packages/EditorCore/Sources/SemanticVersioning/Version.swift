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
//  © 2024 1024jp
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
    
    public enum Prerelease: String, Sendable {
        
        case alpha
        case beta
        case rc
    }
    
    
    public var major: Int
    public var minor: Int
    public var patch: Int
    public var prerelease: Prerelease?
    
    public var isPrerelease: Bool  { self.prerelease != nil }
    
    
    public init(_ major: Int, _ minor: Int, _ patch: Int, prerelease: Prerelease? = nil) {
        
        self.major = major
        self.minor = minor
        self.patch = patch
        self.prerelease = prerelease
    }
    
    
    public init?(_ string: String) {
        
        guard
            let match = string.wholeMatch(of: /(?<major>[0-9]+)\.(?<minor>[0-9]+)\.(?<patch>[0-9]+)(-(?<prerelease>[a-z]+)(\.[0-9]+)?)?/),
            let major = Int(match.major),
            let minor = Int(match.minor),
            let patch = Int(match.patch)
        else { return nil }
        
        self.major = major
        self.minor = minor
        self.patch = patch
        
        if let prereleaseIdentifier = match.prerelease {
            guard let prerelease = Prerelease(rawValue: String(prereleaseIdentifier)) else { return nil }
            
            self.prerelease = prerelease
        }
    }
}


extension Version: Comparable {
    
    public static func < (lhs: Version, rhs: Version) -> Bool {
        
        if lhs.major != rhs.major {
            lhs.major < rhs.major
        } else if lhs.minor != rhs.minor {
            lhs.minor < rhs.minor
        } else if lhs.patch != rhs.patch {
            lhs.patch < rhs.patch
        } else {
            switch (lhs.prerelease, rhs.prerelease) {
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
        
        switch lhs {
            case .alpha: rhs != .alpha
            case .beta: rhs == .rc
            case .rc: false
        }
    }
}
