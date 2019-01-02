//
//  NSTextView+MultiCursor.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-05-04.
//
//  ---------------------------------------------------------------------------
//
//  © 2018-2019 1024jp
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

protocol MultiCursorEditing: AnyObject {
    
    var insertionLocations: [Int] { get set }
}


extension MultiCursorEditing where Self: NSTextView {
    
}



@objc extension NSTextView {
    
    /// Calculate rect for insartion point at `index`.
    ///
    /// - Parameter index: The character index where the insertion point will locate.
    /// - Returns: Rect where insertion point filled.
    func insertionPointRect(at index: Int) -> NSRect {
        
        guard
            let layoutManager = self.layoutManager,
            let textContainer = self.textContainer
            else { assertionFailure(); return .zero }
        
        let glyphIndex = layoutManager.glyphIndexForCharacter(at: index)
        let boundingRect = layoutManager.boundingRect(forGlyphRange: NSRange(location: glyphIndex, length: 1), in: textContainer)
            .offset(by: self.textContainerOrigin)
        let rect = NSRect(x: floor(boundingRect.minX), y: boundingRect.minY, width: 1, height: boundingRect.height)
        
        return self.centerScanRect(rect)
    }
    
}
