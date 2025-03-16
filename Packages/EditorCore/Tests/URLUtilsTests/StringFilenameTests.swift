//
//  StringFilename.swift
//  URLUtilsTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2017-03-19.
//
//  ---------------------------------------------------------------------------
//
//  © 2017-2025 1024jp
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
@testable import URLUtils

struct StringFilename {
    
    @Test func removeExtension() {
        
        #expect("test".deletingPathExtension == "test")
        #expect("test.".deletingPathExtension == "test.")
        #expect("test.txt".deletingPathExtension == "test")
        #expect("test..txt".deletingPathExtension == "test.")
        #expect("test.txt.txt".deletingPathExtension == "test.txt")
        #expect(".htaccess".deletingPathExtension == ".htaccess")
        #expect("1.2 file".deletingPathExtension == "1.2 file")
    }
    
    
    @Test func pathExtension() {
        
        #expect("test".pathExtension == nil)
        #expect("test.".pathExtension == nil)
        #expect("test.txt".pathExtension == "txt")
        #expect("test..txt".pathExtension == "txt")
        #expect("test.txt.txt".pathExtension == "txt")
        #expect(".htaccess".pathExtension == nil)
        #expect("1.2 file".pathExtension == nil)
    }
    
    
    @Test func numberingComponents() {
        
        #expect(" ".numberingComponents() == (" ", 1))
        #expect("1".numberingComponents() == ("1", 1))
        #expect(" 1".numberingComponents() == (" 1", 1))
        #expect("test".numberingComponents() == ("test", 1))
        #expect("test 5".numberingComponents() == ("test", 5))
        #expect("test copy".numberingComponents() == ("test copy", 1))
        #expect("test copy 5".numberingComponents() == ("test copy", 5))
        
        #expect(" ".numberingComponents(suffix: " copy") == (" ", 1))
        #expect("1".numberingComponents(suffix: " copy") == ("1", 1))
        #expect(" 1".numberingComponents(suffix: " copy") == (" 1", 1))
        #expect("test".numberingComponents(suffix: " copy") == ("test", 1))
        #expect("test 5".numberingComponents(suffix: " copy") == ("test 5", 1))
        #expect("test copy".numberingComponents(suffix: " copy") == ("test", 1))
        #expect("test copy 5".numberingComponents(suffix: " copy") == ("test", 5))
        #expect(" copy".numberingComponents(suffix: " copy") == (" copy", 1))
        #expect("  copy".numberingComponents(suffix: " copy") == (" ", 1))
        #expect("copy 5".numberingComponents(suffix: " copy") == ("copy 5", 1))
    }
    
    
    @Test func appendingUniqueNumber() {
        
        let names = ["foo", "foo 3", "foo copy 3", "foo 4", "foo 7"]
        
        #expect("foo".appendingUniqueNumber(in: names) == "foo 2")
        #expect("foo 2".appendingUniqueNumber(in: names) == "foo 2")
        #expect("foo 3".appendingUniqueNumber(in: names) == "foo 5")
        
        #expect("foo".appendingUniqueNumber(in: []) == "foo")
    }
}
