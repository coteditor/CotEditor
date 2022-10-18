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
//  © 2020-2022 1024jp
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
@testable import SyntaxMapBuilder

final class SyntaxMapBuilderTests: XCTestCase {
    
    func testCommand() throws {
        
        let syntaxesURL = Bundle.module.url(forResource: "Syntaxes", withExtension: nil)!
        
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
        
        XCTAssertEqual(try buildSyntaxMap(directoryURL: syntaxesURL), expectedResult)
    }
    
}
