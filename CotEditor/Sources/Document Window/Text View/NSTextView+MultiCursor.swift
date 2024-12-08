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
//  © 2018-2024 1024jp
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

@MainActor protocol MultiCursorEditing: NSTextView {
    
    var insertionLocations: [Int] { get set }
    var selectionOrigins: [Int] { get set }
    var isPerformingRectangularSelection: Bool { get }
    var insertionIndicators: [NSTextInsertionIndicator] { get set }
}


extension MultiCursorEditing {
    
    /// Whether the receiver has multiple points to insert text.
    var hasMultipleInsertions: Bool {
        
        (self.insertionLocations.count + self.selectedRanges.count) > 1
    }
    
    
    /// All ranges to insert for multiple-cursor editing.
    var insertionRanges: [NSRange] {
        
        let selectedRanges = self.selectedRanges.map(\.rangeValue)
        let insertionRanges = self.insertionLocations.map { NSRange(location: $0, length: 0) }
        
        return (selectedRanges + insertionRanges).sorted()
    }
    
    
    /// Inserts the same string at multiple ranges.
    ///
    /// - Parameters:
    ///   - string: The string to insert.
    ///   - replacementRanges: The ranges to insert.
    /// - Returns: Whether the insertion succeed.
    @discardableResult
    func insertText(_ string: String, replacementRanges: [NSRange]) -> Bool {
        
        assert(!replacementRanges.isEmpty)
        
        let replacementStrings = [String](repeating: string, count: replacementRanges.count)
        
        self.setSelectedRangesWithUndo(self.insertionRanges)
        
        guard self.shouldChangeText(inRanges: replacementRanges as [NSValue], replacementStrings: replacementStrings) else { return false }
        
        let attributedString = NSAttributedString(string: string, attributes: self.typingAttributes)
        let stringLength = attributedString.length
        var newInsertionLocations: [Int] = []
        var offset = 0
        
        self.textStorage?.beginEditing()
        for range in replacementRanges {
            self.textStorage?.replaceCharacters(in: range.shifted(by: offset), with: attributedString)
            
            newInsertionLocations.append(range.location + offset + stringLength)
            
            offset += stringLength - range.length
        }
        self.textStorage?.endEditing()
        
        self.didChangeText()
        
        self.setSelectedRangesWithUndo(newInsertionLocations.map { NSRange(location: $0, length: 0) })
        
        return true
    }
    
    
    /// Removes characters at all insertionRanges when there is more than one to delete.
    ///
    /// - Parameter forward: Perform the forward delete when the flag raised; otherwise, delete backward.
    /// - Returns: Whether the deletion succeed.
    func multipleDelete(forward: Bool = false) -> Bool {
        
        let ranges = self.insertionRanges
        
        guard ranges.count > 1 else { return false }
        
        let deletionRanges: [NSRange] = ranges
            .map { range -> NSRange in
                guard range.location > 0 else { return range }
                guard range.isEmpty else { return range }
                
                if !forward,
                   let self = self as? any Indenting,
                   self.isAutomaticTabExpansionEnabled,
                   let indentRange = self.string.rangeForSoftTabDeletion(in: range, tabWidth: self.tabWidth)
                { return indentRange }
                
                let location = forward ? range.location : range.location - 1
                
                return (self.string as NSString).rangeOfComposedCharacterSequence(at: location)
            }
            // remove overlappings
            .compactMap(Range.init)
            .reduce(into: IndexSet()) { $0.insert(integersIn: $1) }
            .rangeView
            .map(NSRange.init)
        
        return self.insertText("", replacementRanges: deletionRanges)
    }
    
    
    /// Calculates multiple insertion points for rectangular selection.
    ///
    /// - Note: This API requires TextKit 1.
    ///
    /// - Parameters:
    ///   - startPoint: The point where the dragging started, in view coordinates.
    ///   - candidates: The candidate ranges for selectedRanges that is passed to `setSelectedRanges(_s:affinity:stillSelecting:)`.
    ///   - affinity: The selection affinity for the selection.
    /// - Returns: Locations for all insertion points.
    func insertionLocations(from startPoint: NSPoint, candidates ranges: [NSValue], affinity: NSSelectionAffinity) -> [Int]? {
        
        // perform only when normal rectangular selection was failed
        guard
            ranges.count == 1,
            let range = ranges.first as? NSRange
        else { return nil }
        
        guard let layoutManager = self.layoutManager else { assertionFailure(); return nil }
        
        let startIndex = self.characterIndexForInsertion(at: startPoint)
        let numberOfRows = layoutManager.numberOfWrappedRows(at: startIndex, affinity: affinity)
        
        // possibility of the very last insertion point in the extra line fragment
        var containsLastLine = {
            guard
                range.upperBound == self.string.length,
                layoutManager.extraLineFragmentTextContainer != nil,
                let window
            else { return false }
            
            let pointInWindow = window.convertPoint(fromScreen: NSEvent.mouseLocation)
            let endPoint = self.convert(pointInWindow, from: nil)
            
            return layoutManager.extraLineFragmentUsedRect.maxY < endPoint.y
        }()
        
        let lineStartRange = (self.string as NSString).lineStartIndex(at: range.location)
        
        var locations: [Int] = []
        (self.string as NSString).enumerateSubstrings(in: NSRange(lineStartRange..<range.upperBound), options: [.byLines, .substringNotRequired]) { [unowned self] (_, lineRange, _, _) in
            let glyphRange = layoutManager.glyphRange(forCharacterRange: lineRange, actualCharacterRange: nil)
            
            var count = 0
            layoutManager.enumerateLineFragments(forGlyphRange: glyphRange) { [unowned self] (_, usedRect, _, lineGlyphRange, stop) in
                guard count == numberOfRows else {
                    count += 1
                    return
                }
                
                let rect = usedRect.offset(by: self.textContainerOrigin)  // to view-based
                let point = NSPoint(x: startPoint.x, y: rect.midY)
                
                guard rect.contains(point) else { return }
                
                let index = self.characterIndexForInsertion(at: point)
                
                // -> The extra line fragment can be an insertion point
                //    only when the other locations are at the line heads.
                if containsLastLine {
                    let glyphIndex = layoutManager.glyphIndexForCharacter(at: index)
                    containsLastLine = (glyphIndex == lineGlyphRange.lowerBound)
                }
                
                locations.append(index)
                
                stop.pointee = true
            }
        }
        
        if containsLastLine {
            locations.append(self.string.length)
        }
        
        guard locations.count > 0 else { return nil }
        
        return locations
    }
    
    
    /// Sanitizes and divide selection ranges candidate to ones to set to the proper `selectionRanges` and `insertionLocations`.
    ///
    /// - Parameter ranges: The selection ranges candidate.
    /// - Returns: Sanitized range set to set to `selectionRanges` and `insertionLocations`, or `nil` when invalid.
    func prepareForSelectionUpdate(_ ranges: [NSRange]) -> (selectedRanges: [NSValue], insertionLocations: [Int])? {
        
        guard !ranges.isEmpty else { return nil }
        
        let ranges = ranges.uniqued.sorted()
        let selectionSet = IndexSet(integersIn: ranges)
        let nonemptyRanges = selectionSet.rangeView
            .map(NSRange.init)
        var emptyRanges = ranges
            .filter { $0.isEmpty }
            .filter { !selectionSet.contains(integersIn: ($0.location-1)..<$0.location) }  // -1 to check upper bound
        
        // -> In the proper implementation of NSTextView, `selectionRanges` can have
        //    either a single empty range, a single non-empty range, or multiple non-empty ranges. (macOS 10.14)
        let selectedRanges = nonemptyRanges.isEmpty ? [emptyRanges.removeFirst()] : nonemptyRanges
        
        return (selectedRanges as [NSValue], emptyRanges.map(\.location))
    }
    
    
    /// Adds a new insertion point at `point` or removes an existing if any.
    ///
    /// - Parameter point: The point where user clicked, in view coordinates.
    /// - Returns: Whether the insertion/removal succeed.
    @discardableResult
    func modifyInsertionPoint(at point: NSPoint) -> Bool {
        
        let location = self.characterIndexForInsertion(at: point)
        var ranges = self.insertionRanges
        
        if let clicked = ranges.first(where: { $0.touches(location) }) {
            ranges.removeFirst(clicked)
        } else {
            ranges.append(NSRange(location: location, length: 0))
        }
        
        guard let set = self.prepareForSelectionUpdate(ranges) else { return false }
        
        self.selectedRanges = set.selectedRanges
        self.insertionLocations = set.insertionLocations
        
        return true
    }
    
    
    /// Moves all cursors with the same rule.
    ///
    /// - Parameters:
    ///   - affinity: The selection affinity for the movement.
    ///   - block: The block that describes the rule how to move the cursors.
    ///   - range: The range of each insertion.
    func moveCursors(affinity: NSSelectionAffinity, using block: (_ range: NSRange) -> Int) {
        
        let ranges = self.insertionRanges.map(block).map { NSRange(location: $0, length: 0) }
        
        guard let set = self.prepareForSelectionUpdate(ranges) else { return assertionFailure() }
        
        // manually set ranges and insertionLocations separately to inform `affinity` to the receiver
        self.setSelectedRanges(set.selectedRanges, affinity: affinity, stillSelecting: false)
        self.insertionLocations = set.insertionLocations
        
        let rangeToVisible: NSRange = switch affinity {
            case .downstream: ranges.first!
            case .upstream: ranges.last!
            @unknown default: fatalError()
        }
        self.scrollRangeToVisible(rangeToVisible)
    }
    
    
    /// Moves all cursors and expands selection with the same rule.
    ///
    /// - Parameters:
    ///   - forward: `true` if the cursor should move forward, otherwise `false`.
    ///   - affinity: The selection affinity for the movement.
    ///   - block: The block that describes the rule how to move the cursor.
    ///   - cursor: The character index of the cursor to move.
    func moveCursorsAndModifySelection(forward: Bool, affinity: NSSelectionAffinity, using block: (_ cursor: Int) -> Int) {
        
        var origins = self.selectionOrigins
        var newOrigins: [Int] = []
        let ranges = self.insertionRanges.map { range -> NSRange in
            let origin: Int? = origins
                .firstIndex { range.upperBound == $0 || range.lowerBound == $0 }
                .flatMap { origins.remove(at: $0) }
            
            let (cursor, newOrigin): (Int, Int) = switch (forward, origin) {
                case (false, range.lowerBound): (range.upperBound, range.lowerBound)
                case (false, _):                (range.lowerBound, range.upperBound)
                case (true, range.upperBound):  (range.lowerBound, range.upperBound)
                case (true, _):                 (range.upperBound, range.lowerBound)
            }
            
            let newCursor = block(cursor)
            
            newOrigins.append(origin ?? newOrigin)
            
            let range = if (newCursor < newOrigin && newOrigin < cursor) || (cursor < newOrigin && newOrigin < newCursor) {
                newOrigin..<newOrigin
            } else if newOrigin < newCursor {
                newOrigin..<newCursor
            } else {
                newCursor..<newOrigin
            }
            
            return NSRange(range)
        }
        
        guard let set = self.prepareForSelectionUpdate(ranges) else { return assertionFailure() }
        
        // manually set ranges and insertionLocations separately to inform `affinity` to the receiver
        self.setSelectedRanges(set.selectedRanges, affinity: affinity, stillSelecting: false)
        self.insertionLocations = set.insertionLocations
        self.selectionOrigins = newOrigins
        
        // make the moved location visible
        let cursorLocation = forward ? ranges.last!.upperBound : ranges.first!.lowerBound
        self.scrollRangeToVisible(NSRange(location: cursorLocation, length: 0))
    }
    
    
    /// Adds new insertion points just above/below to the current insertions.
    ///
    /// - Note: This API requires TextKit 1.
    ///
    /// - Parameter affinity: The direction to add new ones; `.downstream` to add above, otherwise `.upstream`.
    func addSelectedColumn(affinity: NSSelectionAffinity) {
        
        guard
            let layoutManager = self.layoutManager,
            let textContainer = self.textContainer
        else { assertionFailure(); return }
        
        let insertionRanges = self.insertionRanges
        
        // get last line
        let lastCharacterIndex = (affinity == .downstream) ? insertionRanges.first!.lowerBound : insertionRanges.last!.upperBound
        let lastLineRange = (self.string as NSString).lineRange(at: lastCharacterIndex)
        
        // abort when one of the cursors already reached to the edge
        guard
            !(affinity == .downstream && lastLineRange.lowerBound == 0),
            !(affinity == .upstream && lastLineRange.upperBound > self.string.length)
        else { return }
        
        // get number of wrapped lines where the base insertion point (the most opposite side of growing direction) is on
        let glyphRanges = insertionRanges.map { layoutManager.glyphRange(forCharacterRange: $0, actualCharacterRange: nil) }
        let baseIndex = (affinity == .downstream) ? glyphRanges.last!.lowerBound : glyphRanges.first!.upperBound
        let wrappedRow = layoutManager.numberOfWrappedRows(at: baseIndex, affinity: self.selectionAffinity)
        
        // filter existing selections to remove ones not in the same row
        let sameRowGlyphRanges = glyphRanges
            .filter { layoutManager.numberOfWrappedRows(at: $0.lowerBound, affinity: affinity) == wrappedRow }
        let validGlyphRanges = sameRowGlyphRanges.isEmpty ? glyphRanges : sameRowGlyphRanges
        let lineFragmentUsedRects = layoutManager.lineFragmentUsedRects(inSelectedGlyphRanges: validGlyphRanges)
        
        // get new visual line to append
        // -> Use line fragment to allow placing insertion points even when the line is shorter than the origin insertion columns.
        let newLineRect: CGRect = switch affinity {
            case .downstream:
                layoutManager.lineFragmentRect(forGlyphAt: layoutManager.glyphIndexForCharacter(at: lastLineRange.lowerBound - 1), wrappedRow: wrappedRow)
            case .upstream where layoutManager.isValidGlyphIndex(lastLineRange.upperBound):
                layoutManager.lineFragmentRect(forGlyphAt: layoutManager.glyphIndexForCharacter(at: lastLineRange.upperBound), wrappedRow: wrappedRow)
            case .upstream:
                layoutManager.extraLineFragmentRect
            @unknown default: fatalError()
        }
        
        // get base selection rects in the origin line
        let safeBaseIndex = layoutManager.isValidGlyphIndex(baseIndex) ? baseIndex : baseIndex - 1
        var baseLineFragmentRange: NSRange = .notFound
        layoutManager.lineFragmentRect(forGlyphAt: safeBaseIndex, effectiveRange: &baseLineFragmentRange, withoutAdditionalLayout: true)
        let rowBounds = glyphRanges
            .filter { baseLineFragmentRange.intersects($0) }
            .map { layoutManager.minimumRowBounds(of: $0, in: textContainer) }
        
        let newRanges = (lineFragmentUsedRects + [newLineRect])
            .flatMap { lineRect in rowBounds
                .filter { ($0.x...($0.x + $0.width)).overlaps(lineRect.minX...lineRect.maxX) }
                .map { NSRect(x: $0.x, y: lineRect.midY, width: $0.width, height: 0) }
            }
            .map { $0.offset(by: self.textContainerOrigin) }  // to view-based
            .map { self.lineInsertionRange(for: $0) }
        
        guard let set = self.prepareForSelectionUpdate(newRanges) else { return }
        
        self.setSelectedRanges(set.selectedRanges, affinity: .upstream, stillSelecting: false)
        self.insertionLocations = set.insertionLocations
        self.scrollRangeToVisible(newRanges.last!)  // the last is newly added one
    }
    
    
    /// Returns the range for selection that are laid out within the given rectangle
    /// expecting the given rect is contained in a single line fragment.
    ///
    /// - Parameter rect: The bounding rectangle for which to return range.
    /// - Returns: Character range corresponding to the given rectangle.
    private func lineInsertionRange(for rect: NSRect) -> NSRange {
        
        let minBound = self.characterIndexForInsertion(at: NSPoint(x: rect.minX, y: rect.midY))
        let maxBound = self.characterIndexForInsertion(at: NSPoint(x: rect.maxX, y: rect.midY))
        
        return NSRange(min(minBound, maxBound)..<max(minBound, maxBound))
    }
    
    
    /// Updates insertion indicators.
    ///
    /// - Note: This API requires TextKit 1.
    func updateInsertionIndicators() {
        
        assert(Thread.isMainThread)
        
        guard !self.insertionLocations.isEmpty || !self.insertionIndicators.isEmpty else { return }
        
        guard let layoutManager = self.layoutManager else { return assertionFailure() }
        
        let properInsertionLocations = (self.isPerformingRectangularSelection && self.selectedRange.isEmpty) ? [self.selectedRange.location] : []
        let insertionLocations = (self.insertionLocations + properInsertionLocations)
        
        // reuse existing indicators
        var indicators = ArraySlice(self.insertionIndicators)  // slice for popFirst()
        let shouldDraw = self.shouldDrawInsertionPoints
        
        self.insertionIndicators = insertionLocations
            .compactMap { layoutManager.insertionPointRect(at: $0) }  // ignore split cursors
            .map { $0.offset(by: self.textContainerOrigin) }
            .map { rect in
                if let indicator = indicators.popFirst() {
                    indicator.frame = rect
                    return indicator
                } else {
                    let indicator = NSTextInsertionIndicator(frame: rect)
                    indicator.color = self.insertionPointColor
                    indicator.displayMode = shouldDraw ? .automatic : .hidden
                    self.addSubview(indicator)
                    return indicator
                }
            }
        
        // remove remaining indicators
        indicators.forEach { $0.removeFromSuperview() }
    }
    
    
    /// Workarounds the issue that indicators display even the editor is inactive (2023-08 macOS 14, FB12964703 and FB12968177)
    ///
    /// This method should be Invoked when changing the state whether the receiver is the key editor receiving text input in the system.
    func invalidateInsertionIndicatorDisplayMode() {
        
        guard !self.insertionIndicators.isEmpty else { return }
        
        let shouldDraw = self.shouldDrawInsertionPoints
        for indicator in self.insertionIndicators {
            indicator.displayMode = shouldDraw ? .automatic : .hidden
        }
    }
}


extension NSTextView {
    
    /// Whether the editor should draw insertion points.
    fileprivate final var shouldDrawInsertionPoints: Bool {
        
        NSApp.isActive && self.window?.isKeyWindow == true && self.window?.firstResponder == self && self.isEditable
    }
    
    
    /// Finds the location for the insertion point where one (visual) line above to the given insertion point location.
    ///
    /// - Note: This API requires TextKit 1.
    ///
    /// - Parameter index: The character index of the reference insertion point.
    /// - Returns: The character index of the objective insertion point location or `0` if cannot move.
    final func upperInsertionLocation(of index: Int) -> Int {
        
        guard
            let layoutManager = self.layoutManager,
            let textContainer = self.textContainer
        else { assertionFailure(); return 0 }
        
        let glyphIndex = layoutManager.glyphIndexForCharacter(at: index)
        let rect = layoutManager.boundingRect(forGlyphRange: NSRange(location: glyphIndex, length: 0), in: textContainer)
            .offset(by: self.textContainerOrigin)
        let point = NSPoint(x: rect.minX, y: rect.minY - 1)
        
        return self.characterIndexForInsertion(at: point)
    }
    
    
    /// Finds the location for the insertion point where one (visual) line below to the given insertion point location.
    ///
    /// - Note: This API requires TextKit 1.
    ///
    /// - Parameter index: The character index of the reference insertion point.
    /// - Returns: The character index of the objective insertion point location or end of the document if cannot move.
    final func lowerInsertionLocation(of index: Int) -> Int {
        
        guard
            let layoutManager = self.layoutManager,
            let textContainer = self.textContainer
        else { assertionFailure(); return 0 }
        
        let glyphIndex = layoutManager.glyphIndexForCharacter(at: index)
        let rect = layoutManager.boundingRect(forGlyphRange: NSRange(location: glyphIndex, length: 0), in: textContainer)
            .offset(by: self.textContainerOrigin)
        let point = NSPoint(x: rect.minX, y: rect.maxY + 1)
        
        return self.characterIndexForInsertion(at: point)
    }
}



// MARK: Private

private extension NSLayoutManager {
    
    /// Counts the number of wrapped rows where the insertion point at the given glyph index locates.
    ///
    /// - Parameters:
    ///   - glyphIndex: The glyph index of the insertion point.
    ///   - affinity: The current selection affinity.
    /// - Returns: The number of rows (0-based).
    func numberOfWrappedRows(at glyphIndex: Int, affinity: NSSelectionAffinity) -> Int {
        
        let characterIndex = self.characterIndexForGlyph(at: glyphIndex)
        let lineRange = (self.attributedString().string as NSString).lineRange(at: characterIndex)
        let lineGlyphRange = self.glyphRange(forCharacterRange: lineRange, actualCharacterRange: nil)
        
        var count = 0
        self.enumerateLineFragments(forGlyphRange: lineGlyphRange) { (_, _, _, glyphRange, stop) in
            guard glyphIndex > glyphRange.upperBound ||
                    (glyphIndex == glyphRange.upperBound && affinity == .downstream)
            else {
                stop.pointee = true
                return
            }
            
            count += 1
        }
        
        return count
    }
    
    
    /// Returns the line fragment rect of the given wrapped row in the logical line where the given glyph index locates.
    ///
    /// - Parameters:
    ///   - glyphIndex: The glyph index.
    ///   - wrappedRow: The number of wrapped row to get the line fragment rect.
    /// - Returns: A line fragment rect.
    func lineFragmentRect(forGlyphAt glyphIndex: Int, wrappedRow: Int) -> NSRect {
        
        assert(wrappedRow >= 0)
        
        let characterIndex = self.characterIndexForGlyph(at: glyphIndex)
        let lineRange = (self.attributedString().string as NSString).lineRange(at: characterIndex)
        let lineGlyphRange = self.glyphRange(forCharacterRange: lineRange, actualCharacterRange: nil)
        
        var count = 0
        var lineFragmentRect: NSRect = .null
        self.enumerateLineFragments(forGlyphRange: lineGlyphRange) { (rect, _, _, _, stop) in
            lineFragmentRect = rect
            if count >= wrappedRow {
                stop.pointee = true
                return
            }
            
            count += 1
        }
        
        return lineFragmentRect
    }
    
    
    /// Returns the bounds between upper and lower bounds of the given `range` in horizontal axis.
    ///
    /// - Parameters:
    ///   - characterRange: The glyph range for which to return the bounds.
    ///   - container: The text container in which the glyphs are laid out.
    /// - Returns: Actual bounds of the given `characterRange` or bounds between `.upperBound` and `.lowerBound`
    ///            when the range extends across multiple lines.
    func minimumRowBounds(of glyphRange: NSRange, in container: NSTextContainer) -> (x: CGFloat, width: CGFloat) {
        
        let lowerX = self.boundingRect(forGlyphRange: NSRange(location: glyphRange.lowerBound, length: 0), in: container).minX
        let upperX = self.boundingRect(forGlyphRange: NSRange(location: glyphRange.upperBound, length: 0), in: container).minX
        
        return (x: min(lowerX, upperX), width: abs(lowerX - upperX))
    }
    
    
    /// Returns all line fragment used rects including `extraLineFragmentUsedRect` or empty range at the end of given range.
    ///
    /// - Parameters:
    ///   - glyphRange: The glyph range where to return line fragment rectangles.
    /// - Returns: An array of the portions of the line fragment rectangles that actually contains glyphs or other marks that are drawn.
    func lineFragmentUsedRects(inSelectedGlyphRanges glyphRanges: [NSRange]) -> [NSRect] {
        
        assert(!glyphRanges.isEmpty)
        
        var rects: [NSRect] = []
        
        for glyphRange in glyphRanges {
            if !glyphRange.isEmpty {
                self.enumerateLineFragments(forGlyphRange: glyphRange) { (_, usedRect, _, _, _) in
                    rects.append(usedRect)
                }
                
            } else if self.extraLineFragmentTextContainer != nil, !self.isValidGlyphIndex(glyphRange.location) {
                rects.append(self.extraLineFragmentUsedRect)
                
            } else {
                let safeGlyphIndex = self.isValidGlyphIndex(glyphRange.location) ? glyphRange.location : glyphRange.location - 1
                let usedRect = self.lineFragmentUsedRect(forGlyphAt: safeGlyphIndex, effectiveRange: nil, withoutAdditionalLayout: true)
                
                rects.append(usedRect)
            }
        }
        assert(!rects.isEmpty)
        
        return rects.uniqued
    }
}
