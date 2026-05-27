//
//  NSTextLayoutManager+RegexParse.swift
//  RegexHighlighting
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-05-27.
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

public import AppKit

public extension NSTextLayoutManager {
    
    /// Invalidates regular-expression syntax highlighting.
    ///
    /// This method installs a rendering attributes validator when highlighting is enabled and removes it
    /// when highlighting is disabled, then triggers TextKit 2 to validate the current rendering attributes.
    ///
    /// - Parameters:
    ///   - mode: Parse mode of regular expression.
    ///   - theme: The color theme for regex highlighting.
    ///   - enabled: If true, update the rendering attributes validator; otherwise just remove the current highlight.
    final func invalidateRegularExpressionHighlight(mode: RegexParseMode, theme: RegexTheme<NSColor>, enabled: Bool = true) {
        
        guard enabled else {
            self.invalidateRenderingAttributes(for: self.documentRange)
            self.renderingAttributesValidator = nil
            self.textContentManager?.updateRendering()
            return
        }
        
        self.renderingAttributesValidator = { layoutManager, textLayoutFragment in
            layoutManager.removeRenderingAttribute(.foregroundColor, for: textLayoutFragment.rangeInElement)
            
            guard
                let string = layoutManager.textStorage?.string,
                mode.validate(pattern: string)
            else { return }
            
            for type in RegexSyntaxType.allCases.reversed() {
                let textRanges = type.ranges(in: string, mode: mode)
                    .compactMap(layoutManager.textRange(for:))
                    .compactMap(textLayoutFragment.rangeInElement.intersection)
                
                guard !textRanges.isEmpty else { continue }
                
                let color = theme.color(for: type)
                for textRange in textRanges {
                    layoutManager.addRenderingAttribute(.foregroundColor, value: color, for: textRange)
                }
            }
        }
        
        self.textContentManager?.updateRendering()
    }
    
    
    /// Updates regular-expression syntax highlighting.
    final func updateRegularExpressionHighlight() {
        
        self.textContentManager?.updateRendering()
    }
    
    
    /// The default content storage.
    private var textStorage: NSTextStorage? {
        
        (self.textContentManager as? NSTextContentStorage)?.textStorage
    }
}


private extension NSTextContentManager {
    
    /// Records a no-op edit action to make TextKit 2 update rendering attributes for the document range.
    func updateRendering() {
        
        guard !self.documentRange.isEmpty else { return }
        
        self.performEditingTransaction {
            self.recordEditAction(in: self.documentRange, newTextRange: self.documentRange)
        }
    }
}
