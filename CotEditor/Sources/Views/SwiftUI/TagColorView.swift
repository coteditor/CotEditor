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

struct TagsView: View {
    
    var tags: [FinderTag]
    var isSelected = false
    
    var offset: Double = 5
    
    
    var body: some View {
        
        let tags = self.tags.filter { $0.color != .none }
        let description = tags.map(\.name).formatted(.list(type: .and, width: .short))
        
        ZStack(alignment: .trailing) {
            ForEach(Array(tags.enumerated()), id: \.offset) { (index, tag) in
                TagColorView(color: tag.color)
                    .overlay {
                        if self.isSelected {
                            Circle()
                                .strokeBorder(.white.opacity(0.9), lineWidth: 0.9)
                        }
                    }
                    .mask {
                        Rectangle()
                            .overlay {
                                if index < tags.count - 1 {
                                    Circle()
                                        .inset(by: -1)
                                        .blendMode(.destinationOut)
                                        .offset(x: -self.offset)
                                }
                            }
                    }
                    .padding(.trailing, Double(index) * self.offset)
            }
        }
        .help(description)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(description)
    }
}


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

#Preview("TagsView") {
    TagsView(tags: [
        FinderTag(name: "Green", color: .green),
        FinderTag(name: "Blue", color: .blue),
        FinderTag(name: "Purple", color: .purple)
    ])
    .frame(height: 12)
    .padding()
}

#Preview {
    HStack {
        ForEach(FinderTag.Color.allCases, id: \.rawValue) { color in
            TagColorView(color: color)
        }
    }
    .frame(height: 14)
    .padding()
}
