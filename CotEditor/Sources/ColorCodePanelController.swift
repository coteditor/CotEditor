//
//  ColorPanelController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2014-04-22.
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
import ColorCode

@objc protocol ColorCodeReceiver: AnyObject {
    
    func insertColorCode(_ sender: ColorCodePanelController)
}


final class ColorCodePanelController: NSViewController, NSWindowDelegate {
    
    // MARK: Public Properties
    
    static let shared: ColorCodePanelController = NSStoryboard(name: "ColorCodePanelAccessory").instantiateInitialController()!
    
    @objc private(set) dynamic var colorCode: String = ""
    
    
    // MARK: Private Properties
    
    private let stylesheetColorList: NSColorList = KeywordColor.stylesheetColors
        .reduce(into: NSColorList(name: "Stylesheet Keywords".localized)) { $0.setColor(NSColor(hex: $1.value)!, forKey: $1.keyword) }
    
    private weak var panel: NSColorPanel?
    
    
    
    // MARK: -
    // MARK: Window Delegate
    
    func windowWillClose(_ notification: Notification) {
        
        guard let panel = notification.object as? NSColorPanel else { return assertionFailure() }
        
        panel.detachColorList(self.stylesheetColorList)
        panel.showsAlpha = false
        panel.delegate = nil
        panel.setAction(nil)
        panel.setTarget(nil)
        panel.accessoryView = nil
    }
    
    
    
    // MARK: Public Methods
    
    /// Show the shared color panel with the color code accessory.
    func showWindow() {
        
        // setup the shared color panel
        let panel = NSColorPanel.shared
        panel.attachColorList(self.stylesheetColorList)
        panel.showsAlpha = true
        panel.delegate = self
        panel.setAction(#selector(updateCode))
        panel.setTarget(self)
        panel.accessoryView = self.view
        
        // make position of accessory view center
        self.view.translatesAutoresizingMaskIntoConstraints = false
        if let superview = panel.accessoryView?.superview {
            NSLayoutConstraint.activate([
                superview.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                superview.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            ])
        }
        
        self.panel = panel
        self.updateCode(self)
        
        panel.orderFront(self)
    }
    
    
    /// Set color to color panel with color code.
    ///
    /// - Parameter code: The color code of the color to set.
    func setColor(code: String) {
        
        var codeType: ColorCodeType?
        guard let color = NSColor(colorCode: code, type: &codeType) else { return }
        
        self.selectedCodeType = codeType ?? .hex
        self.panel?.color = color
    }
    
    
    
    // MARK: Action Messages
    
    /// insert color code to the selection of the frontmost document
    @IBAction func insertCodeToDocument(_ sender: Any?) {
        
        guard
            !self.colorCode.isEmpty,
            NSApp.sendAction(#selector(ColorCodeReceiver.insertColorCode), to: nil, from: self)
        else { return NSSound.beep() }
    }
    
    
    /// set color from the color code field in the panel
    @IBAction func applayColorCode(_ sender: Any?) {
        
        self.setColor(code: self.colorCode)
    }
    
    
    /// update color code in the field
    @IBAction func updateCode(_ sender: Any?) {
        
        let codeType = self.selectedCodeType
        
        guard var code = self.panel?.color.usingColorSpace(.genericRGB)?.colorCode(type: codeType) else { return assertionFailure() }
        
        // keep lettercase if current Hex code is uppercase
        if (codeType == .hex || codeType == .shortHex), self.colorCode.range(of: "^#[0-9A-F]{1,6}$", options: .regularExpression) != nil {
            code = code.uppercased()
        }
        
        self.colorCode = code
    }
    
    
    
    // MARK: Private Accessors
    
    /// current color code type selection
    private var selectedCodeType: ColorCodeType {
        
        get { ColorCodeType(rawValue: UserDefaults.standard[.colorCodeType]) ?? .hex }
        set { UserDefaults.standard[.colorCodeType] = newValue.rawValue }
    }
}
