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
    var selectionOrigins: [Int] { get set }
    
    var insertionPointTimer: DispatchSourceTimer? { get set }
    var insertionPointOn: Bool { get set }
    var isPerformingRectangularSelection: Bool { get }
}


extension MultiCursorEditing where Self: NSTextView {
    
    /// Whether the receiver has multiple points to insert text.
    var hasMultipleInsertions: Bool {
        
        return (self.insertionLocations.count + self.selectedRanges.count) > 1
    }
    
    
    /// All ranges to insert for multiple-cursor editing.
    var insertionRanges: [NSRange] {
        
        let insertionRanges = self.insertionLocations.map { NSRange(location: $0, length: 0) }
        return ((self.selectedRanges as! [NSRange]) + insertionRanges).sorted { $0.location < $1.location }
    }
    
    
    /// Whetehr the receiver needs to draw insertion points by itself.
    var needsDrawInsertionPoints: Bool {
        
        return !(self.insertionPointTimer?.isCancelled ?? true)
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
        
        self.setSelectedRangesWithUndo(self.insertionRanges)
        
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
        
        self.setSelectedRangesWithUndo(newInsertionLocations.map { NSRange(location: $0, length: 0) })
        
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
                guard range.isEmpty else { return range }
                
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
    
    
    /// Sanitize and divide selection ranges candidate to ones to set to the proper `selectionRanges` and `insertionLocations`.
    ///
    /// - Parameter ranges: The selection ranges randidate.
    /// - Returns: Sanitized range set to set to `selectionRanges` and `insertionLocations`, or `nil` when invalid.
    func prepareForSelectionUpdate(_ ranges: [NSRange]) -> (selectedRanges: [NSValue], insertionLocations: [Int])? {
        
        guard !ranges.isEmpty else { return nil }
        
        let ranges = ranges.unique.sorted { $0.location < $1.location }
        let selectionSet = ranges
            .map { Range<Int>($0)! }
            .reduce(into: IndexSet()) { $0.insert(integersIn: $1) }
        let nonemptyRanges = selectionSet.rangeView
            .map { NSRange($0) }
        var emptyRanges = ranges
            .filter { $0.isEmpty }
            .filter { !selectionSet.contains(integersIn: ($0.location-1)..<$0.location) }  // -1 to check upper bound
        
        // -> In the proper implementation of NSTextView, `selectionRanges` can have
        //    either a single empty range, a single nonempty range, or multiple nonempty ranges (macOS 10.14).
        let selectedRanges = nonemptyRanges.isEmpty ? [emptyRanges.removeFirst()] : nonemptyRanges
        
        return (selectedRanges as [NSValue], emptyRanges.map { $0.location })
    }
    
    
    /// Add a new insrtion point at `point` or remove an existing if any.
    ///
    /// - Parameter point: The point where user clicked, in view coordinates.
    /// - Returns: Whether the insertion/removal succeed.
    @discardableResult
    func modifyInsertionPoint(at point: NSPoint) -> Bool {
        
        let location = self.characterIndexForInsertion(at: point)
        var ranges = self.insertionRanges
        
        if let clicked = ranges.first(where: { $0.touches(location) }) {
            ranges.remove(clicked)
        } else {
            ranges.append(NSRange(location..<location))
        }
        
        guard let set = self.prepareForSelectionUpdate(ranges) else { return false }
        
        self.selectedRanges = set.selectedRanges
        self.insertionLocations = set.insertionLocations
        
        return true
    }
    
    
    /// Move all cursors with the same rule.
    ///
    /// - Parameters:
    ///   - affinity: The selection affinity for the movement.
    ///   - block: The block that describes the rule how to move the cursors.
    ///   - range: The range of each insertion.
    func moveCursors(affinity: NSSelectionAffinity, using block: (_ range: NSRange) -> Int) {
        
        let ranges = self.insertionRanges.map(block).map { NSRange($0..<$0) }
        
        guard let set = self.prepareForSelectionUpdate(ranges) else { return assertionFailure() }
        
        // manually set ranges and insertionLocations separatelly to inform `affinity` to the receiver
        self.setSelectedRanges(set.selectedRanges, affinity: affinity, stillSelecting: false)
        self.insertionLocations = set.insertionLocations
        
        self.scrollRangeToVisible(NSRange(ranges.first!.lowerBound..<ranges.last!.upperBound))
    }
    
    
    /// Move all cursors and expand selection with the same rule.
    ///
    /// - Parameters:
    ///   - affinity: The selection affinity for the movement.
    ///   - block: The block that describes the rule how to change the selection.
    ///   - range: The range of each insertion.
    ///   - origin: The character index where the selection initially started.
    func moveCursorsAndModifySelection(affinity: NSSelectionAffinity, using block: (_ range: NSRange, _ origin: Int?) -> (cursor: Int, origin: Int)) {
        
        var origins = self.selectionOrigins
        var newOrigins: [Int] = []
        let ranges = self.insertionRanges.map { range -> NSRange in
            let origin: Int?
            if let index = origins.firstIndex(where: { range.upperBound == $0 || range.lowerBound == $0 }) {
                origin = origins.remove(at: index)
            } else {
                origin = nil
            }
            
            let bounds = block(range, origin)
            
            newOrigins.append(origin ?? bounds.origin)
            
            return (bounds.cursor <= bounds.origin) ? NSRange(bounds.cursor..<bounds.origin) : NSRange(bounds.origin..<bounds.cursor)
        }
        
        guard let set = self.prepareForSelectionUpdate(ranges) else { return assertionFailure() }
        
        // manually set ranges and insertionLocations separatelly to inform `affinity` to the receiver
        self.setSelectedRanges(set.selectedRanges, affinity: affinity, stillSelecting: false)
        self.insertionLocations = set.insertionLocations
        self.selectionOrigins = newOrigins
        
        self.scrollRangeToVisible(NSRange(ranges.first!.lowerBound..<ranges.last!.upperBound))
    }
    
    
    /// Enable or disable `insertionPointTimer` according to the selection state.
    func updateInsertionPointTimer() {
        
        if self.isPerformingRectangularSelection || (!self.insertionLocations.isEmpty && self.selectedRanges.allSatisfy({ !$0.rangeValue.isEmpty })) {
            self.enableOwnInsertionPointTimer()
            
        } else {
            self.insertionPointTimer?.cancel()
        }
    }
    
    
    /// Add new insertion points just above/below to the current insertions.
    ///
    /// - Parameter affinity: The direction to add new ones; `.downstream` to add above, otherwise `.upstream`.
    func addSelectedColumn(affinity: NSSelectionAffinity) {
        
        guard
            let layoutManager = self.layoutManager,
            let textContainer = self.textContainer
            else { assertionFailure(); return }
        
        let glyphRanges = self.insertionRanges.map { layoutManager.glyphRange(forCharacterRange: $0, actualCharacterRange: nil) }
        let wholeRange = NSRange(glyphRanges.first!.lowerBound..<glyphRanges.last!.upperBound)
        let lineFragmentUsedRects = layoutManager.lineFragmentUsedRects(in: wholeRange)
        assert(!lineFragmentUsedRects.isEmpty)
        
        // new visual line to append
        var newLineRect: NSRect = {
            switch affinity {
            case .downstream:
                let rect = lineFragmentUsedRects.first!
                return rect.offsetBy(dx: 0, dy: -rect.height)
            case.upstream:
                let rect = lineFragmentUsedRects.last!
                return rect.offsetBy(dx: 0, dy: rect.height)
            }
        }()
        
        let baseIndex = (affinity == .downstream) ? glyphRanges.last!.lowerBound : glyphRanges.first!.upperBound
        
        // get base selection rects in the origin line
        // -> At the same time, expand newLineRect to the entire line fragment
        //    to allow placing insertion points even when the line is shorter than the origin insertion columns.
        var baseLineRange: NSRange = .notFound
        newLineRect.origin.x = 0
        newLineRect.size.width = layoutManager.lineFragmentRect(forGlyphAt: baseIndex, effectiveRange: &baseLineRange, withoutAdditionalLayout: true).width
        let rowBounds = glyphRanges
            .filter { baseLineRange.touches($0) }
            .map { layoutManager.minimumRowBounds(of: $0, in: textContainer) }
        
        let newRanges = (lineFragmentUsedRects + [newLineRect])
            .flatMap { lineRect in rowBounds
                .filter { ($0.x...($0.x + $0.width)).overlaps(lineRect.minX...lineRect.maxX) }
                .map { NSRect(x: $0.x, y: lineRect.midY, width: $0.width, height: 0) }
            }
            .map { $0.offset(by: self.textContainerOrigin) }  // to view-based
            .map { self.lineInsertionRange(for: $0) }
        
        guard let set = self.prepareForSelectionUpdate(newRanges) else { return }
        
        self.setSelectedRanges(set.selectedRanges, affinity: affinity, stillSelecting: false)
        self.insertionLocations = set.insertionLocations
        self.scrollRangeToVisible(newRanges.last!)  // the last is newly added one
    }
    
    
    /// Return the range for selection that are laid out within the given rectangle
    /// expecting the given rect is contained in a single line fragment.
    ///
    /// - Parameter rect: The bounding rectangle for which to return range.
    /// - Returns: Character range corresponding to the given rectangle.
    private func lineInsertionRange(for rect: NSRect) -> NSRange {
        
        let minBound = self.characterIndexForInsertion(at: NSPoint(x: rect.minX, y: rect.midY))
        let maxBound = self.characterIndexForInsertion(at: NSPoint(x: rect.maxX, y: rect.midY))
        
        return NSRange(min(minBound, maxBound)..<max(minBound, maxBound))
    }
    
}



extension NSTextView {
    
    /// Calculate rect for insartion point at `index`.
    ///
    /// - Parameter index: The character index where the insertion point will locate.
    /// - Returns: Rect where insertion point filled.
    @objc func insertionPointRect(at index: Int) -> NSRect {
        
        guard
            let layoutManager = self.layoutManager,
            let textContainer = self.textContainer
            else { assertionFailure(); return .zero }
        
        let glyphIndex = layoutManager.glyphIndexForCharacter(at: index)
        let rect = layoutManager.boundingRect(forGlyphRange: NSRange(glyphIndex..<glyphIndex), in: textContainer)
            .offset(by: self.textContainerOrigin)
        
        return NSRect(x: floor(rect.minX), y: rect.minY, width: 1 / self.scale, height: rect.height)
    }
    
    
    /// Find the location for a insertion point where one (visual) line above to the given insertion point location.
    ///
    /// - Parameter index: The character index of the reference insertion point.
    /// - Returns: The character index of the objective insertion point location or `0` if cannot move.
    func upperInsertionLocation(of index: Int) -> Int {
        
        guard
            let layoutManager = self.layoutManager,
            let textContainer = self.textContainer
            else { assertionFailure(); return 0 }
        
        let glyphIndex = layoutManager.glyphIndexForCharacter(at: index)
        let rect = layoutManager.boundingRect(forGlyphRange: NSRange(glyphIndex..<glyphIndex), in: textContainer)
            .offset(by: self.textContainerOrigin)
        let point = NSPoint(x: rect.minX, y: rect.minY - 1)
        
        return self.characterIndexForInsertion(at: point)
    }
    
    
    /// Find the location for a insertion point where one (visual) line below to the given insertion point location.
    ///
    /// - Parameter index: The character index of the reference insertion point.
    /// - Returns: The character index of the objective insertion point location or end of the document if cannot move.
    func lowerInsertionLocation(of index: Int) -> Int {
        
        guard
            let layoutManager = self.layoutManager,
            let textContainer = self.textContainer
            else { assertionFailure(); return 0 }
        
        let glyphIndex = layoutManager.glyphIndexForCharacter(at: index)
        let rect = layoutManager.boundingRect(forGlyphRange: NSRange(glyphIndex..<glyphIndex), in: textContainer)
            .offset(by: self.textContainerOrigin)
        let point = NSPoint(x: rect.minX, y: rect.maxY + 1)
        
        return self.characterIndexForInsertion(at: point)
    }
    
}



// MARK: Private

private struct BlinkPeriod {
    
    var on: Int
    var off: Int
}


private extension UserDefaults {
    
    var textInsertionPointBlinkPeriod: BlinkPeriod {
        
        let onPeriod = self.integer(forKey: "NSTextInsertionPointBlinkPeriodOn")
        let offPeriod = self.integer(forKey: "NSTextInsertionPointBlinkPeriodOff")
        
        return BlinkPeriod(on: (onPeriod > 0) ? onPeriod : 500,
                           off: (offPeriod > 0) ? offPeriod : 500)
    }
    
}


private extension MultiCursorEditing where Self: NSTextView {
    
    /// Enable insertion point blink timer to draw insertion points forcely.
    private func enableOwnInsertionPointTimer() {
        
        guard self.insertionPointTimer?.isCancelled ?? true else { return }
        
        let period = UserDefaults.standard.textInsertionPointBlinkPeriod
        
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now())
        timer.setEventHandler { [unowned self] in
            self.insertionPointOn.toggle()
            let interval = self.insertionPointOn ? period.on : period.off
            timer.schedule(deadline: .now() + .milliseconds(interval))
            self.setNeedsDisplay(self.visibleRect, avoidAdditionalLayout: true)
        }
        timer.resume()
        
        self.insertionPointTimer?.cancel()
        self.insertionPointTimer = timer
    }
    
}


private extension NSLayoutManager {
    
    /// Return the bounds between upper and lower bounds of the given `range` in horizontal axis.
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
    
    
    /// Return all line fragment used rects including `extraLineFragmentUsedRect` or empty range at the end of given range.
    ///
    /// - Parameter glyphRange: The glyph range where to return line fragment rectangles.
    /// - Returns: An array of the portions of the line fragment rectangles that actually contains glyphs or other marks that are drawn.
    func lineFragmentUsedRects(in glyphRange: NSRange) -> [NSRect] {
        
        var rects: [NSRect] = []
        var glyphIndex = glyphRange.lowerBound
        while glyphIndex <= glyphRange.upperBound {
            var effectiveRange: NSRange = .notFound
            let rect = self.lineFragmentUsedRect(forGlyphAt: glyphIndex, effectiveRange: &effectiveRange, withoutAdditionalLayout: true)
            glyphIndex = effectiveRange.upperBound
            
            rects.append(rect)
        }
        
        if glyphRange.upperBound == self.numberOfGlyphs, self.extraLineFragmentTextContainer != nil {
            rects.append(self.extraLineFragmentUsedRect)
        }
        
        return rects
    }
    
}
