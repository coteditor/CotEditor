//
//  Invisible+UserDefaults.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-01-03.
//
//  ---------------------------------------------------------------------------
//
//  © 2014-2024 1024jp
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

import class Foundation.UserDefaults
import Defaults
import Invisible

extension Invisible {
    
    var visibilityDefaultKey: DefaultKey<Bool> {
        
        switch self {
            case .newLine: .showInvisibleNewLine
            case .tab: .showInvisibleTab
            case .space: .showInvisibleSpace
            case .noBreakSpace: .showInvisibleWhitespaces
            case .fullwidthSpace: .showInvisibleWhitespaces
            case .otherWhitespace: .showInvisibleWhitespaces
            case .otherControl: .showInvisibleControl
        }
    }
}


extension UserDefaults {
    
    var showsInvisible: Set<Invisible> {
        
        let invisibles = Invisible.allCases
            .filter { self[$0.visibilityDefaultKey] }
        
        return Set(invisibles)
    }
}
