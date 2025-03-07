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
//  © 2016-2024 1024jp
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

import AppKit
import UniformTypeIdentifiers
import Testing
import Numerics
import Syntax
@testable import CotEditor

actor ThemeTests {
    
    private let themeDirectoryName = "Themes"
    
    
    @Test func defaultTheme() throws {
        
        let themeName = "Dendrobates"
        let theme = try self.loadThemeWithName(themeName)
        
        #expect(theme.name == themeName)
        #expect(theme.text.color == NSColor.black.usingColorSpace(.genericRGB))
        #expect(theme.insertionPoint.color == NSColor.black.usingColorSpace(.genericRGB))
        #expect(theme.invisibles.color.brightnessComponent.isApproximatelyEqual(to: 0.725, relativeTolerance: 0.01))
        #expect(theme.background.color == NSColor.white.usingColorSpace(.genericRGB))
        #expect(theme.lineHighlight.color.brightnessComponent.isApproximatelyEqual(to: 0.929, relativeTolerance: 0.01))
        #expect(!theme.isDarkTheme)
        
        let aqua = try #require(NSAppearance(named: .aqua))
        aqua.performAsCurrentDrawingAppearance {
            #expect(theme.unemphasizedSelectionColor != nil)
        }
        
        let darkAppearance = try #require(NSAppearance(named: .darkAqua))
        darkAppearance.performAsCurrentDrawingAppearance {
            #expect(theme.unemphasizedSelectionColor != nil)
        }
        
        for type in SyntaxType.allCases {
            let style = try #require(theme.style(for: type))
            #expect(style.color.hueComponent > 0)
        }
        
        #expect(!theme.isDarkTheme)
    }
    
    
    @Test func darkTheme() throws {
        
        let themeName = "Anura (Dark)"
        let theme = try self.loadThemeWithName(themeName)
        
        #expect(theme.name == themeName)
        #expect(theme.isDarkTheme)
    }
    
    
    /// Tests if all of bundled themes are valid.
    @Test func bundledThemes() throws {
        
        let themeDirectoryURL = try #require(Bundle.main.url(forResource: self.themeDirectoryName, withExtension: nil))
        let urls = try FileManager.default.contentsOfDirectory(at: themeDirectoryURL, includingPropertiesForKeys: nil, options: [.skipsSubdirectoryDescendants, .skipsHiddenFiles])
            .filter { UTType.cotTheme.preferredFilenameExtension == $0.pathExtension }
        
        #expect(!urls.isEmpty)
        
        for url in urls {
            #expect(throws: Never.self) { try Theme(contentsOf: url) }
        }
    }
}


private extension ThemeTests {
    
    func loadThemeWithName(_ name: String) throws -> Theme {
        
        guard
            let url = Bundle.main.url(forResource: name, withExtension: UTType.cotTheme.preferredFilenameExtension, subdirectory: self.themeDirectoryName)
        else { throw CocoaError(.fileNoSuchFile) }
        
        return try Theme(contentsOf: url)
    }
}
