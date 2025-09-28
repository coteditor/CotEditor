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
//  © 2023-2026 1024jp
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

public import AppKit

public final class FormPopUpButton: NSPopUpButton {
    
    @Invalidating(.display) private(set) var isHovered = false
    
    private var trackingArea: NSTrackingArea?
    
    
    public override static var cellClass: AnyClass? {
        
        get { FormPopUpButtonCell.self }
        set { _ = newValue }
    }
    
    
    public override var intrinsicContentSize: NSSize {
        
        NSSize(width: ceil(self.attributedTitle.size().width) + 44,
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
        
        let width = cellFrame.height - 6
        let x = (self.userInterfaceLayoutDirection == .rightToLeft)
                ? cellFrame.minX + 5
                : cellFrame.maxX - width - 5
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
