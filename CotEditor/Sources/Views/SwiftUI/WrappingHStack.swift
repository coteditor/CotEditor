//
//  WrappingHStack.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-02-10.
//
//  ---------------------------------------------------------------------------
//
//  © 2024-2026 1024jp
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

struct WrappingHStack<Content: View>: View {
    
    var alignment: HorizontalAlignment = .leading
    var horizontalSpacing: Double = 4
    var verticalSpacing: Double = 4
    @ViewBuilder var content: Content
    
    
    var body: some View {
        
        WrappingHStackLayout(alignment: self.alignment, horizontalSpacing: self.horizontalSpacing, verticalSpacing: self.verticalSpacing) {
            self.content
        }
    }
}


private struct WrappingHStackLayout: Layout {
    
    private struct Row {
        
        var indices: [Int] = []
        var width: Double = 0
    }
    
    
    var alignment: HorizontalAlignment
    var horizontalSpacing: Double
    var verticalSpacing: Double
    
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        
        let rows = self.rows(for: subviews, in: proposal.width ?? .infinity)
        let width = proposal.width ?? rows.map(\.width).max() ?? 0
        let rowCount = Double(rows.count)
        let rowHeight = subviews.map { $0.sizeThatFits(.unspecified).height }.max()?.rounded(.up) ?? 0
        let height = rowCount * rowHeight + max(rowCount - 1, 0) * self.verticalSpacing
        
        return CGSize(width: width, height: height)
    }
    
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        
        let rows = self.rows(for: subviews, in: bounds.width)
        let rowHeight = subviews.map { $0.sizeThatFits(.unspecified).height }.max()?.rounded(.up) ?? 0
        var y = bounds.minY
        
        for row in rows {
            var x = bounds.minX + self.xOffset(for: row.width, in: bounds.width)
            
            for index in row.indices {
                let subview = subviews[index]
                let size = subview.sizeThatFits(.unspecified)
                
                subview.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: ProposedViewSize(size))
                x += size.width + self.horizontalSpacing
            }
            
            y += rowHeight + self.verticalSpacing
        }
    }
    
    
    /// Calculates the horizontal offset for a row within the given container width.
    ///
    /// - Note:
    ///   Only `.leading`, `.center`, and `.trailing` are supported.
    ///   Any other `HorizontalAlignment` value falls back to leading alignment.
    ///
    /// - Parameters:
    ///   - rowWidth: The total width of the row.
    ///   - containerWidth: The available width of the container.
    /// - Returns: The leading offset for placing the row.
    private func xOffset(for rowWidth: Double, in containerWidth: Double) -> Double {
        
        switch self.alignment {
            case .leading: 0
            case .center: max(containerWidth - rowWidth, 0) / 2
            case .trailing: max(containerWidth - rowWidth, 0)
            default: 0
        }
    }
    
    
    /// Groups subviews into rows that fit within the given container width.
    ///
    /// - Parameters:
    ///   - subviews: The subviews to lay out.
    ///   - containerWidth: The available width of the container.
    /// - Returns: The rows with their indices and measured widths.
    private func rows(for subviews: Subviews, in containerWidth: Double) -> [Row] {
        
        var rows: [Row] = []
        var row = Row()
        
        for index in subviews.indices {
            let width = subviews[index].sizeThatFits(.unspecified).width
            let rowWidth = row.indices.isEmpty ? width : row.width + self.horizontalSpacing + width
            
            if !row.indices.isEmpty, rowWidth > containerWidth {
                rows.append(row)
                row = Row(indices: [index], width: width)
            } else {
                row.indices.append(index)
                row.width = rowWidth
            }
        }
        
        if !row.indices.isEmpty {
            rows.append(row)
        }
        
        return rows
    }
}


// MARK: - Preview

#Preview {
    WrappingHStack {
        ForEach(["Lorem", "ipsum", "dolor", "sit", "amet", "consectetur", "adipiscing", "elit", "sed", "do"], id: \.self) { word in
            Text(word)
                .monospacedDigit()
                .padding(.horizontal, 2)
                .background(.selection, in: .rect(cornerRadius: 3))
        }
    }
    .border(.separator)
    .padding()
    .frame(width: 180)
}
