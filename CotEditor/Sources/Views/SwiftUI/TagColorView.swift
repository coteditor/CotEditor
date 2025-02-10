//
//  TagColorView.swift
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

import SwiftUI

struct TagColorView: View {
    
    var color: FinderTag.Color
    
    
    var body: some View {
        
        Circle()
            .strokeBorder((self.color == .none) ? .secondary : self.color.color)
            .fill(self.color.color.opacity(0.82))
            .aspectRatio(1, contentMode: .fit)
            .accessibilityHidden(true)
    }
}


private extension FinderTag.Color {
    
    var color: SwiftUI.Color {
        
        switch self {
            case .none: .clear
            case .gray: .gray
            case .green: .green
            case .purple: .purple
            case .blue: .blue
            case .yellow: .yellow
            case .red: .red
            case .orange: .orange
        }
    }
}


// MARK: - Preview

#Preview {
    HStack {
        ForEach(FinderTag.Color.allCases, id: \.rawValue) { color in
            TagColorView(color: color)
        }
    }
    .frame(height: 14)
    .padding()
}
