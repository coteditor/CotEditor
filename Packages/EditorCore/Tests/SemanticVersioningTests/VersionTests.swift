//
//  VersionTests.swift
//  SemanticVersioningTests
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

import Testing
import Foundation
@testable import SemanticVersioning

struct VersionTests {
    
    @Test func version() {
        
        #expect(Version("5.0.1") == Version(5, 0, 1))
        
        #expect(Version("5.0.1-beta") == Version(5, 0, 1, prereleaseIdentifier: "beta"))
        #expect(Version("5.0.1-beta.1") == Version(5, 0, 1, prereleaseIdentifier: "beta.1"))
        #expect(Version("5.0.1-abc") == Version(5, 0, 1, prereleaseIdentifier: "abc"))
        #expect(Version("5.0.1-beta") == Version(5, 0, 1, prerelease: .beta))
        #expect(Version("5.0.1-beta.1") != Version(5, 0, 1, prerelease: .beta))
        #expect(Version("5.0.1-alpha") == Version(5, 0, 1, prerelease: .alpha))
        #expect(Version("5.0.1-rc") == Version(5, 0, 1, prerelease: .rc))
        #expect(Version(5, 0, 1, prerelease: .beta) == Version(5, 0, 1, prereleaseIdentifier: "beta"))
    }
    
    
    @Test func comparison() {
        
        #expect(Version(5, 0, 1) == Version(5, 0, 1))
        #expect((Version(5, 0, 1) < Version(5, 0, 1)) == false)
        #expect((Version(5, 0, 1) > Version(5, 0, 1)) == false)
        
        #expect(Version(5, 0, 1) < Version(6, 0, 1))
        #expect(Version(5, 0, 1) < Version(5, 1, 1))
        #expect(Version(5, 0, 1) < Version(5, 0, 2))
        
        #expect(Version(5, 0, 1, prereleaseIdentifier: "beta.1") < Version(5, 0, 1))
        #expect(Version(5, 0, 1, prereleaseIdentifier: "beta") < Version(5, 0, 1, prereleaseIdentifier: "beta.1"))
        #expect(Version(5, 0, 1, prereleaseIdentifier: "beta.1") < Version(5, 0, 1, prereleaseIdentifier: "beta.2"))
        #expect(Version(5, 0, 1, prereleaseIdentifier: "beta.1") < Version(5, 0, 1, prereleaseIdentifier: "rc"))
        
        #expect(Version(5, 0, 1, prerelease: .beta) < Version(5, 0, 1))
        #expect(Version(5, 0, 1, prerelease: .alpha) < Version(5, 0, 1, prerelease: .beta))
        #expect(Version(5, 0, 1, prerelease: .alpha) < Version(5, 0, 1, prerelease: .beta))
    }
    
    
    @Test func prerelease() {
        
        #expect(Version.Prerelease.alpha == .alpha)
        #expect(Version.Prerelease.alpha < .beta)
        #expect(Version.Prerelease.alpha < .rc)
        
        #expect(Version.Prerelease.beta > .alpha)
        #expect(Version.Prerelease.beta == .beta)
        #expect(Version.Prerelease.beta < .rc)
        
        #expect(Version.Prerelease.rc > .alpha)
        #expect(Version.Prerelease.rc > .beta)
        #expect(Version.Prerelease.rc == .rc)
        
        #expect(Version.Prerelease.beta < .beta(1))
        #expect(Version.Prerelease.beta(1) < .beta(2))
        
        #expect(Version.Prerelease.beta(2).rawValue == "beta.2")
        #expect(Version.Prerelease.other("dogcow").rawValue == "dogcow")
    }
    
    
    @Test(arguments: ["6.1.0", "6.1.0-rc", "6.1.0-rc.1", "6.1.0-dogcow"])
    func encode(rawValue: String) throws {
        
        let version = Version(rawValue)
        
        let data = try JSONEncoder().encode(version)
        let decoded = try JSONDecoder().decode(Version.self, from: data)
        
        #expect(version == decoded)
    }
}
