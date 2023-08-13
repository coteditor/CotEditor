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
//  © 2014-2023 1024jp
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

extension NSPrintInfo.AttributeKey {
    
    static let fontSize = Self("CEFontSize")
    static let theme = Self("CEThemeName")
    static let printsBackground = Self("CEPrintBackground")
    static let printsLineNumbers = Self("CEPrintLineNumber")
    static let printsInvisibles = Self("CEPrintInvisibles")
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
    
    static let blackAndWhite = String(localized: "Black and White")
}



final class PrintPanelAccessoryController: NSViewController, NSPrintPanelAccessorizing {
    
    // MARK: Public Properties
    
    // settings on current window to be set by Document.
    // These values are used if set option is "Same as document's setting"
    var documentShowsLineNumber = false
    var documentShowsInvisibles = false
    
    
    // MARK: Private Properties
    
    @IBOutlet private weak var colorPopUpButton: NSPopUpButton?
    
    @IBOutlet private weak var primaryHeaderPopUpButton: NSPopUpButton?
    @IBOutlet private weak var secondaryHeaderPopUpButton: NSPopUpButton?
    @IBOutlet private weak var primaryFooterPopUpButton: NSPopUpButton?
    @IBOutlet private weak var secondaryFooterPopUpButton: NSPopUpButton?
    
    @IBOutlet private weak var primaryHeaderAlignmentControl: NSSegmentedControl?
    @IBOutlet private weak var secondaryHeaderAlignmentControl: NSSegmentedControl?
    @IBOutlet private weak var primaryFooterAlignmentControl: NSSegmentedControl?
    @IBOutlet private weak var secondaryFooterAlignmentControl: NSSegmentedControl?
    
    
    
    // MARK: -
    // MARK: View Controller Method
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.setup(popUpButton: self.primaryHeaderPopUpButton!, contentKey: #keyPath(primaryHeaderContent), enablingKey: #keyPath(printsHeader))
        self.setup(popUpButton: self.secondaryHeaderPopUpButton!, contentKey: #keyPath(secondaryHeaderContent), enablingKey: #keyPath(printsHeader))
        self.setup(popUpButton: self.primaryFooterPopUpButton!, contentKey: #keyPath(primaryFooterContent), enablingKey: #keyPath(printsFooter))
        self.setup(popUpButton: self.secondaryFooterPopUpButton!, contentKey: #keyPath(secondaryFooterContent), enablingKey: #keyPath(printsFooter))
        
        AlignmentType.setup(segmentedControl: self.primaryHeaderAlignmentControl!)
        AlignmentType.setup(segmentedControl: self.secondaryHeaderAlignmentControl!)
        AlignmentType.setup(segmentedControl: self.primaryFooterAlignmentControl!)
        AlignmentType.setup(segmentedControl: self.secondaryFooterAlignmentControl!)
    }
    
    
    /// printInfo did set (new print sheet will be displayed)
    override var representedObject: Any? {
        
        didSet {
            guard representedObject != nil else { return }
            
            // -> Property initialization must be done after setting representedObject, namely NSPrintInfo,
            //    because these values need to be set also to printInfo through the computed setters.
            assert(representedObject is NSPrintInfo)
            
            let defaults = UserDefaults.standard
            
            self.fontSize = defaults[.printFontSize]
            
            self.theme = switch PrintColorMode(rawValue: defaults[.printColorIndex]) {
                case .blackAndWhite: ThemeName.blackAndWhite
                case .sameAsDocument: ThemeManager.shared.userDefaultSettingName
                default: defaults[.printTheme] ?? ThemeName.blackAndWhite
            }
            self.printsBackground = defaults[.printBackground]
            
            self.printsLineNumbers = switch defaults[.printLineNumIndex] {
                case .no: false
                case .sameAsDocument: self.documentShowsLineNumber
                case .yes: true
            }
            
            self.printsInvisibles = switch defaults[.printInvisibleCharIndex] {
                case .no: false
                case .sameAsDocument: self.documentShowsInvisibles
                case .yes: true
            }
            
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
        
        [
            #keyPath(fontSize),
            #keyPath(theme),
            #keyPath(printsBackground),
            #keyPath(printsLineNumbers),
            #keyPath(printsInvisibles),
            
            #keyPath(printsHeader),
            #keyPath(primaryHeaderContent),
            #keyPath(primaryHeaderAlignment),
            #keyPath(secondaryHeaderContent),
            #keyPath(secondaryHeaderAlignment),
            
            #keyPath(printsFooter),
            #keyPath(primaryFooterContent),
            #keyPath(primaryFooterAlignment),
            #keyPath(secondaryFooterContent),
            #keyPath(secondaryFooterAlignment),
        ]
    }
    
    
    /// localized descriptions for print settings
    func localizedSummaryItems() -> [[NSPrintPanel.AccessorySummaryKey: String]] {
        
        var items: [[NSPrintPanel.AccessorySummaryKey: String]] = [
            [.itemName: String(localized: "Font Size"),
             .itemDescription: String(localized: "\(Double(self.fontSize).formatted(.number.precision(.fractionLength(0...1)))) pt")],
            [.itemName: String(localized: "Color"),
             .itemDescription: self.theme],
        ]
        
        if self.printsBackground {
            items += [[.itemName: String(localized: "Print Backgrounds"),
                       .itemDescription: String(localized: "On")]]
        }
        if self.printsLineNumbers {
            items += [[.itemName: String(localized: "Line Number"),
                       .itemDescription: String(localized: "On")]]
        }
        if self.printsInvisibles {
            items += [[.itemName: String(localized: "Invisibles"),
                       .itemDescription: String(localized: "On")]]
        }
        if self.printsHeader, self.primaryHeaderContent != .none {
            items += [[.itemName: String(localized: "Primary Header"),
                       .itemDescription: self.primaryHeaderContent.label
                       + String(localized: " (\(self.primaryHeaderAlignment.label))")]]
        }
        if self.printsHeader, self.secondaryHeaderContent != .none {
            items += [[.itemName: String(localized: "Secondary Header"),
                       .itemDescription: self.secondaryHeaderContent.label
                       + String(localized: " (\(self.secondaryHeaderAlignment.label))")]]
        }
        if self.printsFooter, self.primaryFooterContent != .none {
            items += [[.itemName: String(localized: "Primary Footer"),
                       .itemDescription: self.primaryFooterContent.label
                       + String(localized: " (\(self.primaryFooterAlignment.label))")]]
        }
        if self.printsFooter, self.secondaryFooterContent != .none {
            items += [[.itemName: String(localized: "Secondary Footer"),
                       .itemDescription: self.secondaryFooterContent.label
                       + String(localized: " (\(self.secondaryFooterAlignment.label))")]]
        }
        
        return items
    }
    
    
    
    // MARK: Private Methods
    
    /// cast representedObject to NSPrintInfo
    private var printInfo: NSPrintInfo? {
        
        self.representedObject as? NSPrintInfo
    }
    
    
    /// update popup menu for color setting
    private func setupColorMenu() {
        
        guard let popUpButton = self.colorPopUpButton else { return assertionFailure() }
        
        let themeNames = ThemeManager.shared.settingNames
        
        // build popup button
        popUpButton.removeAllItems()
        
        popUpButton.addItem(withTitle: ThemeName.blackAndWhite)
        
        popUpButton.menu?.addItem(.separator())
        popUpButton.menu?.addItem(.sectionHeader(title: String(localized: "Theme")))
        
        for themeName in themeNames {
            popUpButton.addItem(withTitle: themeName)
        }
        
        // select menu item
        if themeNames.contains(self.theme) {
            popUpButton.selectItem(withTitle: self.theme)
        } else {
            popUpButton.selectItem(at: 0)  // -> select "Black and White"
        }
    }
    
    
    /// Set up pop-up button for header/footer print info.
    /// - Parameters:
    ///   - popUpButton: The pop-up button to set up.
    ///   - contentKey: The default key for binding to set the option.
    ///   - enablingKey: The default key for binding to enable the button.
    private func setup(popUpButton: NSPopUpButton, contentKey: String, enablingKey: String) {
        
        popUpButton.menu?.items = PrintInfoType.menuItems
        popUpButton.bind(.selectedTag, to: self, withKeyPath: contentKey)
        popUpButton.bind(.enabled, to: self, withKeyPath: enablingKey)
    }
    
    
    
    // MARK: Setting Accessors
    
    /// print theme
    @objc dynamic var fontSize: CGFloat {
        
        get { self.printInfo?[.fontSize] ?? 0 }
        set { self.printInfo?[.fontSize] = newValue }
    }
    
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
    @objc dynamic var printsLineNumbers: Bool {
        
        get { self.printInfo?[.printsLineNumbers] ?? false }
        set { self.printInfo?[.printsLineNumbers] = newValue }
    }
    
    
    /// whether draws invisible characters
    @objc dynamic var printsInvisibles: Bool {
        
        get { self.printInfo?[.printsInvisibles] ?? false }
        set { self.printInfo?[.printsInvisibles] = newValue }
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
