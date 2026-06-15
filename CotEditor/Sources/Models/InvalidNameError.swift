//
//  InvalidNameError.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-06-15.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2026 1024jp
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

enum InvalidNameError: LocalizedError {
    
    case empty
    case tooLong
    case invalidCharacter(String)
    case newLine
    case startWithDot
    case duplicated(name: String)
    case reserved(name: String)
    
    
    var errorDescription: String? {
        
        switch self {
            case .empty:
                String(localized: "InvalidNameError.empty.description",
                       defaultValue: "Name can’t be empty.")
            case .tooLong:
                String(localized: "InvalidNameError.tooLong.description",
                       defaultValue: "The name is too long.")
            case .invalidCharacter(let string):
                String(localized: "InvalidNameError.invalidCharacter.description",
                       defaultValue: "Name can’t contain “\(string)”.",
                       comment: "%@ is the character invalid for filename")
            case .newLine:
                String(localized: "InvalidNameError.newLine.description",
                       defaultValue: "Name can’t contain new lines.")
            case .startWithDot:
                String(localized: "InvalidNameError.startWithDot.description",
                       defaultValue: "Name can’t begin with “.”.")
            case .duplicated(let name):
                String(localized: "InvalidNameError.duplicated.description",
                       defaultValue: "The name “\(name)” is already taken.")
            case .reserved(let name):
                String(localized: "InvalidNameError.reserved.description",
                       defaultValue: "The name “\(name)” is reserved.")
        }
    }
    
    
    var recoverySuggestion: String? {
        
        String(localized: "InvalidNameError.recoverySuggestion",
               defaultValue: "Choose another name.")
    }
}
