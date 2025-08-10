//
//  NSTextView+RenderingAttributes.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2025-08-10.
//
//  ---------------------------------------------------------------------------
//
//  © 2025 1024jp
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
import ValueRange

extension NSTextView {
    
    /// Removes temporal background color highlights in the receiver.
    @IBAction final func unhighlight(_ sender: Any?) {
        
        if let textContentStorage {
            for textLayoutManager in textContentStorage.textLayoutManagers {
                textLayoutManager.removeRenderingAttribute(.backgroundColor, for: textContentStorage.documentRange)
            }
            
        } else if let textStorage {
            for layoutManager in textStorage.layoutManagers where layoutManager.hasTemporaryAttribute(.backgroundColor) {
                layoutManager.removeTemporaryAttribute(.backgroundColor, forCharacterRange: textStorage.range)
            }
        }
        
    }
    
    
    /// Changes the background color of passed-in ranges.
    ///
    /// - Parameters:
    ///   - color: The background color.
    ///   - ranges: The ranges to markup.
    final func updateBackgroundColor(_ color: NSColor, ranges: [NSRange]) {
        
        if let textContentStorage {
            for textLayoutManager in textContentStorage.textLayoutManagers {
                textLayoutManager.updateBackgroundColor(color, ranges: ranges)
            }
            
        } else if let textStorage {
            for layoutManager in textStorage.layoutManagers {
                layoutManager.updateBackgroundColor(color, ranges: ranges)
            }
        }
    }
    
    
    /// Changes the background color of passed-in ranges.
    ///
    /// - Parameters:
    ///   - colors: The pairs of the character range and color to apply.
    final func updateBackgroundColors(_ colors: [ValueRange<NSColor>]) {
        
        if let textContentStorage {
            for textLayoutManager in textContentStorage.textLayoutManagers {
                textLayoutManager.updateBackgroundColors(colors)
            }
            
        } else if let textStorage {
            for layoutManager in textStorage.layoutManagers {
                layoutManager.updateBackgroundColors(colors)
            }
        }
    }
}


// MARK: Private Extensions

private extension NSTextLayoutManager {
    
    /// Changes the temporary background color of passed-in ranges.
    ///
    /// - Parameters:
    ///   - color: The background color.
    ///   - ranges: The ranges to markup.
    final func updateBackgroundColor(_ color: NSColor, ranges: [NSRange]) {
        
        // perform only when really needed to avoid unnecessary layout updates
        guard self.hasRenderingAttribute(.backgroundColor) || !ranges.isEmpty else { return }
        
        self.removeRenderingAttribute(.backgroundColor, for: self.documentRange)
        for range in ranges {
            guard let textRange = self.textContentManager?.textRange(for: range) else { continue }
            
            self.addRenderingAttribute(.backgroundColor, value: color, for: textRange)
        }
    }
    
    
    /// Changes the temporary background color of passed-in ranges.
    ///
    /// - Parameters:
    ///   - colors: The pairs of the character range and color to apply.
    final func updateBackgroundColors(_ colors: [ValueRange<NSColor>]) {
        
        // perform only when really needed to avoid unnecessary layout updates
        guard self.hasRenderingAttribute(.backgroundColor) || !colors.isEmpty else { return }
        
        self.removeRenderingAttribute(.backgroundColor, for: self.documentRange)
        for color in colors {
            guard let textRange = self.textContentManager?.textRange(for: color.range) else { continue }
            
            self.addRenderingAttribute(.backgroundColor, value: color.value, for: textRange)
        }
    }
    
    
    /// Checks if at least one rendering attribute for the given key exists.
    ///
    /// - Parameters:
    ///   - attrName: The key name of the rendering attribute to check.
    /// - Returns: Whether the given attribute exists.
    private func hasRenderingAttribute(_ attrName: NSAttributedString.Key) -> Bool {
        
        guard !self.documentRange.isEmpty else { return false }
        
        var hasAttribute = false
        self.enumerateRenderingAttributes(from: self.documentRange.location, reverse: false) { _, attributes, _ in
            hasAttribute = (attributes[attrName] != nil)
            return !hasAttribute
        }
        
        return hasAttribute
    }
}


private extension NSLayoutManager {
    
    /// Changes the temporary background color of passed-in ranges.
    ///
    /// - Parameters:
    ///   - color: The background color.
    ///   - ranges: The ranges to markup.
    final func updateBackgroundColor(_ color: NSColor, ranges: [NSRange]) {
        
        // perform only when really needed to avoid unnecessary layout updates
        guard self.hasTemporaryAttribute(.backgroundColor) || !ranges.isEmpty else { return }
        
        let wholeRange = self.attributedString().range
        
        self.groupTemporaryAttributesUpdate(in: wholeRange) {
            self.removeTemporaryAttribute(.backgroundColor, forCharacterRange: wholeRange)
            for range in ranges {
                self.addTemporaryAttribute(.backgroundColor, value: color, forCharacterRange: range)
            }
        }
    }
    
    
    /// Changes the temporary background color of passed-in ranges.
    ///
    /// - Parameters:
    ///   - colors: The pairs of the character range and color to apply.
    final func updateBackgroundColors(_ colors: [ValueRange<NSColor>]) {
        
        // perform only when really needed to avoid unnecessary layout updates
        guard self.hasTemporaryAttribute(.backgroundColor) || !colors.isEmpty else { return }
        
        let wholeRange = self.attributedString().range
        
        self.groupTemporaryAttributesUpdate(in: wholeRange) {
            self.removeTemporaryAttribute(.backgroundColor, forCharacterRange: wholeRange)
            for color in colors {
                self.addTemporaryAttribute(.backgroundColor, value: color.value, forCharacterRange: color.range)
            }
        }
    }
}
