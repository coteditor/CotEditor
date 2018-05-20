//
//  NSTextView+RoundedBackground.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-05-08.
//
//  ---------------------------------------------------------------------------
//
//  © 2018 1024jp
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

extension NSAttributedStringKey {
    
    static let roundedBackgroundColor = NSAttributedStringKey(rawValue: "roundedBackgroundColor")
}


extension NSTextView {
    
    // MARK: Public Methods
    
    /// draw rects where the same as the selected word appear
    func drawRoundedBackground(in dirtyRect: NSRect) {
        
        guard let dirtyRange = self.range(for: dirtyRect) else { return }
        
        self.layoutManager?.enumerateTemporaryAttribute(.roundedBackgroundColor, in: dirtyRange) { (value, range, _) in
            guard let color = value as? NSColor else { return }
            
            self.drawRoundedBackground(for: range, color: color)
        }
    }
    
    
    
    // MARK: Private Methods
    
    /// draw background for given range with rounded corners
    private func drawRoundedBackground(for range: NSRange, color: NSColor) {
        
        NSGraphicsContext.saveGraphicsState()
        
        color.setFill()
        
        let rects = self.boundingRects(for: range).map { self.centerScanRect($0) }
        for rect in rects {
            let corners: RectCorner = {
                switch rect {
                case _ where rects.count == 1: return .allCorners
                case rects.first:              return [.topLeft, .bottomLeft]
                case rects.last:               return [.topRight, .bottomRight]
                default:                       return []
                }
            }()
            let radius = rect.height / 4
            
            NSBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadius: radius).fill()
        }
        
        NSGraphicsContext.restoreGraphicsState()
    }
    
}
