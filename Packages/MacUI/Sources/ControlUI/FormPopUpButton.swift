//
//  FormPopUpButton.swift
//  ControlUI
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2023-10-19.
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

public final class FormPopUpButton: NSPopUpButton {
    
    @Invalidating(.display) private(set) var isHovered = false
    
    private var trackingArea: NSTrackingArea?
    
    
    public override static var cellClass: AnyClass? {
        
        get { FormPopUpButtonCell.self }
        set { _ = newValue }
    }
    
    
    public override var intrinsicContentSize: NSSize {
        
        let dx: Double = if #available(macOS 26, *) { 44 } else { 32 }
        
        return NSSize(width: ceil(self.attributedTitle.size().width) + dx,
               height: super.intrinsicContentSize.height)
    }
    
    
    public override func updateTrackingAreas() {
        
        super.updateTrackingAreas()
        
        if let trackingArea {
            self.removeTrackingArea(trackingArea)
        }
        
        let area = NSTrackingArea(rect: self.bounds, options: [.mouseEnteredAndExited, .activeAlways], owner: self)
        self.addTrackingArea(area)
        self.trackingArea = area
    }
    
    
    public override func mouseEntered(with event: NSEvent) {
        
        super.mouseEntered(with: event)
        
        self.isHovered = true
    }
    
    
    public override func mouseExited(with event: NSEvent) {
        
        super.mouseExited(with: event)
        
        self.isHovered = false
    }
    
    
    public override func willOpenMenu(_ menu: NSMenu, with event: NSEvent) {
        
        super.willOpenMenu(menu, with: event)
        
        self.isHovered = false
    }
}


public final class FormPopUpButtonCell: NSPopUpButtonCell {
    
    public override func drawBezel(withFrame cellFrame: NSRect, in controlView: NSView) {
        
        if self.isEnabled, (controlView as? FormPopUpButton)?.isHovered == true {
            return super.drawBezel(withFrame: cellFrame, in: controlView)
        }
        
        guard #available(macOS 26, *) else {
            return self.drawLegacyBezel(withFrame: cellFrame, in: controlView)
        }
        
        let width = cellFrame.height - 6
        let x = (self.userInterfaceLayoutDirection == .rightToLeft)
                ? cellFrame.minX + 3.5
                : cellFrame.maxX - width - 3.5
        let rect = NSRect(x: x, y: cellFrame.minY + 3, width: width, height: width)
        
        // draw capsule
        let path = NSBezierPath(ovalIn: rect)
        let fillColor: NSColor = self.isEnabled ? .secondarySystemFill : .quaternarySystemFill
        let labelColor: NSColor = self.isEnabled ? .labelColor : .tertiaryLabelColor
        
        fillColor.setFill()
        path.fill()
        
        if NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast {
            labelColor.setStroke()
            path.stroke()
        }
        
        // draw chevron
        let chevron = NSImage(resource: ImageResource(name: "chevron.up.chevron.down.narrow", bundle: .module))
        chevron.tinted(with: labelColor)
            .draw(in: rect.insetBy(dx: (rect.width - chevron.size.width) / 2,
                                   dy: (rect.height - chevron.size.height) / 2))
    }
    
    
    @available(macOS, deprecated: 26)
    private func drawLegacyBezel(withFrame cellFrame: NSRect, in controlView: NSView) {
        
        let width: Double = 16
        let x = (self.userInterfaceLayoutDirection == .rightToLeft)
            ? cellFrame.minX + 6
            : cellFrame.maxX - width - 6
        let rect = NSRect(x: x, y: cellFrame.minY + 3,
                          width: width, height: cellFrame.height - 9)
        let isDark = controlView.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
        let isHighContrast = NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
        
        // draw capsule
        let fillPath = NSBezierPath(roundedRect: rect, xRadius: 4, yRadius: 4)
        if self.isEnabled, !isDark, isHighContrast {
            NSGradient(starting: .init(white: 0.4, alpha: 1), ending: .init(white: 0.3, alpha: 1))!
                .draw(in: fillPath, angle: 90)
        } else {
            let fillColor: NSColor = switch (isHighContrast, isDark, self.isEnabled) {
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
        
        if isHighContrast {
            let strokeColor: NSColor = self.isEnabled ? .labelColor : .quaternaryLabelColor
            
            strokeColor.setStroke()
            NSBezierPath(roundedRect: rect.insetBy(dx: -0.5, dy: -0.5), xRadius: 4.5, yRadius: 4.5).stroke()
        }
        
        // draw chevron
        let chevron = NSImage(resource: ImageResource(name: "chevron.up.chevron.down.narrow.legacy", bundle: .module))
        let chevronColor: NSColor = switch (isHighContrast, self.isEnabled) {
            case (false, true): .controlTextColor
            case (false, false): .disabledControlTextColor
            case (true, true): isDark ? .black : .selectedMenuItemTextColor
            case (true, false): .tertiaryLabelColor
        }
        chevron.tinted(with: chevronColor)
            .draw(in: rect.insetBy(dx: (rect.width - chevron.size.width) / 2,
                                   dy: (rect.height - chevron.size.height) / 2))
    }
}


// MARK: - Preview

#Preview("Enabled", traits: .fixedLayout(width: 200, height: 100)) {
    let button = FormPopUpButton()
    button.addItems(withTitles: ["Dog", "Cow", "Dogcow"])
    
    return button
}

#Preview("Disabled", traits: .fixedLayout(width: 200, height: 100)) {
    let button = FormPopUpButton()
    button.addItems(withTitles: ["Dog", "Cow", "Dogcow"])
    button.isEnabled = false
    
    return button
}
