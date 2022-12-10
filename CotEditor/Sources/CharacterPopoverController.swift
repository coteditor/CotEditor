//
//  CharacterPopoverController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2014-05-01.
//
//  ---------------------------------------------------------------------------
//
//  © 2014-2022 1024jp
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

final class CharacterPopoverController: NSViewController {
    
    // MARK: Private Properties
    
    @objc private let glyph: String
    @objc private let unicodeName: String?
    @objc private let unicodeBlockName: String?
    @objc private let unicodeCategoryName: String?
    @objc private let unicode: String
    
    @objc private let characterColor: NSColor
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    /// Instantiate proper view controller for the given character info.
    ///
    /// - Parameter chraracter: The Character to inspect.
    static func instantiate(for character: Character) -> Self {
        
        let info = CharacterInfo(character: character)
        let storyboard = NSStoryboard(name: "CharacterPopover", bundle: nil)
        let creator: ((NSCoder) -> Self?) = { (coder) in Self(coder: coder, characterInfo: info) }
        
        return info.isComplex
            ? storyboard.instantiateController(identifier: "ComplexCharacterPopoverController", creator: creator)
            : storyboard.instantiateInitialController(creator: creator)!
    }
    
    
    /// Initialize view from a storyboard with given values.
    ///
    /// - Parameters:
    ///   - coder: The coder to instantiate the view from a storyboard.
    ///   - characterInfo: The CharacterInfo instance to display.
    private init?(coder: NSCoder, characterInfo info: CharacterInfo) {
        
        let unicodes = info.character.unicodeScalars
        
        self.glyph = info.pictureString ?? String(info.character)
        self.unicodeName = info.localizedDescription
        self.unicodeBlockName = info.isComplex ? nil : unicodes.first?.localizedBlockName
        self.unicodeCategoryName = {
            guard
                !info.isComplex,
                let category = unicodes.first?.properties.generalCategory
            else { return nil }
            
            return "\(category.longName) (\(category.shortName))"
        }()
        
        // build Unicode code point string
        let isMultiple = unicodes.count > 1
        let codePoints: [String] = unicodes.map { unicode in
            var codePoint = unicode.codePoint
            
            if !isMultiple, let surrogates = unicode.surrogateCodePoints {
                codePoint += " (\(surrogates.lead) \(surrogates.trail))"
            }
            
            // append Unicode name
            if isMultiple, let name = unicode.name {
                codePoint += "\t" + name
            }
            
            return codePoint
        }
        
        self.unicode = codePoints.joined(separator: "\n")
        self.characterColor = (info.pictureString != nil) ? .tertiaryLabelColor : .labelColor
        
        super.init(coder: coder)
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
}
    
    

// MARK: Delegate

extension CharacterPopoverController: NSPopoverDelegate {
    
    /// make popover detachable
    func popoverShouldDetach(_ popover: NSPopover) -> Bool {
        
        true
    }
    
}
