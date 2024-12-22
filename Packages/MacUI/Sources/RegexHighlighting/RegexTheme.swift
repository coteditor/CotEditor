//
//  RegexTheme.swift
//  RegexHighlighting
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-07-23.
//
//  ---------------------------------------------------------------------------
//
//  © 2018-2024 1024jp
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

public struct RegexTheme<Color: Sendable>: Sendable {
    
    public var character: Color
    public var backReference: Color
    public var symbol: Color
    public var quantifier: Color
    public var anchor: Color
    
    public var invisible: Color
    
    
    public init(character: Color, backReference: Color, symbol: Color, quantifier: Color, anchor: Color, invisible: Color) {
        
        self.character = character
        self.backReference = backReference
        self.symbol = symbol
        self.quantifier = quantifier
        self.anchor = anchor
        self.invisible = invisible
    }
}


extension RegexTheme {
    
    /// The foreground color for the given syntax type.
    ///
    /// - Parameter type: The regular expression syntax type.
    /// - Returns: A color.
    func color(for type: RegexSyntaxType) -> Color {
        
        switch type {
            case .character: self.character
            case .backReference: self.backReference
            case .symbol: self.symbol
            case .quantifier: self.quantifier
            case .anchor: self.anchor
        }
    }
}
