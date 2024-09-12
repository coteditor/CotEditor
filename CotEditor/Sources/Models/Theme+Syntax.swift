//
//  Theme+Syntax.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2021-04-21.
//
//  ---------------------------------------------------------------------------
//
//  © 2021-2024 1024jp
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

import Syntax

extension Theme {
    
    /// Returns the theme style correspondent to the syntax type.
    ///
    /// - Parameter type: The syntax type.
    /// - Returns: A theme style.
    func style(for type: SyntaxType) -> Style? {
        
        // The syntax keys and theme keys must be the same.
        switch type {
            case .keywords: self.keywords
            case .commands: self.commands
            case .types: self.types
            case .attributes: self.attributes
            case .variables: self.variables
            case .values: self.values
            case .numbers: self.numbers
            case .strings: self.strings
            case .characters: self.characters
            case .comments: self.comments
        }
    }
}
