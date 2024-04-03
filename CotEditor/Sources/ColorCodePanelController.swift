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
//  © 2014-2024 1024jp
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

@objc protocol ColorCodeReceiver: AnyObject {
    
    @MainActor func insertColorCode(_ colorCode: String)
}


@MainActor final class ColorCodePanelController: NSObject, NSWindowDelegate {
    
    static let shared = ColorCodePanelController()
    
    
    // MARK: Private Properties
    
    private let stylesheetColorList: NSColorList = KeywordColor.stylesheetColors
        .reduce(into: NSColorList(name: String(localized: "Stylesheet Keywords", table: "ColorCode", comment: "color list name"))) {
            $0.setColor(NSColor(hex: $1.value)!, forKey: $1.keyword)
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
    func showWindow(colorCode: String?) {
        
        // setup the shared color panel
        let panel = NSColorPanel.shared
        panel.attachColorList(self.stylesheetColorList)
        panel.showsAlpha = true
        panel.delegate = self
        
        let accessory = ColorCodePanelAccessory(colorCode: colorCode, panel: panel)
        let view = NSHostingView(rootView: accessory)
        panel.accessoryView = view
        
        // make position of accessory view center
        view.translatesAutoresizingMaskIntoConstraints = false
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
    
    @State private var colorCode: String = ""
    @AppStorage(.colorCodeType) private var type: Int
    
    private var panel: NSColorPanel
    
    
    // MARK: View
    
    init(colorCode: String?, panel: NSColorPanel) {
        
        self.panel = panel
        
        var type: ColorCodeType?
        if let colorCode, let color = NSColor(colorCode: colorCode, type: &type), let type {
            self.colorCode = colorCode
            self.type = type.rawValue
            Task { @MainActor in
                panel.color = color
            }
        }
    }
    
    
    var body: some View {
        
        VStack {
            TextField(String(localized: "Color Code", table: "ColorCode", comment: "placeholder"), text: $colorCode)
                .font(.system(size: 14, design: .monospaced))
                .multilineTextAlignment(.center)
                .onSubmit {
                    self.apply(colorCode: self.colorCode)
                }
            
            HStack {
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
                .onChange(of: self.type) { self.apply(type: $0) }
                .labelsHidden()
                
                Button(String(localized: "Insert", table: "ColorCode", comment: "button label")) {
                    self.submit()
                }
                .keyboardShortcut(.defaultAction)
            }.controlSize(.small)
        }
        .onReceive(self.panel.publisher(for: \.color), perform: self.apply(color:))
        .padding(EdgeInsets(top: 8, leading: 10, bottom: 16, trailing: 10))
    }
    
    
    // MARK: Private Methods
    
    /// Inserts the color code to the selection of the frontmost document.
    @MainActor private func submit() {
        
        self.apply(colorCode: self.colorCode)
        
        guard
            !self.colorCode.isEmpty,
            NSApp.sendAction(#selector((any ColorCodeReceiver).insertColorCode), to: nil, from: self.colorCode)
        else { return NSSound.beep() }
    }
    
    
    /// Sets the color representing the given code to the color panel and selects the corresponding color code type.
    ///
    /// - Parameter colorCode: The color code of the color to set.
    @MainActor private func apply(colorCode: String) {
        
        var type: ColorCodeType?
        guard
            let color = NSColor(colorCode: colorCode, type: &type),
            let type
        else { return }
        
        self.panel.color = color
        self.type = type.rawValue
    }
    
    
    /// Converts the color code to the specified code type.
    ///
    /// - Parameter rawValue: The rawValue of ColorCodeType.
    @MainActor private func apply(type rawValue: Int) {
        
        guard
            let type = ColorCodeType(rawValue: rawValue),
            let color = self.panel.color.usingColorSpace(.genericRGB),
            let colorCode = color.colorCode(type: type)
        else { return }
        
        self.colorCode = colorCode
    }
    
    
    /// Updates color code for new color.
    ///
    /// - Parameter color: The color.
    private func apply(color: NSColor) {
        
        let type = ColorCodeType(rawValue: self.type) ?? .hex
        let color = color.usingColorSpace(.genericRGB)
        
        guard var colorCode = color?.colorCode(type: type) else { return assertionFailure() }
        
        // keep letter case
        if ColorCodeType.hexTypes.contains(type), self.colorCode.contains(where: \.isUppercase) {
            colorCode = colorCode.uppercased()
        }
        
        self.colorCode = colorCode
    }
}



private extension ColorCodeType {
    
    static let hexTypes: [Self] = [.hex, .hexWithAlpha, .shortHex]
    static let cssTypes: [Self] = [.cssRGB, .cssRGBa, .cssHSL, .cssHSLa, .cssKeyword]
    
    
    var label: String {
        
        switch self {
            case .hex:
                String(localized: "ColorCodeType.hex.label",
                       defaultValue: "Hexadecimal",
                       table: "ColorCode")
            case .hexWithAlpha:
                String(localized: "ColorCodeType.hexWithAlpha.label",
                       defaultValue: "Hexadecimal with Alpha",
                       table: "ColorCode")
            case .shortHex:
                String(localized: "ColorCodeType.shortHex.label",
                       defaultValue: "Hexadecimal (Short)",
                       table: "ColorCode")
            case .cssRGB:
                String(localized: "ColorCodeType.cssRGB.label",
                       defaultValue: "CSS RGB",
                       table: "ColorCode")
            case .cssRGBa:
                String(localized: "ColorCodeType.cssRGBa.label",
                       defaultValue: "CSS RGBa",
                       table: "ColorCode")
            case .cssHSL:
                String(localized: "ColorCodeType.cssHSL.label",
                       defaultValue: "CSS HSL",
                       table: "ColorCode")
            case .cssHSLa:
                String(localized: "ColorCodeType.cssHSLa.label",
                       defaultValue: "CSS HSLa",
                       table: "ColorCode")
            case .cssKeyword:
                String(localized: "ColorCodeType.cssKeyword.label",
                       defaultValue: "CSS Keyword",
                       table: "ColorCode")
        }
    }
}



// MARK: - Preview

#Preview {
    ColorCodePanelAccessory(colorCode: "#006699", panel: .shared)
        .frame(width: 240)
}
