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
//  © 2015-2018 1024jp
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
    
    private let format: CountableFormatter
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    init(format: CountableFormatter, totalUnitCount: Int = -1) {
        
        self.format = format
        
        super.init(parent: nil, userInfo: nil)
        
        self.totalUnitCount = Int64(totalUnitCount)
        self.localizedDescription = self.format.localizedString(for: 0)
    }
    
    
    
    // MARK: Progress Methods
    
    override var completedUnitCount: Int64 {
        
        didSet {
            self.localizedDescription = self.format.localizedString(for: Int(completedUnitCount))
        }
    }
    
}



// MARK: -

struct CountableFormatter {
    
    static let find = CountableFormatter(singular: "%@ string found.", plural: "%@ strings found.")
    static let replacement = CountableFormatter(singular: "%@ string replaced.", plural: "%@ strings replaced.")
    
    
    
    // MARK: Public Properties
    
    let singular: String
    let plural: String
    
    
    // MARK: Private Properties
    
    private let integerFormatter: NumberFormatter = {
        
        let formatter = NumberFormatter()
        formatter.usesGroupingSeparator = true
        formatter.numberStyle = .decimal
        return formatter
    }()
    
    
    
    // MARK: Public Methods
    
    fileprivate func localizedString(for count: Int) -> String {
        
        return String(format: self.format(for: count).localized,
                      self.integerFormatter.string(from: count as NSNumber)!)
    }
    
    
    
    // MARK: Private Methods
    
    private func format(for count: Int) -> String {
        
        switch count {
            case 0:
                return "Searching in text…".localized
            case 1:
                return self.singular
            default:
                return self.plural
        }
    }
    
}
