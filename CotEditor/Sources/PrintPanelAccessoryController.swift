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
    static let primaryHeaderContent = Self("CEPrimaryHeaderContent")
    static let secondaryHeaderContent = Self("CESecondaryHeaderContent")
    static let primaryHeaderAlignment = Self("CEPrimaryHeaderAlignment")
    static let secondaryHeaderAlignment = Self("CESecondaryHeaderAlignment")
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
        
        self.primaryHeaderPopUpButton!.menu!.items = PrintInfoType.menuItems
        self.secondaryHeaderPopUpButton!.menu!.items = PrintInfoType.menuItems
        self.primaryFooterPopUpButton!.menu!.items = PrintInfoType.menuItems
        self.secondaryFooterPopUpButton!.menu!.items = PrintInfoType.menuItems
        
        AlignmentType.setup(segmentedControl: self.primaryHeaderAlignmentControl!)
        AlignmentType.setup(segmentedControl: self.secondaryHeaderAlignmentControl!)
        AlignmentType.setup(segmentedControl: self.primaryFooterAlignmentControl!)
        AlignmentType.setup(segmentedControl: self.secondaryFooterAlignmentControl!)
    }
    
    
    /// PrintInfo did set (new print sheet will be displayed).
    override var representedObject: Any? {
        
        didSet {
            guard representedObject != nil else { return }
            
            // -> Property initialization must be done after setting representedObject, namely NSPrintInfo,
            //    because these values need to be set also to printInfo through the computed setters.
            assert(representedObject is NSPrintInfo)
            
            let defaults = UserDefaults.standard
            
            self.fontSize = defaults[.printFontSize]
            
            self.theme = defaults[.printTheme] ?? ThemeManager.shared.userDefaultSettingName
            self.printsBackground = defaults[.printBackground]
            
            self.printsLineNumbers = self.documentShowsLineNumber
            self.printsInvisibles = self.documentShowsInvisibles
            
            self.printsHeaderAndFooter = defaults[.printHeaderAndFooter]
            
            self.primaryHeaderContent = defaults[.primaryHeaderContent]
            self.primaryHeaderAlignment = defaults[.primaryHeaderAlignment]
            self.secondaryHeaderContent = defaults[.secondaryHeaderContent]
            self.secondaryHeaderAlignment = defaults[.secondaryHeaderAlignment]
            
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
    
    /// List of key paths that affect to preview.
    func keyPathsForValuesAffectingPreview() -> Set<String> {
        
        [
            #keyPath(fontSize),
            #keyPath(theme),
            #keyPath(printsBackground),
            #keyPath(printsLineNumbers),
            #keyPath(printsInvisibles),
            
            #keyPath(printsHeaderAndFooter),
            
            #keyPath(primaryHeaderContent),
            #keyPath(primaryHeaderAlignment),
            #keyPath(secondaryHeaderContent),
            #keyPath(secondaryHeaderAlignment),
            
            #keyPath(primaryFooterContent),
            #keyPath(primaryFooterAlignment),
            #keyPath(secondaryFooterContent),
            #keyPath(secondaryFooterAlignment),
        ]
    }
    
    
    /// Localized descriptions for print settings.
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
        
        if self.printsHeaderAndFooter {
            let headerItems = [self.primaryHeaderContent, self.secondaryHeaderContent].filter { $0 != .none }
            if !headerItems.isEmpty {
                items += [[.itemName: String(localized: "Header"),
                           .itemDescription: headerItems.map(\.label).formatted(.list(type: .and))]]
            }
            
            let footerItems = [self.primaryFooterContent, self.secondaryFooterContent].filter { $0 != .none }
            if !footerItems.isEmpty {
                items += [[.itemName: String(localized: "Footer"),
                           .itemDescription: footerItems.map(\.label).formatted(.list(type: .and))]]
            }
        }
        
        return items
    }
    
    
    
    // MARK: Private Methods
    
    /// Cast `representedObject` to `NSPrintInfo`.
    private var printInfo: NSPrintInfo? {
        
        self.representedObject as? NSPrintInfo
    }
    
    
    /// Update the pop-up menu for the color setting.
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
    
    
    
    // MARK: Setting Accessors
    
    /// The print font size.
    @objc dynamic var fontSize: CGFloat {
        
        get {
            self.printInfo?[.fontSize] ?? 0
        }
        
        set {
            self.printInfo?[.fontSize] = newValue
            UserDefaults.standard[.printFontSize] = newValue
        }
    }
    
    /// The theme.
    @objc dynamic var theme: String {
        
        get {
            self.printInfo?[.theme] ?? ThemeName.blackAndWhite
        }
        
        set {
            self.printInfo?[.theme] = newValue
            UserDefaults.standard[.printTheme] = newValue
        }
    }
    
    
    /// Whether prints the background color.
    @objc dynamic var printsBackground: Bool {
        
        get {
            self.printInfo?[.printsBackground] ?? true
        }
        
        set {
            self.printInfo?[.printsBackground] = newValue
            UserDefaults.standard[.printBackground] = newValue
        }
    }
    
    
    /// @hether draws line numbers.
    @objc dynamic var printsLineNumbers: Bool {
        
        get { self.printInfo?[.printsLineNumbers] ?? false }
        set { self.printInfo?[.printsLineNumbers] = newValue }
    }
    
    
    /// Whether draws invisible characters.
    @objc dynamic var printsInvisibles: Bool {
        
        get { self.printInfo?[.printsInvisibles] ?? false }
        set { self.printInfo?[.printsInvisibles] = newValue }
    }
    
    
    /// Whether prints headers and footers.
    @objc dynamic var printsHeaderAndFooter: Bool {
        
        get {
            self.printInfo?[.headerAndFooter] ?? false
        }
        
        set {
            self.printInfo?[.headerAndFooter] = newValue
            UserDefaults.standard[.printHeaderAndFooter] = newValue
        }
    }
    
    
    /// Primary header item content type.
    @objc dynamic var primaryHeaderContent: PrintInfoType {
        
        get {
            PrintInfoType(self.printInfo?[.primaryHeaderContent])
        }
        
        set {
            self.printInfo?[.primaryHeaderContent] = newValue.rawValue
            UserDefaults.standard[.primaryHeaderContent] = newValue
        }
    }
    
    
    /// Primary header item alignment.
    @objc dynamic var primaryHeaderAlignment: AlignmentType {
        
        get {
            AlignmentType(self.printInfo?[.primaryHeaderAlignment])
        }
        
        set {
            self.printInfo?[.primaryHeaderAlignment] = newValue.rawValue
            UserDefaults.standard[.primaryHeaderAlignment] = newValue
        }
    }
    
    
    /// Secondary header item content type.
    @objc dynamic var secondaryHeaderContent: PrintInfoType {
        
        get {
            PrintInfoType(self.printInfo?[.secondaryHeaderContent])
        }
        
        set {
            self.printInfo?[.secondaryHeaderContent] = newValue.rawValue
            UserDefaults.standard[.secondaryHeaderContent] = newValue
        }
    }
    
    
    /// Secondary header item alignment.
    @objc dynamic var secondaryHeaderAlignment: AlignmentType {
        
        get {
            AlignmentType(self.printInfo?[.secondaryHeaderAlignment])
        }
        
        set {
            self.printInfo?[.secondaryHeaderAlignment] = newValue.rawValue
            UserDefaults.standard[.secondaryHeaderAlignment] = newValue
        }
    }
    
    
    /// Primary footer item content type.
    @objc dynamic var primaryFooterContent: PrintInfoType {
        
        get {
            PrintInfoType(self.printInfo?[.primaryFooterContent])
        }
        
        set {
            self.printInfo?[.primaryFooterContent] = newValue.rawValue
            UserDefaults.standard[.primaryFooterContent] = newValue
        }
    }
    
    
    /// Primary footer item alignment.
    @objc dynamic var primaryFooterAlignment: AlignmentType {
        
        get {
            AlignmentType(self.printInfo?[.primaryFooterAlignment])
        }
        
        set {
            self.printInfo?[.primaryFooterAlignment] = newValue.rawValue
            UserDefaults.standard[.primaryFooterAlignment] = newValue
        }
    }
    
    
    /// Secondary footer item content type.
    @objc dynamic var secondaryFooterContent: PrintInfoType {
        
        get {
            PrintInfoType(self.printInfo?[.secondaryFooterContent])
        }
        
        set {
            self.printInfo?[.secondaryFooterContent] = newValue.rawValue
            UserDefaults.standard[.secondaryFooterContent] = newValue
        }
    }
    
    
    /// Secondary footer item alignment.
    @objc dynamic var secondaryFooterAlignment: AlignmentType {
        
        get {
            AlignmentType(self.printInfo?[.secondaryFooterAlignment])
        }
        
        set {
            self.printInfo?[.secondaryFooterAlignment] = newValue.rawValue
            UserDefaults.standard[.secondaryFooterAlignment] = newValue
        }
    }
}



// MARK: Private Extensions

private extension PrintInfoType {
    
    static var menuItems: [NSMenuItem] {
        
        [Self.none.menuItem, .separator()] + Self.allCases[1...].map(\.menuItem)
    }
    
    
    private var menuItem: NSMenuItem {
        
        let item = NSMenuItem()
        item.title = self.label
        item.tag = Self.allCases.enumerated().first { $0.element == self }?.offset ?? 0
        return item
    }
}


private extension AlignmentType {
    
    static func setup(segmentedControl: NSSegmentedControl) {
        
        for type in self.allCases {
            segmentedControl.setToolTip(type.help, forSegment: type.rawValue)
            segmentedControl.setTag(type.rawValue, forSegment: type.rawValue)
            segmentedControl.setImage(NSImage(systemSymbolName: type.symbolName, accessibilityDescription: type.help), forSegment: type.rawValue)
        }
    }
}
