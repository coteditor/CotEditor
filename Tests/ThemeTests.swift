/*
 
 ThemeTests.swift
 Tests
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2016-03-15.
 
 ------------------------------------------------------------------------------
 
 © 2016 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import XCTest

let ThemeDirectoryName = "Themes"
let ThemeExtension = "cottheme"


class ThemeTests: XCTestCase {
    
    var bundle: Bundle?
    
    
    override func setUp() {
        super.setUp()
        
        self.bundle = Bundle(for: type(of: self))
    }
    

    func testDefaultTheme() {
        let themeName = "Dendrobates"
        let theme = self.loadThemeWithName(themeName)!
        
        XCTAssertEqual(theme.name, themeName)
        XCTAssertEqual(theme.textColor, NSColor.black.usingColorSpaceName(NSCalibratedRGBColorSpace))
        XCTAssertEqual(theme.insertionPointColor, NSColor.black.usingColorSpaceName(NSCalibratedRGBColorSpace))
        XCTAssertEqualWithAccuracy(theme.invisiblesColor.brightnessComponent, 0.72, accuracy: 0.01)
        XCTAssertEqual(theme.backgroundColor, NSColor.white.usingColorSpaceName(NSCalibratedRGBColorSpace))
        XCTAssertEqualWithAccuracy(theme.lineHighLightColor.brightnessComponent, 0.94, accuracy: 0.01)
        XCTAssertEqual(theme.selectionColor, NSColor.selectedTextBackgroundColor)
        XCTAssertGreaterThan(theme.keywordsColor.hueComponent, 0)
        XCTAssertGreaterThan(theme.commandsColor.hueComponent, 0)
        XCTAssertGreaterThan(theme.typesColor.hueComponent, 0)
        XCTAssertGreaterThan(theme.attributesColor.hueComponent, 0)
        XCTAssertGreaterThan(theme.variablesColor.hueComponent, 0)
        XCTAssertGreaterThan(theme.valuesColor.hueComponent, 0)
        XCTAssertGreaterThan(theme.numbersColor.hueComponent, 0)
        XCTAssertGreaterThan(theme.stringsColor.hueComponent, 0)
        XCTAssertGreaterThan(theme.charactersColor.hueComponent, 0)
        XCTAssertGreaterThan(theme.commandsColor.hueComponent, 0)
        
        XCTAssertEqualWithAccuracy(theme.weakTextColor.brightnessComponent, 0.3, accuracy: 0.01)
        XCTAssertEqualWithAccuracy(theme.markupColor.brightnessComponent, 0.5, accuracy: 0.01)
        
        XCTAssertEqual(theme.syntaxColor(forType: CEThemeKeywordsKey), theme.keywordsColor)
        XCTAssertEqual(theme.syntaxColor(forType: CEThemeCommandsKey), theme.commandsColor)
        XCTAssertEqual(theme.syntaxColor(forType: CEThemeTypesKey), theme.typesColor)
        XCTAssertEqual(theme.syntaxColor(forType: CEThemeAttributesKey), theme.attributesColor)
        XCTAssertEqual(theme.syntaxColor(forType: CEThemeVariablesKey), theme.variablesColor)
        XCTAssertEqual(theme.syntaxColor(forType: CEThemeValuesKey), theme.valuesColor)
        XCTAssertEqual(theme.syntaxColor(forType: CEThemeNumbersKey), theme.numbersColor)
        XCTAssertEqual(theme.syntaxColor(forType: CEThemeStringsKey), theme.stringsColor)
        XCTAssertEqual(theme.syntaxColor(forType: CEThemeCharactersKey), theme.charactersColor)
        XCTAssertEqual(theme.syntaxColor(forType: CEThemeCommandsKey), theme.commandsColor)
        XCTAssertNil(theme.syntaxColor(forType: "foo"))
        
        XCTAssertFalse(theme.isDarkTheme)
    }
    
    
    func testDarkTheme() {
        let themeName = "Solarized (Dark)"
        let theme = self.loadThemeWithName(themeName)!
        
        XCTAssertEqual(theme.name, themeName)
        XCTAssertTrue(theme.isDarkTheme)
    }
    
    
    func testFail() {
        // zero-length theme name is invalid
        XCTAssertNil(CETheme(dictinonary: ["foo": ["dog": "cow"]], name: ""))
        
        let theme = CETheme(dictinonary: ["foo": ["dog": "cow"]], name: "Broken Theme")
        
        XCTAssertNotNil(theme)  // Theme can be created from a lacking dictionary
        XCTAssertFalse(theme!.isValid)  // but flagged as invalid
        XCTAssertEqual(theme!.textColor, NSColor.gray)  // and unavailable colors are substituted with frayColor().
    }
    
    
    /// test if all of bundled themes are valid
    func testBundledThemes() {
        let themeDirectoryURL = self.bundle?.url(forResource: ThemeDirectoryName, withExtension: nil)!
        let enumerator = FileManager.default.enumerator(at: themeDirectoryURL!, includingPropertiesForKeys: nil, options: [.skipsSubdirectoryDescendants, .skipsHiddenFiles], errorHandler: nil)!
        
        for url in enumerator.allObjects as! [URL] {
            guard url.pathExtension == ThemeExtension else { continue }
            
            let theme = self.loadThemeWithURL(url)
            
            XCTAssertNotNil(theme)
            XCTAssert(theme!.keywordsColor.isKind(of: NSColor.self))
            XCTAssert(theme!.isValid)
        }
    }
    
    
    // MARK: Private Methods
    
    func loadThemeWithName(_ name: String) -> CETheme? {
        let url = self.bundle?.url(forResource: name, withExtension: ThemeExtension, subdirectory: ThemeDirectoryName)
        
        return self.loadThemeWithURL(url!)
    }
    
    
    func loadThemeWithURL(_ url: URL) -> CETheme? {
        let data = try? Data(contentsOf: url)
        let jsonDict = try! JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as! [String: [AnyHashable: Any]]
        let themeName = url.deletingPathExtension().lastPathComponent
        
        XCTAssertNotNil(jsonDict)
        XCTAssertNotNil(themeName)
        
        return CETheme(dictinonary: jsonDict, name: themeName)
        
    }

}
