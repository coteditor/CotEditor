//
//  ColorCodePanelController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2014-04-22.
//
//  ---------------------------------------------------------------------------
//
//  © 2014-2026 1024jp
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
import ColorCode
import Defaults

@objc protocol ColorCodeReceiver: AnyObject {
    
    /// Inserts the color code into the receiver.
    ///
    /// - Parameter colorCode: The color code to insert.
    @MainActor func insertColorCode(_ colorCode: String)
}


@MainActor final class ColorCodePanelController: NSObject, NSWindowDelegate {
    
    static let shared = ColorCodePanelController()
    
    
    // MARK: Private Properties
    
    private let stylesheetColorList: NSColorList = KeywordColor.stylesheetColors
        .reduce(into: NSColorList(name: String(localized: "Stylesheet Keywords", table: "ColorCode", comment: "color list name"))) { list, color in
            list.setColor(NSColor(hex: color.value)!, forKey: color.keyword)
        }
    
    
    // MARK: Window Delegate
    
    func windowWillClose(_ notification: Notification) {
        
        guard let panel = notification.object as? NSColorPanel else { return assertionFailure() }
        
        panel.detachColorList(self.stylesheetColorList)
        panel.showsAlpha = false
        panel.delegate = nil
        panel.accessoryView = nil
    }
    
    
    // MARK: Public Methods
    
    /// Shows the color panel with the color code accessory.
    ///
    /// - Parameter colorCode: The color code of the color to set to the panel.
    func showWindow(colorCode: String? = nil) {
        
        // setup the shared color panel
        let panel = NSColorPanel.shared
        panel.attachColorList(self.stylesheetColorList)
        panel.showsAlpha = true
        panel.delegate = self
        
        var initialColorCode = ""
        var type: ColorCodeType?
        if let colorCode, let color = NSColor(colorCode: colorCode, type: &type), let type {
            initialColorCode = colorCode
            UserDefaults.standard[.colorCodeType] = type.rawValue
            panel.color = color
        }
        
        let accessory = ColorCodePanelAccessory(colorCode: initialColorCode, panel: panel)
            .padding((ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 27) ? .top : .all, 10)
        let view = NSHostingView(rootView: accessory)
        view.translatesAutoresizingMaskIntoConstraints = false
        panel.accessoryView = view
        
        // make position of accessory view center
        if let superview = view.superview {
            NSLayoutConstraint.activate([
                superview.topAnchor.constraint(equalTo: view.topAnchor),
                superview.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                superview.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                superview.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            ])
        }
        
        panel.orderFront(self)
    }
}


// MARK: -

private struct ColorCodePanelAccessory: View {
    
    @State var colorCode: String
    var panel: NSColorPanel
    
    @AppStorage(.colorCodeType) private var type: Int
    
    
    // MARK: View
    
    var body: some View {
        
        VStack {
            TextField(.init("Color Code", table: "ColorCode", comment: "noun; placeholder"), text: $colorCode)
                .font(.system(size: 14, design: .monospaced))
                .multilineTextAlignment(.center)
                .onSubmit {
                    self.apply()
                }
            
            HStack(alignment: .firstTextBaseline) {
                Picker(selection: $type) {
                    Section {
                        ForEach(ColorCodeType.hexTypes, id: \.self) { type in
                            Text(type.label).tag(type.rawValue)
                        }
                    }
                    Section {
                        ForEach(ColorCodeType.cssTypes, id: \.self) { type in
                            Text(type.label).tag(type.rawValue)
                        }
                    }
                } label: {
                    EmptyView()
                }
                .onChange(of: self.type) {
                    self.updateColorCode(for: self.panel.color)
                }
                .labelsVisibility(.hidden)
                .buttonSizing(.flexible)
                
                Button(.init("Action.insert.label", defaultValue: "Insert"), action: self.submit)
                    .keyboardShortcut(.defaultAction)
            }
            .controlSize(.small)
        }
        .onReceive(self.panel.publisher(for: \.color)) { color in
            guard self.updateColorCode(for: color) else { return assertionFailure() }
        }
    }
    
    
    // MARK: Private Methods
    
    /// Inserts the color code to the selection of the frontmost document.
    private func submit() {
        
        guard
            self.apply(),
            NSApp.sendAction(#selector((any ColorCodeReceiver).insertColorCode), to: nil, from: self.colorCode)
        else { return NSSound.beep() }
    }
    
    
    /// Sets the color representing the color code to the color panel and selects the corresponding color code type.
    ///
    /// - Returns: `true` if the given code represents a color; otherwise, `false`.
    @discardableResult private func apply() -> Bool {
        
        var type: ColorCodeType?
        guard
            let color = NSColor(colorCode: self.colorCode, type: &type),
            let type
        else { return false }
        
        self.panel.color = color
        self.type = type.rawValue
        
        return true
    }
    
    
    /// Updates the color code in the selected type, falling back to hexadecimal if no CSS keyword matches.
    ///
    /// - Parameter color: The color to represent.
    /// - Returns: `true` if the color code was updated; otherwise, `false`.
    @discardableResult private func updateColorCode(for color: NSColor) -> Bool {
        
        guard let color = color.usingColorSpace(.genericRGB) else { return false }
        
        var type = ColorCodeType(rawValue: self.type) ?? .hex
        var colorCode = color.colorCode(type: type)
        
        if colorCode == nil, type == .cssKeyword {
            type = .hex
            colorCode = color.colorCode(type: type)
        }
        
        guard var colorCode else { return false }
        
        // keep letter case
        if ColorCodeType.hexTypes.contains(type), self.colorCode.contains(where: \.isUppercase) {
            colorCode = colorCode.uppercased()
        }
        
        if self.type != type.rawValue {
            self.type = type.rawValue
        }
        self.colorCode = colorCode
        
        return true
    }
}


private extension ColorCodeType {
    
    /// The localized name of the color code type.
    var label: LocalizedStringResource {
        
        switch self {
            case .hex:
                .init("ColorCodeType.hex.label",
                      defaultValue: "Hexadecimal",
                      table: "ColorCode")
            case .hexWithAlpha:
                .init("ColorCodeType.hexWithAlpha.label",
                      defaultValue: "Hexadecimal with Alpha",
                      table: "ColorCode")
            case .shortHex:
                .init("ColorCodeType.shortHex.label",
                      defaultValue: "Hexadecimal (Short)",
                      table: "ColorCode")
            case .shortHexWithAlpha:
                .init("ColorCodeType.shortHexWithAlpha.label",
                      defaultValue: "Hexadecimal with Alpha (Short)",
                      table: "ColorCode")
            case .cssRGB:
                .init("ColorCodeType.cssRGB.label",
                      defaultValue: "CSS RGB",
                      table: "ColorCode")
            case .cssRGBa:
                .init("ColorCodeType.cssRGBa.label",
                      defaultValue: "CSS RGBa",
                      table: "ColorCode")
            case .cssHSL:
                .init("ColorCodeType.cssHSL.label",
                      defaultValue: "CSS HSL",
                      table: "ColorCode")
            case .cssHSLa:
                .init("ColorCodeType.cssHSLa.label",
                      defaultValue: "CSS HSLa",
                      table: "ColorCode")
            case .cssHWB:
                .init("ColorCodeType.cssHWB.label",
                      defaultValue: "CSS HWB",
                      table: "ColorCode")
            case .cssHWBWithAlpha:
                .init("ColorCodeType.cssHWBWithAlpha.label",
                      defaultValue: "CSS HWB with Alpha",
                      table: "ColorCode")
            case .cssKeyword:
                .init("ColorCodeType.cssKeyword.label",
                      defaultValue: "CSS Keyword",
                      table: "ColorCode")
        }
    }
}


// MARK: - Preview

#Preview {
    let panel = NSColorPanel()
    panel.color = NSColor(hex: 0x006699)!
    
    return ColorCodePanelAccessory(colorCode: "#006699", panel: panel)
        .frame(width: 240)
        .scenePadding()
}
