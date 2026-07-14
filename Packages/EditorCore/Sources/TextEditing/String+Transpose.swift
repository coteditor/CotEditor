//
//  String+Transpose.swift
//  TextEditing
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-07-14.
//
//  ---------------------------------------------------------------------------
//
//  © 2026 1024jp
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

public import Foundation
import StringUtils

public extension String {
    
    /// Returns the editing context that transposes the characters around each of the given insertion points.
    ///
    /// The two characters on either side of each insertion point are swapped, except at the end of a line
    /// or the document, where the two preceding characters are swapped instead. Insertion points at the
    /// document start or where there is nothing to swap are left untouched.
    ///
    /// - Parameter selectedRanges: The selected ranges at which to transpose the characters.
    /// - Returns: An `EditingContext`, or `nil` if there is nothing to transpose.
    func transpose(at selectedRanges: [NSRange]) -> EditingContext? {
        
        let string = self as NSString
        
        var replacementRanges: [NSRange] = []
        var replacementStrings: [String] = []
        var newSelectedRanges: [NSRange] = []
        for range in selectedRanges.reversed() {
            guard range.isEmpty, range.location > 0 else {
                newSelectedRanges.append(range)
                continue
            }
            
            let location = range.location
            
            // find the characters to swap and the resulting insertion point location
            let swap: (range: NSRange, string: String, location: Int)
            if location == string.length || string.character(at: location).isNewline {
                // at the end of a line or the document, swap the two preceding characters
                let index = string.index(before: location)
                let precedingIndex = string.index(before: index)
                
                guard precedingIndex < index,
                      !string.character(at: precedingIndex).isNewline,
                      !string.character(at: index).isNewline
                else {
                    newSelectedRanges.append(range)
                    continue
                }
                
                let newString = string.substring(with: NSRange(index..<location)) + string.substring(with: NSRange(precedingIndex..<index))
                swap = (NSRange(precedingIndex..<location), newString, location)
                
            } else {
                // swap the characters on either side of the insertion point
                let precedingIndex = string.index(before: location)
                let followingIndex = string.index(after: location)
                let newString = string.substring(with: NSRange(location..<followingIndex)) + string.substring(with: NSRange(precedingIndex..<location))
                swap = (NSRange(precedingIndex..<followingIndex), newString, followingIndex)
            }
            
            // keep the insertion point unchanged if there is nothing to swap,
            // or if its swap range overlaps that of the adjacent insertion point
            guard replacementRanges.last.map({ swap.range.upperBound <= $0.lowerBound }) ?? true else {
                newSelectedRanges.append(range)
                continue
            }
            
            replacementStrings.append(swap.string)
            replacementRanges.append(swap.range)
            newSelectedRanges.append(NSRange(location: swap.location, length: 0))
        }
        
        guard !replacementRanges.isEmpty else { return nil }
        
        return EditingContext(strings: replacementStrings.reversed(),
                              ranges: replacementRanges.reversed(),
                              selectedRanges: newSelectedRanges.reversed())
    }
}
