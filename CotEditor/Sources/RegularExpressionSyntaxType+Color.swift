//
//  RegularExpressionSyntaxType+Color.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-12-23.
//
//  ---------------------------------------------------------------------------
//
//  © 2018 1024jp
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

extension RegularExpressionSyntaxType {
    
    var color: NSColor {
        
        guard #available(macOS 10.13, *) else { return self.literalColor }
        
        return NSColor(named: self.colorName)!
    }
    
    
    
    // MARK: Private Methods
    
    private var literalColor: NSColor {
        
        switch self {
        case .character: return #colorLiteral(red: 0.1176470596, green: 0.4011936392, blue: 0.5, alpha: 1)
        case .backReference: return #colorLiteral(red: 0.7471567648, green: 0.07381642141, blue: 0.5326599043, alpha: 1)
        case .symbol: return #colorLiteral(red: 0.7450980544, green: 0.1236130619, blue: 0.07450980693, alpha: 1)
        case .quantifier: return #colorLiteral(red: 0.4634826636, green: 0, blue: 0.6518557685, alpha: 1)
        case .anchor: return #colorLiteral(red: 0.3934386824, green: 0.5045222784, blue: 0.1255275325, alpha: 1)
        }
    }
    
    
    private var colorName: NSColor.Name {
        
        let name: String = {
            switch self {
            case .character: return "Character"
            case .backReference: return "BackReference"
            case .symbol: return "Symbol"
            case .quantifier: return "Quantifier"
            case .anchor: return "Anchor"
            }
        }()
        
        return "RegexColor/" + name
    }
    
}
