//
//  SyntaxMappingTableTests.swift
//  SyntaxFormatTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-04-11.
//
//  ---------------------------------------------------------------------------
//
//  © 2026 1024jp
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
@testable import SyntaxFormat

struct SyntaxMappingTableTests {
    
    @Test func isEmpty() {
        
        #expect(SyntaxMappingTable().isEmpty)
        #expect(!SyntaxMappingTable(extensions: ["py": ["Python"]]).isEmpty)
    }
    
    
    @Test func syntaxNameForExactFilename() {
        
        let table = SyntaxMappingTable(filenames: ["Makefile": ["Makefile"]])
        
        #expect(table.syntaxName(forFilename: "Makefile") == "Makefile")
        #expect(table.syntaxName(forFilename: "README") == nil)
    }
    
    
    @Test func syntaxNameForExtension() {
        
        let table = SyntaxMappingTable(extensions: ["swift": ["Swift"], "py": ["Python"]])
        
        #expect(table.syntaxName(forFilename: "main.swift") == "Swift")
        #expect(table.syntaxName(forFilename: "script.py") == "Python")
        #expect(table.syntaxName(forFilename: "noext") == nil)
    }
    
    
    @Test func syntaxNameForExtensionCaseInsensitive() {
        
        let table = SyntaxMappingTable(extensions: ["Swift": ["Swift"]])
        
        #expect(table.syntaxName(forFilename: "main.swift") == "Swift")
        #expect(table.syntaxName(forFilename: "main.SWIFT") == "Swift")
    }
    
    
    @Test func filenameMatchTakesPrecedenceOverExtension() {
        
        let table = SyntaxMappingTable(
            extensions: ["conf": ["Apache"]],
            filenames: [".htaccess": ["Apache"]]
        )
        
        #expect(table.syntaxName(forFilename: ".htaccess") == "Apache")
    }
    
    
    @Test func syntaxNameForShebang() {
        
        let table = SyntaxMappingTable(interpreters: ["python3": ["Python"], "ruby": ["Ruby"]])
        
        #expect(table.syntaxName(forContent: "#!/usr/bin/env python3\nimport os") == "Python")
        #expect(table.syntaxName(forContent: "#!/usr/bin/ruby") == "Ruby")
        #expect(table.syntaxName(forContent: "no shebang here") == nil)
    }
    
    
    @Test func syntaxNameForXMLDeclaration() {
        
        let table = SyntaxMappingTable()
        
        #expect(table.syntaxName(forContent: "<?xml version=\"1.0\"?>") == "XML")
        #expect(table.syntaxName(forContent: "<html>") == nil)
    }
    
    
    @Test func buildFromFileMaps() {
        
        let maps: [String: Syntax.FileMap] = [
            "Python": .init(extensions: ["py"], interpreters: ["python", "python3"]),
            "Ruby": .init(extensions: ["rb"], filenames: ["Gemfile"], interpreters: ["ruby"]),
        ]
        
        let table = SyntaxMappingTable(syntaxNames: ["Python", "Ruby"], maps: maps)
        
        #expect(table.extensions["py"] == ["Python"])
        #expect(table.extensions["rb"] == ["Ruby"])
        #expect(table.filenames["Gemfile"] == ["Ruby"])
        #expect(table.interpreters["python"] == ["Python"])
        #expect(table.interpreters["ruby"] == ["Ruby"])
    }
    
    
    @Test func buildPriority() {
        
        let maps: [String: Syntax.FileMap] = [
            "UserSyntax": .init(extensions: ["txt"]),
            "BundledSyntax": .init(extensions: ["txt"]),
        ]
        
        // UserSyntax listed first -> takes precedence
        let table = SyntaxMappingTable(syntaxNames: ["UserSyntax", "BundledSyntax"], maps: maps)
        
        #expect(table.extensions["txt"]?.first == "UserSyntax")
        #expect(table.extensions["txt"]?.count == 2)
    }
    
    
    @Test func scanInterpreter() {
        
        #expect(SyntaxMappingTable.scanInterpreterInShebang("") == nil)
        #expect(SyntaxMappingTable.scanInterpreterInShebang("swift") == nil)
        #expect(SyntaxMappingTable.scanInterpreterInShebang("#!/usr/bin/swift") == "swift")
        #expect(SyntaxMappingTable.scanInterpreterInShebang("#!/usr/bin/env swift") == "swift")
        #expect(SyntaxMappingTable.scanInterpreterInShebang("#!/usr/bin/env swift\nabc") == "swift")
        #expect(SyntaxMappingTable.scanInterpreterInShebang("#!/usr/bin/osascript -l JavaScript") == "osascript")
    }
}
