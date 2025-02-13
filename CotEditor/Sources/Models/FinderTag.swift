//
//  FinderTag.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2025-02-10.
//
//  ---------------------------------------------------------------------------
//
//  © 2025 1024jp
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

struct FinderTag: Equatable {
    
    enum Color: Int, CaseIterable {
        
        case none
        case gray
        case green
        case purple
        case blue
        case yellow
        case red
        case orange
        
        
        /// The color list ordered like in the Finder (2025-02, macOS 15).
        static let allCases: [Self] = [.none, .red, .orange, .yellow, .green, .blue, .purple, .gray]
    }
    
    
    var name: String
    var color: Color = .none
}

 
extension FinderTag {
    
    /// Parses tags from the extended attribute data.
    ///
    /// - Parameter data: The bplist data.
    /// - Returns: `FinderTag`s.
    static func tags(data: Data) -> [Self] {
        
        // -> The data is encoded as bplist.
        guard let strings = try? PropertyListDecoder().decode([String].self, from: data) else { return [] }
        
        return strings.compactMap(Self.init(string:))
    }
    
    
    /// Instantiates a Finder tag from the string stored in the extended attributes.
    ///
    /// - Parameter string: The string stored in the extended attributes.
    private init?(string: String) {
        
        let components = string.split(separator: "\n")
        
        guard let name = components.first else { return nil }
        
        self.name = String(name)
        
        if components.count > 1,
           let number = Int(components[1]),
           let color = Color(rawValue: number)
        {
            self.color = color
        }
    }
}
