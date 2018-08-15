//
//  HexColorTransformer.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2014-09-12.
//
//  ---------------------------------------------------------------------------
//
//  © 2014-2018 1024jp
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

import Foundation
import AppKit.NSColor
import ColorCode

final class HexColorTransformer: ValueTransformer {
    
    // MARK: Public Properties
    
    static let name = NSValueTransformerName("HexColorTransformer")
    
    
    
    // MARK: -
    // MARK: Value Transformer Methods
    
    /// Class of transformed value
    override class func transformedValueClass() -> AnyClass {
        
        return NSString.self
    }
    
    
    /// Can reverse transformeation?
    override class func allowsReverseTransformation() -> Bool {
        
        return true
    }
    
    
    /// From color code hex to NSColor (String -> NSColor)
    override func transformedValue(_ value: Any?) -> Any? {
        
        guard let code = value as? String else { return nil }
        
        var type: ColorCodeType?
        let color = NSColor(colorCode: code, type: &type)
        
        guard type == .hex || type == .shortHex else { return nil }
        
        return color
    }
    
    
    /// From NSColor to hex color code string (NSColor -> String)
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        
        let color = value as? NSColor ?? .black
        
        let sanitizedColor = color.usingColorSpace(.genericRGB)
        
        return sanitizedColor?.colorCode(type: .hex)
    }
    
}
