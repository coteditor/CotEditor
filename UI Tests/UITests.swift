//
//  UITests.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-02-13.
//
//  ---------------------------------------------------------------------------
//
//  © 2018-2022 1024jp
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

final class UITests: XCTestCase {
    
    override func setUp() {
        
        super.setUp()
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        self.continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()
    }
    
    
    func testTyping() {
        
        let app = XCUIApplication()
        
        // open new document
        let menuBarsQuery = app.menuBars
        menuBarsQuery.menuBarItems["File"].click()
        menuBarsQuery.menuItems["New Window"].click()
        
        // type some words
        let documentWindow = app.windows.firstMatch
        let textView = documentWindow.textViews.firstMatch
        textView.typeText("Test.\r")
        XCTAssertEqual(textView.value as! String, "Test.\n")
        
        // wait a bit to let document autosave
        sleep(1)
        
        // delete entire words
        for _ in 1...6 {
            textView.typeKey(.delete, modifierFlags: [])
        }
        
        // close window without save
        documentWindow.buttons[XCUIIdentifierCloseWindow].click()
        if documentWindow.sheets.count > 0 {
            // it actually depends on user settings and iCloud availability if save sheet appears...
            documentWindow.sheets.firstMatch.children(matching: .button)["Delete"].click()
        }
        sleep(1)
        XCTAssert(documentWindow.exists)
    }
    
    
    func testLaunchPerformance() throws {
        
        // This measures how long it takes to launch your application.
        self.measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
    
}
