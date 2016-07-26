/*
 
 UnicodeCharacter.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2015-11-21.
 
 ------------------------------------------------------------------------------
 
 © 2015-2016 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Foundation
import ICU

class UnicodeCharacter: CustomStringConvertible, CustomDebugStringConvertible {
    
    // MARK: Public Properties
    
    let character: UnicodeScalar
    
    /// Unicode name
    private(set) lazy var name: String = self.character.name ?? ""
    
    /// alternate picture caracter for invisible control character
    private(set) lazy var pictureCharacter: UnicodeScalar? = self.character.pictureRepresentation
    
    let unicode: String
    let string: String
    let isSurrogatePair: Bool
    let surrogateUnicodes: [String]?
    
    
    
    // MARK:
    // MARK: Lifecycle
    
    required init(character: UnicodeScalar) {
        
        self.character = character
        self.unicode = character.codePoint
        
        // surrogate pair check
        self.isSurrogatePair = character.isSurrogatePair
        if self.isSurrogatePair {
            self.surrogateUnicodes = [String(format: "U+%04X", UTF16.leadSurrogate(character)),
                                      String(format: "U+%04X", UTF16.trailSurrogate(character))]
        } else {
            self.surrogateUnicodes = nil
        }
        
        // UnicodeScalar to String
        self.string = String(Character(character))
    }
    
    
    var description: String {
        
        return "\(self.character)"
    }
    
    
    var debugDescription: String {
        
        return "<\(self): \(self.character)>"
    }
    
    
    
    // MARK: Lazy Properties
    
    /// Unicode category name
    private(set) lazy var categoryName: String = {
        
        guard let name = self.character.categoryName else {
            return NSLocalizedString("Unknown category", tableName: "Unicode", comment: "")
        }
        
        return name
    }()
    
    
    /// Unicode block name just returned from an icu function
    private(set) lazy var blockName: String = {
        
        guard let name = self.character.blockName else {
            return NSLocalizedString("Unknown block", tableName: "Unicode", comment: "")
        }
        
        return name
    }()
    
    
    /// Localized and sanitized unicode block name
    private(set) lazy var localizedBlockName: String = {
        
        let blockName = sanitize(blockName: self.blockName)
        
        return NSLocalizedString(sanitize(blockName: self.blockName), tableName: "Unicode", comment: "")
    }()
    
}



/// sanitize block name for localization
private func sanitize(blockName: String) -> String
{
    // -> This is actually a dirty workaround to make the block name the same as the Apple's block naming rule.
    //    Otherwise, we cannot localize block name correctly. (2015-11 by 1024jp)
    
    var sanitized = blockName
    
    sanitized = sanitized.replacingOccurrences(of: " ([A-Z])$", with: "-$1", options: .regularExpression)
    sanitized = sanitized.replacingOccurrences(of: "Extension-", with: "Ext. ")
    sanitized = sanitized.replacingOccurrences(of: " And ", with: " and ")
    sanitized = sanitized.replacingOccurrences(of: " For ", with: " for ")
    sanitized = sanitized.replacingOccurrences(of: " Mathematical ", with: " Math ")
    sanitized = sanitized.replacingOccurrences(of: "Latin 1", with: "Latin-1")  // only for "Latin-1
    
    return sanitized
}



// MARK: - Test

/// check which block names will be lozalized (only for test use)
private func testUnicodeBlockNameLocalization(for language: String) {
    
    let bundleURL = Bundle.main.urlForResource(language, withExtension: "lproj")!
    let bundle = Bundle(url: bundleURL)
    
    for index in 0..<UBLOCK_COUNT.rawValue {
        let blockNameChars = u_getPropertyValueName(UCHAR_BLOCK, index, U_LONG_PROPERTY_NAME)
        
        var blockName = String(blockNameChars).replacingOccurrences(of: "_", with: " ")  // sanitize
        blockName = sanitize(blockName: blockName)
        
        let localizedBlockName = bundle?.localizedString(forKey: blockName, value: nil, table: "Unicode")
        
        print((localizedBlockName == blockName) ? "⚠️" : "  ", blockName, localizedBlockName)
    }
}
