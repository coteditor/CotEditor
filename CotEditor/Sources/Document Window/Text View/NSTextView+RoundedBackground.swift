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
//  © 2018-2025 1024jp
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

extension NSAttributedString.Key {
    
    static let roundedBackgroundColor = NSAttributedString.Key("roundedBackgroundColor")
}


extension NSTextView {
    
    // MARK: Public Methods
    
    /// Draws rounded background rects for `.roundedBackgroundColor` temporary attributes in the layout manager.
    ///
    /// - Note: This API requires TextKit 1.
    ///
    /// - Parameters:
    ///   - dirtyRange: The character range to draw.
    ///   - dirtyRect: The bounds to draw.
    final func drawRoundedBackground(range dirtyRange: NSRange, in dirtyRect: NSRect) {
        
        guard let layoutManager = self.layoutManager else { return }
        
        var coloredPaths: [NSColor: [NSBezierPath]] = [:]
        layoutManager.enumerateTemporaryAttribute(.roundedBackgroundColor, type: NSColor.self, in: dirtyRange) { (color, range, _) in
            let paths = self.roundedRectPaths(for: range)
                .filter { $0.bounds.intersects(dirtyRect) }
            
            guard !paths.isEmpty else { return }
            
            coloredPaths[color, default: []] += paths
        }
        
        guard !coloredPaths.isEmpty else { return }
        
        NSGraphicsContext.saveGraphicsState()
        
        for (color, paths) in coloredPaths {
            color.setFill()
            for path in paths {
                path.fill()
            }
        }
        
        NSGraphicsContext.restoreGraphicsState()
    }
    
    
    // MARK: Private Methods
    
    /// Returns fragment bezier paths of which a rounded rect for given range consists.
    ///
    /// - Note: This API requires TextKit 1.
    private func roundedRectPaths(for range: NSRange) -> [NSBezierPath] {
        
        let rects = self.boundingRects(for: range).map(self.centerScanRect)
        
        return rects.map { rect in
            let corners: RectCorner = switch rect {
                case _ where rects.count == 1: .allCorners
                case rects.first:              [.topLeft, .bottomLeft]
                case rects.last:               [.topRight, .bottomRight]
                default:                       []
            }
            let radius = rect.height / 4
            
            return NSBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadius: radius)
        }
    }
}
