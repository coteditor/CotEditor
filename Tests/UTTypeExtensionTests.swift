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
//  © 2022 1024jp
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

import XCTest
import UniformTypeIdentifiers
@testable import CotEditor

final class UTTypeExtensionTests: XCTestCase {
    
    func testFilenameExtensions() {
        
        XCTAssertEqual(UTType.yaml.filenameExtensions, ["yml", "yaml"])
        XCTAssertEqual(UTType.svg.filenameExtensions, ["svg", "svgz"])
    }
    
    
    func testURLConformance() {
        
        let xmlURL = URL(fileURLWithPath: "foo.xml")
        XCTAssertFalse(xmlURL.conforms(to: .svg))
        XCTAssertTrue(xmlURL.conforms(to: .xml))
        XCTAssertFalse(xmlURL.conforms(to: .plainText))
        
        let svgzURL = URL(fileURLWithPath: "FOO.SVGZ")
        XCTAssertTrue(svgzURL.conforms(to: .svg))
    }
}
