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

extension NSAttributedString.Key {
    
    static let roundedBackgroundColor = NSAttributedString.Key(rawValue: "roundedBackgroundColor")
}


extension NSTextView {
    
    // MARK: Public Methods
    
    /// draw rounded background rects for .roundedBackgroundColor temporary attributes in the layoutManager
    func drawRoundedBackground(in dirtyRect: NSRect) {
        
        // avoid invoking heavy-duty `range(for:)` as possible
        guard
            let layoutManager = self.layoutManager,
            let dirtyRange = self.range(for: dirtyRect),
            layoutManager.hasTemporaryAttribute(for: .roundedBackgroundColor, in: dirtyRange)
            else { return }
        
        NSGraphicsContext.saveGraphicsState()
        
        layoutManager.enumerateTemporaryAttribute(.roundedBackgroundColor, in: dirtyRange) { (value, range, _) in
            guard let color = value as? NSColor else { return }
            
            color.setFill()
            self.roundedRectPaths(for: range).forEach { $0.fill() }
        }
        
        NSGraphicsContext.restoreGraphicsState()
    }
    
    
    
    // MARK: Private Methods
    
    /// return fragment bezier paths of which a rounded rect for given range consists.
    private func roundedRectPaths(for range: NSRange) -> [NSBezierPath] {
        
        let rects = self.boundingRects(for: range).map { self.centerScanRect($0) }
        
        return rects.map { rect in
            let corners: RectCorner = {
                switch rect {
                case _ where rects.count == 1: return .allCorners
                case rects.first:              return [.topLeft, .bottomLeft]
                case rects.last:               return [.topRight, .bottomRight]
                default:                       return []
                }
            }()
            let radius = rect.height / 4
            
            return NSBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadius: radius)
        }
    }
    
}
