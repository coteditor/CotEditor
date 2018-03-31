/*
 
 ReplacementSet.Settings+Object.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2017-03-17.
 
 ------------------------------------------------------------------------------
 
 © 2017-2018 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 https://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Foundation

extension ReplacementSet.Settings {
    
    /// KVO-compatible object for ReplacementSet.Settings to use with the Cocoa-binding in a popover with checkboxes
    final class Object: NSObject {
        
        @objc dynamic var textIsLiteralSearch: Bool
        @objc dynamic var textIgnoresDiacriticMarks: Bool
        @objc dynamic var textIgnoresWidth: Bool
        
        @objc dynamic var regexIsSingleline: Bool
        @objc dynamic var regexIsMultiline: Bool
        @objc dynamic var regexUsesUnicodeBoundaries: Bool
        
        @objc dynamic var regexUnescapesReplacementString: Bool
        
        
        
        // MARK: - Lifecycle
        
        init(settings: ReplacementSet.Settings) {
            
            self.textIsLiteralSearch = settings.textualOptions.contains(.literal)
            self.textIgnoresDiacriticMarks = settings.textualOptions.contains(.diacriticInsensitive)
            self.textIgnoresWidth = settings.textualOptions.contains(.widthInsensitive)
            
            self.regexIsSingleline = settings.regexOptions.contains(.dotMatchesLineSeparators)
            self.regexIsMultiline = settings.regexOptions.contains(.anchorsMatchLines)
            self.regexUsesUnicodeBoundaries = settings.regexOptions.contains(.useUnicodeWordBoundaries)
            
            self.regexUnescapesReplacementString = settings.unescapesReplacementString
        }
        
        
        var settings: ReplacementSet.Settings {
            
            var textualOptions = NSString.CompareOptions()
            if self.textIsLiteralSearch        { textualOptions.update(with: .literal) }
            if self.textIgnoresDiacriticMarks  { textualOptions.update(with: .diacriticInsensitive) }
            if self.textIgnoresWidth           { textualOptions.update(with: .widthInsensitive) }
            
            var regexOptions = NSRegularExpression.Options()
            if self.regexIsSingleline          { regexOptions.update(with: .dotMatchesLineSeparators) }
            if self.regexIsMultiline           { regexOptions.update(with: .anchorsMatchLines) }
            if self.regexUsesUnicodeBoundaries { regexOptions.update(with: .useUnicodeWordBoundaries) }
            
            return ReplacementSet.Settings(textualOptions: textualOptions,
                                           regexOptions: regexOptions,
                                           unescapesReplacementString: self.regexUnescapesReplacementString)
        }
        
    }
    
}
