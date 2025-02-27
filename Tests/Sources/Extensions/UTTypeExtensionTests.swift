//
//  UTTypeExtensionTests.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2022-03-15.
//
//  ---------------------------------------------------------------------------
//
//  © 2022-2025 1024jp
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

import UniformTypeIdentifiers
import Testing
@testable import CotEditor

struct UTTypeExtensionTests {
    
    @Test func filenameExtensions() {
        
        #expect(UTType.yaml.filenameExtensions == ["yml", "yaml"])
        #expect(UTType.svg.filenameExtensions == ["svg", "svgz"])
        #expect(UTType.mpeg2TransportStream.filenameExtensions == ["ts"])
        #expect(UTType.propertyList.filenameExtensions == ["plist"])
    }
    
    
    @Test func conformURL() {
        
        let xmlURL = URL(filePath: "foo.xml")
        #expect(!xmlURL.conforms(to: .svg))
        #expect(xmlURL.conforms(to: .xml))
        #expect(!xmlURL.conforms(to: .plainText))
        
        let svgzURL = URL(filePath: "FOO.SVGZ")
        #expect(svgzURL.conforms(to: .svg))
    }
    
    
    @Test func svg() throws {
        
        #expect(UTType.svg.conforms(to: .text))
        #expect(UTType.svg.conforms(to: .image))
        
        let svgz = try #require(UTType(filenameExtension: "svgz"))
        #expect(svgz == .svg)
        #expect(!svgz.conforms(to: .gzip))
    }
    
    
    @Test func plist() {
        
        #expect(UTType.propertyList.conforms(to: .data))
        #expect(!UTType.propertyList.conforms(to: .image))
    }
    
    
    @Test func isPlainText() throws {
        
        #expect(UTType.propertyList.isPlainText)
        #expect(UTType.svg.isPlainText)
        
        let ts = try #require(UTType(filenameExtension: "ts"))
        #expect(ts.isPlainText)
    }
}
