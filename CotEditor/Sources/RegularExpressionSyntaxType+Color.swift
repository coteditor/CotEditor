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
//  © 2018-2023 1024jp
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

import AppKit.NSColor

extension RegularExpressionSyntaxType {
    
    var color: NSColor {
        
        switch self {
            case .character: .Regex.character
            case .backReference: .Regex.backReference
            case .symbol: .Regex.symbol
            case .quantifier: .Regex.quantifier
            case .anchor: .Regex.anchor
        }
    }
}
