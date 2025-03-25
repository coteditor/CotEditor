//
//  PrintPanelAccessoryController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2023-08-13.
//
//  ---------------------------------------------------------------------------
//
//  © 2023-2025 1024jp
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
import SwiftUI
import Defaults

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
    
    static let blackAndWhite = String(localized: "Black and White", table: "PrintPanelAccessory", comment: "coloring option")
}


protocol PrintAccessoryModel: ObservableObject {
    
    static var printAccessoryValueKeyPaths: [String] { get }
    
    static func label(for keyPath: String) -> String
    func valueDescription(for keyPath: String) -> String?
}


final class PrintPanelAccessoryController<ContentView, Model>: NSViewController, NSPrintPanelAccessorizing where ContentView: View, Model: PrintAccessoryModel {
    
    @nonobjc let model: Model
    @objc(model) var objCModel: AnyObject { self.model }
    let contentView: (Model) -> ContentView
    
    
    // MARK: Lifecycle
    
    @IBOutlet private weak var colorPopUpButton: NSPopUpButton?
    
    @IBOutlet private weak var primaryHeaderPopUpButton: NSPopUpButton?
    @IBOutlet private weak var secondaryHeaderPopUpButton: NSPopUpButton?
    @IBOutlet private weak var primaryFooterPopUpButton: NSPopUpButton?
    @IBOutlet private weak var secondaryFooterPopUpButton: NSPopUpButton?
    
    @IBOutlet private weak var primaryHeaderAlignmentControl: NSSegmentedControl?
    @IBOutlet private weak var secondaryHeaderAlignmentControl: NSSegmentedControl?
    @IBOutlet private weak var primaryFooterAlignmentControl: NSSegmentedControl?
    @IBOutlet private weak var secondaryFooterAlignmentControl: NSSegmentedControl?
    
    
    // MARK: View Controller Method
    
    required init(model: Model, contentView: @escaping (Model) -> ContentView) {
        
        self.model = model
        self.contentView = contentView
        
        super.init(nibName: nil, bundle: nil)
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func loadView() {
        
        let hostingView = NSHostingView(rootView: contentView(self.model))
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        
        self.view = hostingView
    }
    
    
    // MARK: Print Panel Accessorizing Methods
    
    func keyPathsForValuesAffectingPreview() -> Set<String> {
        
        Set(Model.printAccessoryValueKeyPaths.map { #keyPath(objCModel) + "." + $0 })
    }
    
    
    func localizedSummaryItems() -> [[NSPrintPanel.AccessorySummaryKey: String]] {
        
        Model.printAccessoryValueKeyPaths.compactMap {
            if let description = self.model.valueDescription(for: $0) {
                [.itemName: Model.label(for: $0),
                 .itemDescription: description]
            } else {
                nil
            }
        }
    }
    
    
    // MARK: Setting Accessors
    
    /// Casts `representedObject` to `NSPrintInfo`.
    private var printInfo: NSPrintInfo? {
        
        self.representedObject as? NSPrintInfo
    }
    
    
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
    
    
    /// Whether draws line numbers.
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
