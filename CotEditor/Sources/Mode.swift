//
//  Mode.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-02-26.
//
//  ---------------------------------------------------------------------------
//
//  © 2024 1024jp
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
import Syntax

enum Mode: RawRepresentable, Equatable, Hashable {
    
    case kind(Syntax.Kind)
    case syntax(String)
    
    
    init?(rawValue: String) {
        
        self = if let kind = Syntax.Kind(rawValue: rawValue) {
            .kind(kind)
        } else {
            .syntax(rawValue)
        }
    }
    
    
    var rawValue: String {
        
        switch self {
            case .kind(let kind): kind.rawValue
            case .syntax(let string): string
        }
    }
    
    
    /// Localized name to display for user.
    var label: String {
        
        switch self {
            case .kind(let kind): kind.label
            case .syntax(let string): string
        }
    }
}
