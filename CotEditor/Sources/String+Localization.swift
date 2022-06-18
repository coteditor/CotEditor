//
//  String+Localization.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-07-14.
//
//  ---------------------------------------------------------------------------
//
//  © 2018-2022 1024jp
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

extension String {
    
    /// Cocoa localized string
    var localized: String {
        
        NSLocalizedString(self, comment: "")
    }
    
    
    /// returns a localized string, using the main bundle if one is not specified.
    func localized(tableName: String) -> String {
        
        NSLocalizedString(self, tableName: tableName, comment: "")
    }
    
}
