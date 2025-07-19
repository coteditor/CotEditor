//
//  TruncatingHStack.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2025-07-20.
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

struct TruncatingHStack: Layout {
    
    var spacing: Double = 8
    
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        
        let maxWidth = proposal.replacingUnspecifiedDimensions().width
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let totalWidth = sizes.map(\.width).reduce(0, +) + Double(subviews.count - 1) * self.spacing
        let maxHeight = sizes.map(\.height).reduce(0, max)
        
        return CGSize(width: min(totalWidth, maxWidth), height: maxHeight)
    }
    
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        
        var point = bounds.origin
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let width = (bounds.maxX - point.x).clamped(to: 0...size.width)
            
            subview.place(at: point, proposal: ProposedViewSize(width: width, height: bounds.height))
            point.x += size.width + self.spacing
        }
    }
}
