//
//  FormPopUpButton.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2023-10-19.
//
//  ---------------------------------------------------------------------------
//
//  © 2023-2024 1024jp
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

final class FormPopUpButton: NSPopUpButton {
    
    @Invalidating(.display) private(set) var isHovered = false
    
    
    override class var cellClass: AnyClass? {
        
        get { FormPopUpButtonCell.self }
        set { _ = newValue }
    }
    
    
    override var intrinsicContentSize: NSSize {
        
        NSSize(width: self.attributedTitle.size().width + 32,
               height: super.intrinsicContentSize.height)
    }
    
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        self.addTrackingRect(self.bounds, owner: self, userData: nil, assumeInside: true)
    }
    
    
    override func mouseEntered(with event: NSEvent) {
        
        super.mouseEntered(with: event)
        
        self.isHovered = true
    }
    
    
    override func mouseExited(with event: NSEvent) {
        
        super.mouseExited(with: event)
        
        self.isHovered = false
    }
}



final class FormPopUpButtonCell: NSPopUpButtonCell {
    
    override func drawBorderAndBackground(withFrame cellFrame: NSRect, in controlView: NSView) {
        
        if self.isEnabled, (controlView as? FormPopUpButton)?.isHovered == true {
            return super.drawBorderAndBackground(withFrame: cellFrame, in: controlView)
        }
        
        let width: Double = 16
        let x = (self.userInterfaceLayoutDirection == .rightToLeft)
            ? cellFrame.minX + 6
            : cellFrame.maxX - width - 6
        let rect = NSRect(x: x, y: cellFrame.minY + 3,
                          width: width, height: cellFrame.height - 9)
        let appearance = controlView.effectiveAppearance
        
        // draw capsule
        let fillPath = NSBezierPath(roundedRect: rect, xRadius: 4, yRadius: 4)
        if self.isEnabled, !appearance.isDark, appearance.isHighContrast {
            NSGradient(starting: .init(white: 0.4, alpha: 1), ending: .init(white: 0.3, alpha: 1))!
                .draw(in: fillPath, angle: 90)
        } else {
            let fillColor: NSColor = switch (appearance.isHighContrast, appearance.isDark, self.isEnabled) {
                case (false, false, true): .quaternarySystemFill
                case (false, false, false): .quinarySystemFill
                case (false, true, true): .tertiarySystemFill
                case (false, true, false): .quaternarySystemFill
                case (true, false, true): preconditionFailure()  // gradient
                case (true, false, false): .windowBackgroundColor  // not exactly same
                case (true, true, true): .labelColor
                case (true, true, false): .tertiarySystemFill  // not exactly same
            }
            
            fillColor.setFill()
            fillPath.fill()
        }
        
        if appearance.isHighContrast {
            let strokeColor: NSColor = self.isEnabled ? .labelColor : .quaternaryLabelColor
            
            strokeColor.setStroke()
            NSBezierPath(roundedRect: rect.insetBy(dx: -0.5, dy: -0.5), xRadius: 4.5, yRadius: 4.5).stroke()
        }
        
        // draw chevron
        let chevron: NSImage = .chevronUpChevronDownNarrow
        let chevronColor: NSColor = switch (appearance.isHighContrast, self.isEnabled) {
            case (false, true): .controlTextColor
            case (false, false): .disabledControlTextColor
            case (true, true): appearance.isDark ? .black : .selectedMenuItemTextColor
            case (true, false): .tertiaryLabelColor
        }
        chevron.tinted(with: chevronColor)
            .draw(in: rect.insetBy(dx: (rect.width - chevron.size.width) / 2,
                                   dy: (rect.height - chevron.size.height) / 2))
    }
}



// MARK: - Preview

@available(macOS 14, *)
#Preview("Enabled") {
    let button = FormPopUpButton()
    button.addItem(withTitle: "Inu dog")
    
    return button
}

@available(macOS 14, *)
#Preview("Disabled") {
    let button = FormPopUpButton()
    button.addItem(withTitle: "Inu dog")
    button.isEnabled = false
    
    return button
}
