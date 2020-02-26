//
//  SyntaxMapBuilderTests.swift
//
//  SyntaxMapBuilder
//  https://coteditor.com
//
//  Created by 1024jp on 2020-02-26.
//
//  ---------------------------------------------------------------------------
//
//  © 2020 1024jp
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

import XCTest
import class Foundation.Bundle

final class SyntaxMapBuilderTests: XCTestCase {
    
    static var allTests = [
        ("testExample", testExample),
    ]
    
    
    func testExample() throws {
        
        let fooBinary = productsDirectory.appendingPathComponent("SyntaxMapBuilder")
        
        let process = Process()
        process.executableURL = fooBinary
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        try process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)
        
        XCTAssertEqual(output, "")
    }
    
    
    
    // MARK: Private Methods
    
    /// Returns path to the built products directory.
    private var productsDirectory: URL {
        #if os(macOS)
        for bundle in Bundle.allBundles where bundle.bundlePath.hasSuffix(".xctest") {
            return bundle.bundleURL.deletingLastPathComponent()
        }
        fatalError("couldn't find the products directory")
        #else
        return Bundle.main.bundleURL
        #endif
    }
    
}
