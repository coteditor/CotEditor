//
//  CSVFormatStyle.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-05-08.
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

extension FormatStyle where Self == CSVFormatStyle {
    
    static var csv: CSVFormatStyle {
        
        CSVFormatStyle()
    }
    
    
    /// Joined a string list using a separator character.
    ///
    ///  - Note: This style works only with a simple CSV assuming all items are consist of alphanumeric characters.
    ///
    /// - Parameters:
    ///   - separator: The separator of CSV.
    ///   - omittingEmptyItems: If `true`, empty items are removed from the list.
    /// - Returns: A RangedIntegerFormatStyle.
    static func csv(separator: String = ",", omittingEmptyItems: Bool = false) -> CSVFormatStyle {
        
        return CSVFormatStyle(separator: separator, omittingEmptyItems: omittingEmptyItems)
    }
}


struct CSVFormatStyle: Codable {
    
    var separator: String = ","
    var omittingEmptyItems: Bool = false
}


extension CSVFormatStyle: FormatStyle {
    
    typealias FormatInput = [String]
    typealias FormatOutput = String
    
    
    func format(_ value: [String]) -> String {
        
        value
            .filter { !self.omittingEmptyItems || !$0.isEmpty }
            .joined(separator: self.separator + " ")
    }
}


extension CSVFormatStyle: ParseableFormatStyle {
    
    typealias Strategy = CSVParseStrategy
    
    
    struct CSVParseStrategy: ParseStrategy {
        
        var style: CSVFormatStyle
        
        
        func parse(_ value: String) throws -> [String] {
            
            value.split(separator: self.style.separator, omittingEmptySubsequences: self.style.omittingEmptyItems)
                .map { $0.trimmingCharacters(in: .whitespaces) }
        }
    }
    
    
    var parseStrategy: CSVParseStrategy {
        
        CSVParseStrategy(style: self)
    }
}
