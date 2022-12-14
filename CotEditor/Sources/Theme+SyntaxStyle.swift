//
//  Theme+SyntaxStyle.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2021-04-21.
//
//  ---------------------------------------------------------------------------
//
//  © 2021 1024jp
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

extension Theme {
    
    /// Return the theme style correspondent to the syntax style type.
    ///
    /// - Parameter type: The syntax style type.
    /// - Returns: A theme style.
    func style(for type: SyntaxType) -> Style? {
        
        // The syntax keys and theme keys must be the same.
        switch type {
            case .keywords: return self.keywords
            case .commands: return self.commands
            case .types: return self.types
            case .attributes: return self.attributes
            case .variables: return self.variables
            case .values: return self.values
            case .numbers: return self.numbers
            case .strings: return self.strings
            case .characters: return self.characters
            case .comments: return self.comments
        }
    }
}
