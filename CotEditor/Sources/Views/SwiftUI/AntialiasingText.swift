//
//  AntialiasingTextField.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-05-08.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2024 1024jp
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

import SwiftUI
import AppKit

struct AntialiasingText: NSViewRepresentable {
    
    typealias NSViewType = NSTextField
    
    
    private var text: String
    private var antialiasDisabled: Bool = false
    private var font: NSFont?
    
    
    init(_ text: String) {
        
        self.text = text
    }
    
    
    func makeNSView(context: Context) -> NSTextField {
        
        let nsView = AntialiasingTextField(string: self.text)
        nsView.isEditable = false
        nsView.isSelectable = false
        nsView.alignment = .center
        nsView.lineBreakMode = .byTruncatingMiddle
        nsView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        // keep initial field height
        nsView.heightAnchor.constraint(equalToConstant: nsView.frame.height).isActive = true
        
        return nsView
    }
    
    
    func updateNSView(_ nsView: NSTextField, context: Context) {
        
        nsView.stringValue = self.text
        nsView.font = self.font
        (nsView as! AntialiasingTextField).antialiasDisabled = self.antialiasDisabled
    }
    
    
    /// Sets whether disables the antialias.
    ///
    /// - Parameter disabled: The antialias state to change.
    func antialiasDisabled(_ disabled: Bool = true) -> Self {
        
        var view = self
        view.antialiasDisabled = disabled
        return view
    }
    
    
    /// Sets the font to display.
    ///
    /// - Parameter font: The font.
    func font(nsFont font: NSFont?) -> Self {
        
        var view = self
        view.font = font
        return view
    }
}


private final class AntialiasingTextField: NSTextField {
    
    @Invalidating(.display) var antialiasDisabled = false
    
    
    override static var cellClass: AnyClass? {
        
        get { CenteringTextFieldCell.self }
        set { _ = newValue }
    }
    
    
    /// Controls antialiasing of text.
    override func draw(_ dirtyRect: NSRect) {
        
        if self.antialiasDisabled {
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current?.shouldAntialias = false
        }
        
        super.draw(dirtyRect)
        
        if self.antialiasDisabled {
            NSGraphicsContext.restoreGraphicsState()
        }
    }
}


private final class CenteringTextFieldCell: NSTextFieldCell {
    
    /// Returns the rect of the content text.
    override func titleRect(forBounds rect: NSRect) -> NSRect {
        
        var titleRect = super.titleRect(forBounds: rect)
        let titleSize = self.attributedStringValue.size()
        
        titleRect.origin.y = (rect.minY + (rect.height - titleSize.height) / 2).rounded(.up)
        titleRect.size.height = rect.height - titleRect.origin.y
        
        return titleRect
    }
    
    
    /// Draws inside of the field.
    override func drawInterior(withFrame cellFrame: NSRect, in controlView: NSView) {
        
        self.attributedStringValue.draw(in: self.titleRect(forBounds: cellFrame))
    }
}


// MARK: - Preview

#Preview(traits: .fixedLayout(width: 200, height: 400)) {
    VStack {
        AntialiasingText("Antialias Text")
            .antialiasDisabled(true)
        
        AntialiasingText("Smooth Text")
            .antialiasDisabled(false)
            .font(nsFont: .monospacedSystemFont(ofSize: 8, weight: .regular))
        
        AntialiasingText("Very Long Long Long Long Long Long Text")
    }.padding()
}
