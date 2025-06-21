//
//  StatusImage.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2025-06-21.
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

import SwiftUI

struct StatusImage: View {
    
    enum Status {
        
        case none
        case unavailable
        case partiallyAvailable
        case available
    }
    
    
    var status: Status
    
    
    var body: some View {
        
        switch self.status {
            case .none:
                Image(systemName: "circle")
                    .foregroundStyle(.tertiary)
            default:
                Image(systemName: self.symbolName)
                    .symbolVariant(.circle.fill)
                    .fontWeight(.semibold)
                    .foregroundStyle(self.color)
                    .saturation(0.9)
        }
    }
    
    
    private var color: Color {
        
        switch self.status {
            case .none: fatalError()
            case .unavailable: .red
            case .partiallyAvailable: .orange
            case .available: .green
        }
    }
    
    
    private var symbolName: String {
        
        switch self.status {
            case .none: fatalError()
            case .unavailable: "xmark"
            case .partiallyAvailable: "exclamationmark"
            case .available: "checkmark"
        }
    }
}


// MARK: - Preview

#Preview {
    VStack(alignment: .leading, spacing: 6) {
        Label(title: { Text("none") }, icon: { StatusImage(status: .none) })
        Label(title: { Text("available") }, icon: { StatusImage(status: .available) })
        Label(title: { Text("partiallyAvailable") }, icon: { StatusImage(status: .partiallyAvailable) })
        Label(title: { Text("unavailable") }, icon: { StatusImage(status: .unavailable) })
    }.padding()
}
