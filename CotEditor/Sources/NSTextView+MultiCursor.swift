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
    
    /// All ranges to insert for multiple-cursor editing.
    var insertionRanges: [NSRange] {
        
        let insertionRanges = self.insertionLocations.map { NSRange(location: $0, length: 0) }
        return ((self.selectedRanges as! [NSRange]) + insertionRanges).sorted { $0.location < $1.location }
    }
    
    
    /// Insert the same string at multiple ranges.
    ///
    /// - Parameters:
    ///   - string: The string to insert.
    ///   - replacementRanges: The ranges to insert.
    /// - Returns: Whether the insertion succeed.
    @discardableResult
    func insertText(_ string: String, replacementRanges: [NSRange]) -> Bool {
        
        assert(!replacementRanges.isEmpty)
        
        let replacementStrings = [String](repeating: string, count: replacementRanges.count)
        
        self.undoManager?.registerUndo(withTarget: self) { [selectedRanges = self.selectedRanges, insertionLocations = self.insertionLocations] target in
            target.selectedRanges = selectedRanges
            target.insertionLocations = insertionLocations
        }
        
        guard self.shouldChangeText(inRanges: replacementRanges as [NSValue], replacementStrings: replacementStrings) else { return false }
        
        let stringLength = string.nsRange.length
        let attributedString = NSAttributedString(string: string, attributes: self.typingAttributes)
        var newInsertionLocations: [Int] = []
        var offset = 0
        
        self.textStorage?.beginEditing()
        for range in replacementRanges {
            let replacementRange = NSRange(location: range.location + offset, length: range.length)
            
            self.textStorage?.replaceCharacters(in: replacementRange, with: attributedString)
            
            newInsertionLocations.append(range.location + offset + stringLength)
            
            offset += stringLength - range.length
        }
        self.textStorage?.endEditing()
        
        self.didChangeText()
        
        self.selectedRange = NSRange(location: newInsertionLocations.removeFirst(), length: 0)
        self.insertionLocations = newInsertionLocations
        
        return true
    }
    
    
    /// Remove backward at all insertionRanges when there is more than one to delete.
    ///
    /// - Returns: Whether the deletion succeed.
    func multipleDeleteBackward() -> Bool {
        
        let ranges = self.insertionRanges
        
        guard ranges.count > 1 else { return false }
        
        let deletionRanges: [NSRange] = ranges
            .map { range in
                guard range.location > 0 else { return range }
                guard range.length == 0 else { return range }
                
                if let self = self as? NSTextView & Indenting,
                    self.isAutomaticTabExpansionEnabled,
                    let indentRange = self.string.rangeForSoftTabDeletion(in: range, tabWidth: self.tabWidth)
                { return indentRange }
                
                return NSRange(location: range.location-1, length: 1)
            }
            // remove overlappings
            .map { Range<Int>($0)! }
            .reduce(into: IndexSet()) { $0.insert(integersIn: $1) }
            .rangeView
            .map { NSRange($0) }
        
        return self.insertText("", replacementRanges: deletionRanges)
    }
    
    
    /// Calculate multiple insertion points for rectangular selection.
    ///
    /// - Parameters:
    ///   - startPoint: The point where the dragging started, in view coordinates.
    ///   - candidates: The candidate ranges for selectedRanges that is passed to `setSelectedRanges(_s:affinity:stillSelecting:)`.
    /// - Returns: Locations for all insertion points.
    func insertionLocations(from startPoint: NSPoint, candidates ranges: [NSValue]) -> [Int]? {
        
        // perform only when normal recutangular selection was failed
        guard
            ranges.count == 1,
            let range = ranges.first as? NSRange
            else { return nil }
        
        guard let layoutManager = self.layoutManager else { assertionFailure(); return nil }
        
        let glyphRange = layoutManager.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
        
        var locations: [Int] = []
        layoutManager.enumerateLineFragments(forGlyphRange: glyphRange) { (_, usedRect, _, glyphRange, stop) in
            let rect = usedRect.offset(by: self.textContainerOrigin)  // to view-based
            let point = NSPoint(x: startPoint.x, y: rect.midY)
            
            guard rect.contains(point) else { return }
            
            locations.append(self.characterIndexForInsertion(at: point))
        }
        
        guard locations.count > 1 else { return nil }
        
        return locations
    }
    
    
    /// Add a new insrtion point at `point` or remove an existing if any.
    ///
    /// - Parameter point: The point where user clicked, in view coordinates.
    /// - Returns: Whether the insertion/removal succeed.
    @discardableResult
    func modifyInsertionPoint(at point: NSPoint) -> Bool {
        
        guard self.selectedRanges.allSatisfy({ $0.rangeValue.length == 0 }) else { return false }
        
        let location = self.characterIndexForInsertion(at: point)
        let emptySelectedLocations = self.selectedRanges
            .map { $0.rangeValue }
            .filter { $0.length == 0 }
            .map { $0.location }
        var locations = self.insertionLocations + emptySelectedLocations
        
        if let clicked = locations.first(where: { $0 == location }) {
            locations.remove(clicked)
        } else {
            locations.append(location)
        }
        locations.sort()
        
        guard !locations.isEmpty else { return false }
        
        self.selectedRange = NSRange(location: locations.removeFirst(), length: 0)
        self.insertionLocations = locations
        
        return true
    }
    
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
