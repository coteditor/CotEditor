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

import Cocoa
import SwiftUI
import ColorCode

@objc protocol ColorCodeReceiver: AnyObject {
    
    func insertColorCode(_ colorCode: String)
}


final class ColorCodePanelController: NSObject, NSWindowDelegate {
    
    static let shared = ColorCodePanelController()
    
    
    // MARK: Private Properties
    
    private let stylesheetColorList: NSColorList = KeywordColor.stylesheetColors
        .reduce(into: NSColorList(name: "Stylesheet Keywords".localized)) {
            $0.setColor(NSColor(hex: $1.value)!, forKey: $1.keyword)
        }
    
    
    // MARK: -
    // MARK: Window Delegate
    
    func windowWillClose(_ notification: Notification) {
        
        guard let panel = notification.object as? NSColorPanel else { return assertionFailure() }
        
        panel.detachColorList(self.stylesheetColorList)
        panel.showsAlpha = false
        panel.delegate = nil
        panel.accessoryView = nil
    }
    
    
    // MARK: Public Methods
    
    /// Show the color panel with the color code accessory.
    ///
    /// - Parameter colorCode: The color code of the color to set to the panel.
    func showWindow(colorCode: String? = nil) {
        
        // setup the shared color panel
        let panel = NSColorPanel.shared
        panel.attachColorList(self.stylesheetColorList)
        panel.showsAlpha = true
        panel.delegate = self
        
        let accessory = ColorCodePanelAccessory(colorCode: colorCode, panel: panel)
        let view = NSHostingView(rootView: accessory)
        view.ensureFrameSize()
        panel.accessoryView = view
        
        // make position of accessory view center
        view.translatesAutoresizingMaskIntoConstraints = false
        if let superview = view.superview {
            NSLayoutConstraint.activate([
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
    @AppStorage(.colorCodeType) private var colorCodeType: Int
    
    private var panel: NSColorPanel
    
    
    // MARK: View
    
    init(colorCode: String?, panel: NSColorPanel) {
        
        self.panel = panel
        
        var codeType: ColorCodeType?
        if let colorCode, let color = NSColor(colorCode: colorCode, type: &codeType), let codeType {
            self.colorCode = colorCode
            self.colorCodeType = codeType.rawValue
            panel.color = color
        }
    }
    
    
    var body: some View {
        
        VStack {
            TextField("color code", text: $colorCode)
                .font(.system(size: 14, design: .monospaced))
                .multilineTextAlignment(.center)
                .onSubmit {
                    self.apply(colorCode: self.colorCode)
                }
            
            HStack {
                Picker("", selection: $colorCodeType) {
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
                }
                .labelsHidden()
                .onChange(of: self.colorCodeType) { newValue in
                    guard
                        let type = ColorCodeType(rawValue: newValue),
                        let color = self.panel.color.usingColorSpace(.genericRGB),
                        let colorCode = color.colorCode(type: type)
                    else { return }
                    
                    self.colorCode = colorCode
                }
                
                Button("Insert", action: self.submit)
                    .keyboardShortcut(.defaultAction)
            }.controlSize(.small)
        }
        .onReceive(self.panel.publisher(for: \.color), perform: self.apply(color:))
        .padding(.top, 8)
        .padding(.horizontal, 10)
        .padding(.bottom, 16)
    }
    
    
    // MARK: Private Methods
    
    /// Insert the color code to the selection of the frontmost document.
    private func submit() {
        
        self.apply(colorCode: self.colorCode)
        
        guard
            !self.colorCode.isEmpty,
            NSApp.sendAction(#selector(ColorCodeReceiver.insertColorCode), to: nil, from: self.colorCode)
        else { return NSSound.beep() }
    }
    
    
    /// Set the color representing the given code to the color panel and select the corresponding color code type.
    ///
    /// - Parameter colorCode: The color code of the color to set.
    private func apply(colorCode: String) {
        
        var codeType: ColorCodeType?
        guard
            let color = NSColor(colorCode: colorCode, type: &codeType),
            let codeType
        else { return }
        
        self.panel.color = color
        self.colorCodeType = codeType.rawValue
    }
    
    
    /// Update color code for new color.
    ///
    /// - Parameter color: The color.
    private func apply(color: NSColor) {
        
        let codeType = ColorCodeType(rawValue: self.colorCodeType) ?? .hex
        let color = color.usingColorSpace(.genericRGB)
        
        guard var code = color?.colorCode(type: codeType) else { return assertionFailure() }
        
        // keep lettercase for current hex code
        if ColorCodeType.hexTypes.contains(codeType), self.colorCode.contains(where: \.isUppercase) {
            code = code.uppercased()
        }
        
        self.colorCode = code
    }
}



private extension ColorCodeType {
    
    static let hexTypes: [Self] = [.hex, .shortHex]
    static let cssTypes: [Self] = [.cssRGB, .cssRGBa, .cssHSL, .cssHSLa, .cssKeyword]
    
    
    var label: LocalizedStringKey {
        
        switch self {
            case .hex:
                return "Hexadecimal"
            case .shortHex:
                return "Hexadecimal (short)"
            case .cssRGB:
                return "CSS RGB"
            case .cssRGBa:
                return "CSS RGBa"
            case .cssHSL:
                return "CSS HSL"
            case .cssHSLa:
                return "CSS HSLa"
            case .cssKeyword:
                return "CSS Keyword"
        }
    }
}



// MARK: - Preview

struct ColorCodePanelAccessory_Previews: PreviewProvider {

    static var previews: some View {

        ColorCodePanelAccessory(colorCode: "#006699", panel: .shared)
            .frame(width: 240)
    }
}
