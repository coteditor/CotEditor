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

import SwiftUI

struct WrappingHStack<Content: View>: View {
    
    var horizontalSpacing: Double = 4
    var verticalSpacing: Double = 4
    @ViewBuilder var content: () -> Content
    
    
    var body: some View {
        
        WrappingHStackLayout(horizontalSpacing: self.horizontalSpacing, verticalSpacing: self.verticalSpacing) {
            self.content()
        }
    }
}


private struct WrappingHStackLayout: Layout {
    
    var horizontalSpacing: Double
    var verticalSpacing: Double
    
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        
        let width = proposal.replacingUnspecifiedDimensions().width
        let rowCount = Double(self.countRows(for: subviews, in: width))
        let minHeight = subviews.map { $0.sizeThatFits(proposal).height }.max()?.rounded(.up) ?? 0
        let height = rowCount * minHeight + max(rowCount - 1, 0) * self.verticalSpacing
        
        return CGSize(width: width, height: height)
    }
    
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        
        let minHeight = subviews.map { $0.sizeThatFits(proposal).height }.max()?.rounded(.up) ?? 0
        var point = bounds.origin
        
        for subview in subviews {
            let width = subview.sizeThatFits(proposal).width
            
            if point.x + width > bounds.maxX {
                point.x = bounds.minX
                point.y += minHeight + self.verticalSpacing
            }
            
            subview.place(at: point, anchor: .topLeading, proposal: proposal)
            point.x += width + self.horizontalSpacing
        }
    }
    
    
    /// Calculates the number of rows when the subviews are laid out within the given `containerWidth`.
    ///
    /// - Parameters:
    ///   - subviews: The subviews to lay out.
    ///   - containerWidth: The width of the view to fit in.
    /// - Returns: The number of rows.
    private func countRows(for subviews: Subviews, in containerWidth: Double) -> Int {
        
        var count = 0
        var x: Double = 0
        
        for subview in subviews {
            let width = subview.sizeThatFits(.unspecified).width
            
            if x + width > containerWidth {
                x = 0
                count += 1
            }
            x += width + self.horizontalSpacing
        }
        
        if x > 0 {
            count += 1
        }
        
        return count
    }
}


// MARK: - Preview

#Preview {
    WrappingHStack {
        ForEach(["Lorem", "ipsum", "dolor", "sit", "amet", "consectetur", "adipiscing", "elit", "sed", "do"], id: \.self) {
            Text($0)
                .monospacedDigit()
                .padding(.horizontal, 2)
                .background(.selection, in: .rect(cornerRadius: 3))
        }
    }
    .border(.separator)
    .padding()
    .frame(width: 180)
}
