//
//  TextFindProgress.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2017-02-02.
//
//  ---------------------------------------------------------------------------
//
//  © 2015-2022 1024jp
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

final class TextFindProgress: Progress {
    
    // MARK: Private Properties
    
    private let format: CountableFormat
    private var _localizedDescription: String?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    init(format: CountableFormat, totalUnitCount: Int = -1) {
        
        self.format = format
        
        super.init(parent: nil, userInfo: nil)
        
        self.totalUnitCount = Int64(totalUnitCount)
    }
    
    
    
    // MARK: Progress Methods
    
    override var localizedDescription: String! {
        
        // -> KVO is sacrificed for the performance.
        get { self._localizedDescription ?? self.format.localizedString(for: Int(self.completedUnitCount)) }
        set { self._localizedDescription = newValue }
    }
    
}



// MARK: -

enum CountableFormat {
    
    case find
    case replacement
    
    
    
    // MARK: Public Methods
    
    fileprivate func localizedString(for count: Int) -> String {
        
        String(localized: self.format(for: count))
    }
    
    
    
    // MARK: Private Methods
    
    private func format(for count: Int) -> String.LocalizationValue {
        
        switch count {
            case 0:
                return "Searching in text…"
            case 1:
                switch self {
                    case .find:
                        return "\(count) string found."
                    case .replacement:
                        return "\(count) string replaced."
                }
            default:
                switch self {
                    case .find:
                        return "\(count) strings found."
                    case .replacement:
                        return "\(count) strings replaced."
                }
        }
    }
    
}
