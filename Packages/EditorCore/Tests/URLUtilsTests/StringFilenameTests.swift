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
        
        #expect(" ".numberingComponents == (" ", 1))
        #expect("1".numberingComponents == ("1", 1))
        #expect(" 1".numberingComponents == (" 1", 1))
        #expect("test".numberingComponents == ("test", 1))
        #expect("test 5".numberingComponents == ("test", 5))
        #expect("test copy".numberingComponents == ("test copy", 1))
        #expect("test copy 5".numberingComponents == ("test copy", 5))
    }
    
    
    @Test func englishFormat() {
        
        let format = NumberingFormat { base in
            "\(base) copy"
        } numbered: { base, count in
            "\(base) copy \(count)"
        }
        
        #expect(format.components(" ") == (" ", 1))
        #expect(format.components("1") == ("1", 1))
        #expect(format.components(" 1") == (" 1", 1))
        #expect(format.components("test") == ("test", 1))
        #expect(format.components("test 5") == ("test 5", 1))
        #expect(format.components("test copy") == ("test", 1))
        #expect(format.components("test copy 5") == ("test", 5))
        #expect(format.components(" copy") == (" copy", 1))
        #expect(format.components("  copy") == (" ", 1))
        #expect(format.components("copy 5") == ("copy 5", 1))
        
        #expect(format.filename("test", count: 1) == "test copy")
        #expect(format.filename("test 1", count: 1) == "test 1 copy")
        #expect(format.filename("test", count: 2) == "test copy 2")
        #expect(format.filename("test 1", count: 2) == "test 1 copy 2")
    }
    
    
    @Test func czechFormat() {
        
        let format = NumberingFormat { base in
            "\(base) (kopie)"
        } numbered: { base, count in
            "\(base) (kopie \(count))"
        }
        #expect(format.components(" ") == (" ", 1))
        #expect(format.components("1") == ("1", 1))
        #expect(format.components(" 1") == (" 1", 1))
        #expect(format.components("test") == ("test", 1))
        #expect(format.components("test 5") == ("test 5", 1))
        #expect(format.components("test (kopie)") == ("test", 1))
        #expect(format.components("test (kopie 5)") == ("test", 5))
        #expect(format.components(" (kopie)") == (" (kopie)", 1))
        #expect(format.components("  (kopie)") == (" ", 1))
        #expect(format.components("(kopie 5)") == ("(kopie 5)", 1))
        
        #expect(format.filename("test", count: 1) == "test (kopie)")
        #expect(format.filename("test 1", count: 1) == "test 1 (kopie)")
        #expect(format.filename("test", count: 2) == "test (kopie 2)")
        #expect(format.filename("test 1", count: 2) == "test 1 (kopie 2)")
    }
    
    
    @Test func spanishFormat() {
        
        let format = NumberingFormat { base in
            "Copia de \(base)"
        } numbered: { base, count in
            "Copia de \(base) \(count)"
        }
        #expect(format.components(" ") == (" ", 1))
        #expect(format.components("1") == ("1", 1))
        #expect(format.components(" 1") == (" 1", 1))
        #expect(format.components("test") == ("test", 1))
        #expect(format.components("test 5") == ("test 5", 1))
        #expect(format.components("Copia de test") == ("test", 1))
        #expect(format.components("Copia de test 5") == ("test", 5))
        #expect(format.components("Copia de ") == ("Copia de ", 1))
        #expect(format.components("Copia de  ") == (" ", 1))
        #expect(format.components("Copia de 5") == ("5", 1))
        
        #expect(format.filename("test", count: 1) == "Copia de test")
        #expect(format.filename("test 1", count: 1) == "Copia de test 1")
        #expect(format.filename("test", count: 2) == "Copia de test 2")
        #expect(format.filename("test 1", count: 2) == "Copia de test 1 2")
    }
    
    
    @Test func appendingUniqueNumber() {
        
        let names = ["foo", "foo 3", "foo copy 3", "foo 4", "foo 7"]
        
        #expect("foo".appendingUniqueNumber(in: names) == "foo 2")
        #expect("foo 2".appendingUniqueNumber(in: names) == "foo 2")
        #expect("foo 3".appendingUniqueNumber(in: names) == "foo 5")
        
        #expect("foo".appendingUniqueNumber(in: []) == "foo")
    }
}
