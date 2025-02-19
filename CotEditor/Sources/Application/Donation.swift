//
//  Donation.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-04-28.
//
//  ---------------------------------------------------------------------------
//
//  © 2024-2025 1024jp
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

enum Donation {
    
    static let groupID = "21481959"
    
    
    enum Product: String, CaseIterable {
        
        case onetime = "com.coteditor.CotEditor.donation.onetime"
        case continuous = "com.coteditor.CotEditor.donation.subscription.yearly"
        
        var id: String  { self.rawValue }
    }
}


enum BadgeType: Int, CaseIterable {
    
    case mug
    case invisible
    
    
    var symbolName: String {
        
        switch self {
            case .mug: "mug"
            case .invisible: "circle.dotted"
        }
    }
    
    
    var label: String {
        
        switch self {
            case .mug:
                String(localized: "BadgeType.mug.label",
                       defaultValue: "Coffee Mug",
                       table: "Donation")
            case .invisible:
                String(localized: "BadgeType.invisible.label",
                       defaultValue: "Invisible Coffee",
                       table: "Donation")
        }
    }
}
