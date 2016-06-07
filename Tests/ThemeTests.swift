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
    
    var bundle: NSBundle?
    
    
    override func setUp() {
        super.setUp()
        
        self.bundle = NSBundle(forClass: self.dynamicType)
    }
    

    func testDefaultTheme() {
        let themeName = "Dendrobates"
        let theme = self.loadThemeWithName(themeName)!
        
        XCTAssertEqual(theme.name, themeName)
        XCTAssertEqual(theme.textColor, NSColor.blackColor().colorUsingColorSpaceName(NSCalibratedRGBColorSpace))
        XCTAssertEqual(theme.insertionPointColor, NSColor.blackColor().colorUsingColorSpaceName(NSCalibratedRGBColorSpace))
        XCTAssertEqualWithAccuracy(theme.invisiblesColor.brightnessComponent, 0.72, accuracy: 0.01)
        XCTAssertEqual(theme.backgroundColor, NSColor.whiteColor().colorUsingColorSpaceName(NSCalibratedRGBColorSpace))
        XCTAssertEqualWithAccuracy(theme.lineHighLightColor.brightnessComponent, 0.94, accuracy: 0.01)
        XCTAssertEqual(theme.selectionColor, NSColor.selectedTextBackgroundColor())
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
        
        XCTAssertEqualWithAccuracy(theme.weakTextColor.brightnessComponent, 0.25, accuracy: 0.01)
        
        XCTAssertEqual(theme.syntaxColorForType(CEThemeKeywordsKey), theme.keywordsColor)
        XCTAssertEqual(theme.syntaxColorForType(CEThemeCommandsKey), theme.commandsColor)
        XCTAssertEqual(theme.syntaxColorForType(CEThemeTypesKey), theme.typesColor)
        XCTAssertEqual(theme.syntaxColorForType(CEThemeAttributesKey), theme.attributesColor)
        XCTAssertEqual(theme.syntaxColorForType(CEThemeVariablesKey), theme.variablesColor)
        XCTAssertEqual(theme.syntaxColorForType(CEThemeValuesKey), theme.valuesColor)
        XCTAssertEqual(theme.syntaxColorForType(CEThemeNumbersKey), theme.numbersColor)
        XCTAssertEqual(theme.syntaxColorForType(CEThemeStringsKey), theme.stringsColor)
        XCTAssertEqual(theme.syntaxColorForType(CEThemeCharactersKey), theme.charactersColor)
        XCTAssertEqual(theme.syntaxColorForType(CEThemeCommandsKey), theme.commandsColor)
        XCTAssertNil(theme.syntaxColorForType("foo"))
        
        XCTAssertFalse(theme.darkTheme)
    }
    
    
    func testDarkTheme() {
        let themeName = "Solarized (Dark)"
        let theme = self.loadThemeWithName(themeName)!
        
        XCTAssertEqual(theme.name, themeName)
        XCTAssertTrue(theme.darkTheme)
    }
    
    
    func testFail() {
        // zero-length theme name is invalid
        XCTAssertNil(CETheme(dictinonary: ["foo": ["dog": "cow"]], name: ""))
        
        let theme = CETheme(dictinonary: ["foo": ["dog": "cow"]], name: "Broken Theme")
        
        XCTAssertNotNil(theme)  // Theme can be created from a lacking dictionary
        XCTAssertFalse(theme!.valid)  // but flagged as invalid
        XCTAssertEqual(theme!.textColor, NSColor.grayColor())  // and unavailable colors are substituted with frayColor().
    }
    
    
    /// test if all of bundled themes are valid
    func testBundledThemes() {
        let themeDirectoryURL = self.bundle?.URLForResource(ThemeDirectoryName, withExtension: nil)!
        let enumerator = NSFileManager.defaultManager().enumeratorAtURL(themeDirectoryURL!, includingPropertiesForKeys: nil, options: [.SkipsSubdirectoryDescendants, .SkipsHiddenFiles], errorHandler: nil)!
        
        for url in enumerator.allObjects as! [NSURL] {
            guard url.pathExtension == ThemeExtension else { continue }
            
            let theme = self.loadThemeWithURL(url)
            
            XCTAssertNotNil(theme)
            XCTAssert(theme!.keywordsColor.isKindOfClass(NSColor))
            XCTAssert(theme!.valid)
        }
    }
    
    
    // MARK: Private Methods
    
    func loadThemeWithName(name: String) -> CETheme? {
        let url = self.bundle?.URLForResource(name, withExtension: ThemeExtension, subdirectory: ThemeDirectoryName)
        
        return self.loadThemeWithURL(url!)
    }
    
    
    func loadThemeWithURL(url: NSURL) -> CETheme? {
        let data = NSData(contentsOfURL: url)
        let jsonDict = try! NSJSONSerialization.JSONObjectWithData(data!, options: .MutableContainers) as! [String: [NSObject: AnyObject]]
        let themeName = url.URLByDeletingPathExtension!.lastPathComponent!
        
        XCTAssertNotNil(jsonDict)
        XCTAssertNotNil(themeName)
        
        return CETheme(dictinonary: jsonDict, name: themeName)
        
    }

}
