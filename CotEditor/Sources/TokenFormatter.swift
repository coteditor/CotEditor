//
//  TokenFormatter.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2022-01-27.
//
//  ---------------------------------------------------------------------------
//
//  © 2022 1024jp
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

final class TokenFormatter: Formatter {
    
    // MARK: Formatter Function
    
    /// convert to plain string
    override func string(for obj: Any?) -> String? {
        
        return obj as? String
    }
    
    
    /// create attributed string from object
    override func attributedString(for obj: Any, withDefaultAttributes attrs: [NSAttributedString.Key: Any]? = nil) -> NSAttributedString? {
        
        self.string(for: obj)?
            .components(separatedBy: ", ")
            .map { NSAttributedString(attachment: .init(token: $0, attributes: attrs)) }
            .joined(separator: .init(string: " ", attributes: attrs))
    }
    
    
    override func getObjectValue(_ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?, for string: String, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        
        return false
    }
    
}



// MARK: -

private extension NSTextAttachment {
    
    convenience init(token: String, attributes: [NSAttributedString.Key: Any]? = nil) {
        
        self.init()
        
        let cell = TokenCell()
        cell.stringValue = token
        cell.attributedStringValue = NSAttributedString(string: token, attributes: attributes)
        self.attachmentCell = cell
    }
}



final private class TokenCell: NSTextAttachmentCell {
    
    // MARK: Private Properties
    
    private var tokenColor: NSColor = .quaternaryLabelColor
    
    
    // MARK: Text Attachment Cell Methods
    
    override func cellBaselineOffset() -> NSPoint {
        
        NSPoint(x: 0, y: self.font?.descender ?? 0)
    }
    
    
    override func cellSize() -> NSSize {
        
        NSRect(origin: .zero, size: self.attributedStringValue.size())
            .insetBy(dx: -2, dy: 0)
            .integral.size
    }
    
    
    override func draw(withFrame cellFrame: NSRect, in controlView: NSView?) {
        
        guard let controlView = controlView else { return }
        
        let rect = cellFrame.insetBy(dx: NSBezierPath.defaultLineWidth / 2,
                                     dy: NSBezierPath.defaultLineWidth / 2)
        let radius = cellFrame.height / 4
        let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
        
        NSGraphicsContext.saveGraphicsState()
        
        self.tokenColor.withAlphaComponent(0.2 * self.tokenColor.alphaComponent).setFill()
        self.tokenColor.setStroke()
        path.fill()
        path.stroke()
        
        self.drawInterior(withFrame: cellFrame, in: controlView)
        
        NSGraphicsContext.restoreGraphicsState()
    }
    
}
