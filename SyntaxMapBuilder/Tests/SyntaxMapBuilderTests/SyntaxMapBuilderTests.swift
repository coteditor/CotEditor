//
//  SyntaxMapBuilderTests.swift
//
//  SyntaxMapBuilder
//  https://coteditor.com
//
//  Created by 1024jp on 2020-02-18.
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
//

import XCTest
import class Foundation.Bundle

final class SyntaxMapBuilderTests: XCTestCase {
    
    func testExecutable() throws {
        
        let executableURL = self.productsDirectory.appendingPathComponent("SyntaxMapBuilder")
        let inputURL = self.testDirectory.appendingPathComponent("Resources")
        
        let process = Process()
        process.executableURL = executableURL
        process.arguments = [inputURL.path]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        try process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)
        
        let expectedResult = """
            {
              "Apache" : {
                "extensions" : [
                  "conf"
                ],
                "filenames" : [
                  ".htaccess"
                ],
                "interpreters" : [

                ]
              },
              "Python" : {
                "extensions" : [
                  "py"
                ],
                "filenames" : [

                ],
                "interpreters" : [
                  "python",
                  "python2",
                  "python3"
                ]
              }
            }
            
            """
        
        XCTAssertEqual(output, expectedResult)
    }
    
}



private extension XCTestCase {
    
    /// Path to the built products directory.
    var productsDirectory: URL {
        
        return Bundle.allBundles
            .first { $0.bundlePath.hasSuffix(".xctest") }!
            .bundleURL
            .deletingLastPathComponent()
    }
    
    
    /// Path to the test directory in package.
    var testDirectory: URL {
        
        return URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
    
}
