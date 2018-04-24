//
//  ThemeTests.swift
//  Tests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-03-15.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2018 1024jp
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
@testable import CotEditor

let themeDirectoryName = "Themes"


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
        XCTAssertEqual(theme.text.color, NSColor.black.usingColorSpaceName(.calibratedRGB))
        XCTAssertEqual(theme.insertionPoint.color, NSColor.black.usingColorSpaceName(.calibratedRGB))
        XCTAssertEqual(theme.invisibles.color.brightnessComponent, 0.72, accuracy: 0.01)
        XCTAssertEqual(theme.background.color, NSColor.white.usingColorSpaceName(.calibratedRGB))
        XCTAssertEqual(theme.lineHighLight.color.brightnessComponent, 0.94, accuracy: 0.01)
        XCTAssertEqual(theme.selection.color, NSColor.selectedTextBackgroundColor)
        
        for type in SyntaxType.all {
            XCTAssertGreaterThan(theme.style(for: type)!.color.hueComponent, 0)
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
        
        let theme = Theme(dictionary: [:])
        
        XCTAssertNotNil(theme)  // Theme can be created from a lacking dictionary
        XCTAssertEqual(theme!.text.color, NSColor.gray.usingColorSpaceName(.calibratedRGB))  // and unavailable colors are substituted with frayColor().
    }
    
    
    /// test if all of bundled themes are valid
    func testBundledThemes() {
        
        let themeDirectoryURL = self.bundle?.url(forResource: themeDirectoryName, withExtension: nil)!
        let enumerator = FileManager.default.enumerator(at: themeDirectoryURL!, includingPropertiesForKeys: nil, options: [.skipsSubdirectoryDescendants, .skipsHiddenFiles])!
        
        for case let url as URL in enumerator {
            guard DocumentType.theme.extensions.contains(url.pathExtension) else { continue }
            
            let theme = self.loadThemeWithURL(url)
            
            XCTAssertNotNil(theme)
        }
    }
    
    
    // MARK: Private Methods
    
    func loadThemeWithName(_ name: String) -> Theme? {
        
        let url = self.bundle?.url(forResource: name, withExtension: DocumentType.theme.extensions[0], subdirectory: themeDirectoryName)
        
        return self.loadThemeWithURL(url!)
    }
    
    
    func loadThemeWithURL(_ url: URL) -> Theme? {
        
        let data = try! Data(contentsOf: url)
        let jsonDict = try! JSONSerialization.jsonObject(with: data, options: .mutableContainers) as! ThemeDictionary
        let themeName = url.deletingPathExtension().lastPathComponent
        
        XCTAssertNotNil(jsonDict)
        XCTAssertNotNil(themeName)
        
        return Theme(dictionary: jsonDict)
    }

}
