/*
 
 String+JapaneseTransform.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2014-07-31.
 
 ------------------------------------------------------------------------------
 
 © 2014-2016 1024jp
 
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

extension String {
    
    // MARK: Public Properties
    
    /// transform half-width roman to full-width
    var fullWidthRoman: String {
        
        var string = ""
        
        for scalar in self.unicodeScalars {
            if String.latinCharacterRange.contains(scalar) {
                string.append(UnicodeScalar(scalar.value + String.characterWidthDistance))
            } else {
                string.append(scalar)
            }
        }
        
        return string
    }
    
    
    /// transform full-width roman to half-width
    var halfWidthRoman: String {
        
        var string = ""
        
        for scalar in self.unicodeScalars {
            if String.fullWidthCharacterRange.contains(scalar) {
                string.append(UnicodeScalar(scalar.value - String.characterWidthDistance))
            } else {
                string.append(scalar)
            }
        }
        
        return string
    }
    
    
    /// transform Japanese Katakana to Hiragana
    var katakana: String {
        
        let string = NSMutableString(string: self)
        
        CFStringTransform(string, nil, kCFStringTransformHiraganaKatakana, false)
        
        return string as String
    }
    
    
    /// transform Japanese Hiragana to Katakana
    var hiragana: String {
        
        let string = NSMutableString(string: self)
        
        CFStringTransform(string, nil, kCFStringTransformHiraganaKatakana, true)
        
        return string as String
    }
    
    
    // MARK: Private Properties
    
    private static let latinCharacterRange: ClosedRange<UnicodeScalar> = "!"..."~"
    private static let fullWidthCharacterRange: ClosedRange<UnicodeScalar> = "！"..."～"
    private static let characterWidthDistance = UnicodeScalar("！").value - UnicodeScalar("!").value
    
}
