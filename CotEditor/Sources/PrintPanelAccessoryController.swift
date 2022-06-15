//
//  PrintAccessoryViewController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2014-03-24.
//
//  ---------------------------------------------------------------------------
//
//  © 2014-2022 1024jp
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

import Cocoa

extension NSPrintInfo.AttributeKey {
    
    static let theme = Self("CEThemeName")
    static let printsBackground = Self("CEPrintBackground")
    static let lineNumber = Self("CEPrintLineNumber")
    static let invisibles = Self("CEPrintInvisibles")
    static let printsHeader = Self("CEPrintHeader")
    static let primaryHeaderContent = Self("CEPrimaryHeaderContent")
    static let secondaryHeaderContent = Self("CESecondaryHeaderContent")
    static let primaryHeaderAlignment = Self("CEPrimaryHeaderAlignment")
    static let secondaryHeaderAlignment = Self("CESecondaryHeaderAlignment")
    static let printsFooter = Self("CEPrintFooter")
    static let primaryFooterContent = Self("CEPrimaryFooterContent")
    static let secondaryFooterContent = Self("CESecondaryFooterContent")
    static let primaryFooterAlignment = Self("CEPrimaryFooterAlignment")
    static let secondaryFooterAlignment = Self("CESecondaryFooterAlignment")
}


enum ThemeName {
    
    static let blackAndWhite = "Black and White".localized
}



final class PrintPanelAccessoryController: NSViewController, NSPrintPanelAccessorizing {
    
    // MARK: Private Properties
    
    @IBOutlet private weak var colorPopupButton: NSPopUpButton?
    
    
    
    // MARK: -
    // MARK: View Controller Method
    
    /// printInfo did set (new print sheet will be displayed)
    override var representedObject: Any? {
        
        didSet {
            guard representedObject != nil else { return }
            
            // -> Property initialization must be done after setting representedObject, namely NSPrintInfo,
            //    because these values need to be set also to printInfo through the computed setters.
            assert(representedObject is NSPrintInfo)
            
            let defaults = UserDefaults.standard
            
            self.theme = {
                switch PrintColorMode(rawValue: defaults[.printColorIndex]) {
                    case .blackAndWhite:
                        return ThemeName.blackAndWhite
                    case .sameAsDocument:
                        return ThemeManager.shared.userDefaultSettingName
                    default:
                        return defaults[.printTheme] ?? ThemeName.blackAndWhite
                }
            }()
            self.printsBackground = defaults[.printBackground]
            self.lineNumberMode = defaults[.printLineNumIndex]
            self.invisibleCharsMode = defaults[.printInvisibleCharIndex]
            
            self.printsHeader = defaults[.printHeader]
            self.primaryHeaderContent = defaults[.primaryHeaderContent]
            self.primaryHeaderAlignment = defaults[.primaryHeaderAlignment]
            self.secondaryHeaderContent = defaults[.secondaryHeaderContent]
            self.secondaryHeaderAlignment = defaults[.secondaryHeaderAlignment]
            
            self.printsFooter = defaults[.printFooter]
            self.primaryFooterContent = defaults[.primaryFooterContent]
            self.primaryFooterAlignment = defaults[.primaryFooterAlignment]
            self.secondaryFooterContent = defaults[.secondaryFooterContent]
            self.secondaryFooterAlignment = defaults[.secondaryFooterAlignment]
        }
    }
    
    
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        self.setupColorMenu()
    }
    
    
    
    // MARK: NSPrintPanelAccessorizing Protocol
    
    /// list of key paths that affect to preview
    func keyPathsForValuesAffectingPreview() -> Set<String> {
        
        return [#keyPath(theme),
                #keyPath(printsBackground),
                #keyPath(lineNumberMode),
                #keyPath(invisibleCharsMode),
                
                #keyPath(printsHeader),
                #keyPath(primaryHeaderContent),
                #keyPath(primaryHeaderAlignment),
                #keyPath(secondaryHeaderContent),
                #keyPath(secondaryHeaderAlignment),
                
                #keyPath(printsFooter),
                #keyPath(primaryFooterAlignment),
                #keyPath(primaryFooterContent),
                #keyPath(secondaryFooterAlignment),
                #keyPath(secondaryFooterContent),
        ]
    }
    
    
    /// localized descriptions for print settings
    func localizedSummaryItems() -> [[NSPrintPanel.AccessorySummaryKey: String]] {
        
        [
            [.itemName: "Color".localized,
             .itemDescription: self.theme.localized],
            [.itemName: "Print Background".localized,
             .itemDescription: self.printsBackground ? "On".localized : "Off".localized],
            [.itemName: "Line Number".localized,
             .itemDescription: self.lineNumberMode.localizedDescription],
            [.itemName: "Invisibles".localized,
             .itemDescription: self.invisibleCharsMode.localizedDescription],
            
            [.itemName: "Print Header".localized,
             .itemDescription: self.printsHeader ? "On" .localized: "Off".localized],
            [.itemName: "Primary Header".localized,
             .itemDescription: self.primaryHeaderContent.localizedDescription],
            [.itemName: "Primary Header Alignment".localized,
             .itemDescription: self.primaryHeaderContent.localizedDescription],
            [.itemName: "Primary Header".localized,
             .itemDescription: self.secondaryHeaderContent.localizedDescription],
            [.itemName: "Primary Header Alignment".localized,
             .itemDescription: self.secondaryHeaderAlignment.localizedDescription],
            
            [.itemName: "Print Footer".localized,
             .itemDescription: self.printsFooter ? "On".localized : "Off".localized],
            [.itemName: "Primary Footer".localized,
             .itemDescription: self.primaryFooterContent.localizedDescription],
            [.itemName: "Primary Footer Alignment".localized,
             .itemDescription: self.primaryFooterAlignment.localizedDescription],
            [.itemName: "Primary Footer".localized,
             .itemDescription: self.secondaryFooterContent.localizedDescription],
            [.itemName: "Primary Footer Alignment".localized,
             .itemDescription: self.secondaryFooterAlignment.localizedDescription],
        ]
    }
    
    
    
    // MARK: Private Methods
    
    /// cast representedObject to NSPrintInfo
    private var printInfo: NSPrintInfo? {
        
        return self.representedObject as? NSPrintInfo
    }
    
    
    /// update popup menu for color setting
    private func setupColorMenu() {
        
        guard let popupButton = self.colorPopupButton else { return assertionFailure() }
        
        let themeNames = ThemeManager.shared.settingNames
        
        // build popup button
        popupButton.removeAllItems()
        
        popupButton.addItem(withTitle: ThemeName.blackAndWhite)
        popupButton.menu?.addItem(.separator())
        
        popupButton.addItem(withTitle: "Theme".localized)
        popupButton.lastItem?.isEnabled = false
        
        for themeName in themeNames {
            popupButton.addItem(withTitle: themeName)
            popupButton.lastItem?.indentationLevel = 1
        }
        
        // select menu item
        if themeNames.contains(self.theme) {
            popupButton.selectItem(withTitle: self.theme)
        } else {
            popupButton.selectItem(at: 0)  // -> select "Black and White"
        }
    }
    
    
    
    // MARK: Setting Accessors
    
    /// print theme
    @objc dynamic var theme: String {
        
        get { self.printInfo?[.theme] ?? ThemeName.blackAndWhite }
        set { self.printInfo?[.theme] = newValue }
    }
    
    
    /// whether prints background color
    @objc dynamic var printsBackground: Bool {
        
        get { self.printInfo?[.printsBackground] ?? true }
        set { self.printInfo?[.printsBackground] = newValue }
    }
    
    
    /// whether draws line number
    @objc dynamic var lineNumberMode: PrintVisibilityMode {
        
        get { PrintVisibilityMode(self.printInfo?[.lineNumber]) }
        set { self.printInfo?[.lineNumber] = newValue.rawValue }
    }
    
    
    /// whether draws invisible characters
    @objc dynamic var invisibleCharsMode: PrintVisibilityMode {
        
        get { PrintVisibilityMode(self.printInfo?[.invisibles]) }
        set { self.printInfo?[.invisibles] = newValue.rawValue }
    }
    
    
    /// whether prints header
    @objc dynamic var printsHeader: Bool {
        
        get { self.printInfo?[.printsHeader] ?? false }
        set { self.printInfo?[.printsHeader] = newValue }
    }
    
    
    /// primary header item content type
    @objc dynamic var primaryHeaderContent: PrintInfoType {
        
        get { PrintInfoType(self.printInfo?[.primaryHeaderContent]) }
        set { self.printInfo?[.primaryHeaderContent] = newValue.rawValue }
    }
    
    
    /// primary header item align
    @objc dynamic var primaryHeaderAlignment: AlignmentType {
        
        get { AlignmentType(self.printInfo?[.primaryHeaderAlignment]) }
        set { self.printInfo?[.primaryHeaderAlignment] = newValue.rawValue }
    }
    
    
    /// secondary header item content type
    @objc dynamic var secondaryHeaderContent: PrintInfoType {
        
        get { PrintInfoType(self.printInfo?[.secondaryHeaderContent]) }
        set { self.printInfo?[.secondaryHeaderContent] = newValue.rawValue }
    }
    
    
    /// secondary header item align
    @objc dynamic var secondaryHeaderAlignment: AlignmentType {
        
        get { AlignmentType(self.printInfo?[.secondaryHeaderAlignment]) }
        set { self.printInfo?[.secondaryHeaderAlignment] = newValue.rawValue }
    }
    
    
    /// whether prints footer
    @objc dynamic var printsFooter: Bool {
        
        get { self.printInfo?[.printsFooter] ?? false }
        set { self.printInfo?[.printsFooter] = newValue }
    }
    
    
    /// primary footer item content type
    @objc dynamic var primaryFooterContent: PrintInfoType {
        
        get { PrintInfoType(self.printInfo?[.primaryFooterContent]) }
        set { self.printInfo?[.primaryFooterContent] = newValue.rawValue }
    }
    
    
    /// primary footer item align
    @objc dynamic var primaryFooterAlignment: AlignmentType {
        
        get { AlignmentType(self.printInfo?[.primaryFooterAlignment]) }
        set { self.printInfo?[.primaryFooterAlignment] = newValue.rawValue }
    }
    
    
    /// secondary footer item content type
    @objc dynamic var secondaryFooterContent: PrintInfoType {
        
        get { PrintInfoType(self.printInfo?[.secondaryFooterContent]) }
        set { self.printInfo?[.secondaryFooterContent] = newValue.rawValue }
    }
    
    
    /// secondary footer item align
    @objc dynamic var secondaryFooterAlignment: AlignmentType {
        
        get { AlignmentType(self.printInfo?[.secondaryFooterAlignment]) }
        set { self.printInfo?[.secondaryFooterAlignment] = newValue.rawValue }
    }
    
}


private extension PrintVisibilityMode {
    
    var localizedDescription: String {
        
        switch self {
            case .no:
                return "Don’t Print".localized
            case .sameAsDocument:
                return "Same as Document’s Setting".localized
            case .yes:
                return "Print".localized
        }
    }
}


private extension PrintInfoType {
    
    var localizedDescription: String {
        
        switch self {
            case .none:
                return "None".localized
            case .syntaxName:
                return "Syntax Name".localized
            case .documentName:
                return "Document Name".localized
            case .filePath:
                return "File Path".localized
            case .printDate:
                return "Print Date".localized
            case .pageNumber:
                return "Page Number".localized
        }
    }
}


private extension AlignmentType {
    
    var localizedDescription: String {
        
        switch self {
            case .left:
                return "Left".localized
            case .center:
                return "Center".localized
            case .right:
                return "Right".localized
        }
    }
}
