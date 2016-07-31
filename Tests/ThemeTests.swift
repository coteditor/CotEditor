/*
 
 ThemeTests.swift
 Tests
 
 CotEditor
 https://coteditor.com
 
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
@testable import CotEditor

let ThemeDirectoryName = "Themes"
let ThemeExtension = "cottheme"


class ThemeTests: XCTestCase {
    
    var bundle: Bundle?
    
    
    override func setUp() {
        super.setUp()
        
        self.bundle = Bundle(for: self.dynamicType)
    }
    

    func testDefaultTheme() {
        let themeName = "Dendrobates"
        let theme = self.loadThemeWithName(themeName)!
        
        XCTAssertEqual(theme.name, themeName)
        XCTAssertEqual(theme.textColor, NSColor.black().usingColorSpaceName(NSCalibratedRGBColorSpace))
        XCTAssertEqual(theme.insertionPointColor, NSColor.black().usingColorSpaceName(NSCalibratedRGBColorSpace))
        XCTAssertEqualWithAccuracy(theme.invisiblesColor.brightnessComponent, 0.72, accuracy: 0.01)
        XCTAssertEqual(theme.backgroundColor, NSColor.white().usingColorSpaceName(NSCalibratedRGBColorSpace))
        XCTAssertEqualWithAccuracy(theme.lineHighLightColor.brightnessComponent, 0.94, accuracy: 0.01)
        XCTAssertEqual(theme.selectionColor, NSColor.selectedTextBackgroundColor())
        
        for type in SyntaxType.all {
            XCTAssertGreaterThan(theme.syntaxColor(type: type)!.hueComponent, 0)
        }
        
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
        XCTAssertNil(Theme(dictionary: [:], name: ""))
        
        let theme = Theme(dictionary: [:], name: "Broken Theme")
        
        XCTAssertNotNil(theme)  // Theme can be created from a lacking dictionary
        XCTAssertFalse(theme!.isValid)  // but flagged as invalid
        XCTAssertEqual(theme!.textColor, NSColor.gray())  // and unavailable colors are substituted with frayColor().
    }
    
    
    /// test if all of bundled themes are valid
    func testBundledThemes() {
        let themeDirectoryURL = self.bundle?.urlForResource(ThemeDirectoryName, withExtension: nil)!
        let enumerator = FileManager.default.enumerator(at: themeDirectoryURL!, includingPropertiesForKeys: nil, options: [.skipsSubdirectoryDescendants, .skipsHiddenFiles], errorHandler: nil)!
        
        for url in enumerator.allObjects as! [URL] {
            guard url.pathExtension == ThemeExtension else { continue }
            
            let theme = self.loadThemeWithURL(url)
            
            XCTAssertNotNil(theme)
            XCTAssert(theme!.isValid)
        }
    }
    
    
    // MARK: Private Methods
    
    func loadThemeWithName(_ name: String) -> Theme? {
        let url = self.bundle?.urlForResource(name, withExtension: ThemeExtension, subdirectory: ThemeDirectoryName)
        
        return self.loadThemeWithURL(url!)
    }
    
    
    func loadThemeWithURL(_ url: URL) -> Theme? {
        let data = try? Data(contentsOf: url)
        let jsonDict = try! JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as! ThemeDictionary
        let themeName = try! url.deletingPathExtension().lastPathComponent!
        
        XCTAssertNotNil(jsonDict)
        XCTAssertNotNil(themeName)
        
        return Theme(dictionary: jsonDict, name: themeName)
    }

}
