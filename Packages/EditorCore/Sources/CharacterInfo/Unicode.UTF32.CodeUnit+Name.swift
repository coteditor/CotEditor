//
//  UTF32.CodeUnit+Name.swift
//  CharacterInfo
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-07-26.
//
//  ---------------------------------------------------------------------------
//
//  © 2015-2025 1024jp
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

public extension Unicode.UTF32.CodeUnit {
    
    /// Returns Unicode name.
    ///
    /// Implemented at UTF32.CodeUnit level in order to cover single surrogate characters
    /// that are not allowed by Unicode.Scalar.
    var unicodeName: String? {
        
        if let name = Unicode.Scalar(self)?.name {
            return name
        }
        
        if let codeUnit = UTF16.CodeUnit(exactly: self) {
            if UTF16.isLeadSurrogate(codeUnit) {
                return "<lead surrogate-\(codeUnit.codePoint)>"
            }
            if UTF16.isTrailSurrogate(codeUnit) {
                return "<tail surrogate-\(codeUnit.codePoint)>"
            }
        }
        
        return nil
    }
}
