//
//  UnicodeInputViewController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2014-05-06.
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

final class UnicodeInputViewController: NSViewController {
    
    // MARK: Private Properties
    
    private let completionHandler: (_ character: Character) -> Void
    
    private var character: Character?
    
    @objc private dynamic var codePoint: String = ""  { didSet { self.validateCodePoint() } }
    
    @objc private dynamic var pictureString: String?
    @objc private dynamic var unicodeName: String?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    /// Initialize view from a storyboard with given values.
    ///
    /// - Parameters:
    ///   - coder: The coder to instantiate the view from a storyboard.
    ///   - completionHandler: The callback method to perform when the command was accepted.
    init?(coder: NSCoder, completionHandler: @escaping (_ character: Character) -> Void) {
        
        self.completionHandler = completionHandler
        
        super.init(coder: coder)
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        self.view.window?.initialFirstResponder = self.view.subviews.first { ($0 as? NSTextField)?.isEditable == true }
    }
    
    
    
    // MARK: Action Messages
    
    /// Input Unicode character to the parent text view.
    @IBAction func insertToDocument(_ sender: Any?) {
        
        guard let character = self.character else { return NSSound.beep() }
        
        self.completionHandler(character)
        self.codePoint = ""
        
        if let codePoint = character.unicodeScalars.first?.codePoint {
            UserDefaults.standard[.unicodeHistory].appendUnique(codePoint, maximum: 10)
        }
    }
    
    
    /// Insert a code point to the field
    @IBAction func insertCodePoint(_ sender: NSMenuItem) {
        
        guard let codePoint = sender.representedObject as? String else { return assertionFailure() }
        
        self.codePoint = codePoint
    }
    
    
    @IBAction func clearRecents(_ sender: Any?) {
        
        UserDefaults.standard[.unicodeHistory].removeAll()
    }
    
    
    
    // MARK: Private Methods
    
    private func validateCodePoint() {
        
        let longChar = UTF32.CodeUnit(codePoint: self.codePoint)
        
        self.character = longChar
            .flatMap { Unicode.Scalar($0) }
            .map { Character($0) }
        
        self.pictureString = (self.character?.isNewline == true) ? " " : self.character.map { String($0) }
        self.unicodeName = longChar?.unicodeName
    }

}


extension UnicodeInputViewController: NSMenuDelegate {
    
    func menuNeedsUpdate(_ menu: NSMenu) {
        
        menu.items.removeAll()
        menu.addItem(.init())  // dummy item
        menu.addItem(withTitle: "Recents".localized, action: nil, keyEquivalent: "")
            .isEnabled = false
        
        guard !UserDefaults.standard[.unicodeHistory].isEmpty else { return }
        
        let font = NSFont.monospacedDigitSystemFont(ofSize: menu.font?.pointSize ?? 0, weight: .regular)
        let paragraphStyle = NSParagraphStyle.default.mutable
        paragraphStyle.tabStops = []
        paragraphStyle.defaultTabInterval = 8 * font.width(of: "0")
        
        menu.items += UserDefaults.standard[.unicodeHistory]
            .compactMap(UTF32.CodeUnit.init(codePoint:))
            .compactMap(UnicodeScalar.init)
            .map {
                let item = NSMenuItem()
                item.attributedTitle = [
                    NSAttributedString(string: $0.codePoint + "\t",
                                       attributes: [.font: font,
                                                    .paragraphStyle: paragraphStyle]),
                    NSAttributedString(string: $0.name ?? "Invalid code".localized,
                                       attributes: [.foregroundColor: NSColor.secondaryLabelColor,
                                                    .font: NSFont.menuFont(ofSize: NSFont.smallSystemFontSize)]),
                ].joined()
                item.representedObject = $0.codePoint
                item.action = #selector(insertCodePoint)
                item.target = self
                return item
            }
            .reversed()
        menu.addItem(.separator())
        menu.addItem(withTitle: "Clear Recents".localized, action: #selector(clearRecents), keyEquivalent: "")
    }
    
}



// MARK: Private Extensions

private extension UTF32.CodeUnit {
    
    /// Initialize from a possible Unicode code point representation, such as `U+1F600`, `1f600`, and `0x1F600`.
    init?(codePoint: String) {
        
        guard let range = codePoint.range(of: "(?<=^(U\\+|0x|\\\\u)?)[0-9a-f]{1,5}$",
                                          options: [.regularExpression, .caseInsensitive]) else { return nil }
        let hexString = codePoint[range]
        
        self.init(hexString, radix: 16)
    }
    
}
