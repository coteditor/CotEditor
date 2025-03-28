//
//  SubmitButtonGroup.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2023-01-18.
//
//  ---------------------------------------------------------------------------
//
//  © 2023-2025 1024jp
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

struct SubmitButtonGroup: View {
    
    private var submitLabel: String
    private var submitAction: () -> Void
    private var cancelAction: () -> Void
    
    
    // MARK: View
    
    /// Creates two buttons with the same width; one is the cancel button and another is the submit button.
    ///
    /// - Parameters:
    ///   - submitLabel: The label to be displayed in the submit button, or `nil` for the default "OK."
    ///   - action: The action invoked when the submit button was pressed.
    ///   - cancelAction: The action invoked when the cancel button was pressed.
    init(_ submitLabel: String? = nil, action: @escaping () -> Void, cancelAction: @escaping () -> Void) {
        
        self.submitLabel = submitLabel ?? String(localized: "OK")
        self.submitAction = action
        self.cancelAction = cancelAction
    }
    
    
    var body: some View {
        
        EqualWidthHStack {
            Button(role: .cancel, action: self.cancelAction) {
                Text("Cancel")
                    .frame(maxWidth: .infinity)
            }
            .keyboardShortcut(.cancelAction)
            .environment(\.isEnabled, true)  // Cancel button is always active
            
            Button(action: self.submitAction) {
                Text(self.submitLabel)
                    .frame(maxWidth: .infinity)
            }
            .keyboardShortcut(.defaultAction)
        }
    }
}


/// cf. [Compose custom layouts with SwiftUI](https://developer.apple.com/wwdc22/10056)
private struct EqualWidthHStack: Layout {
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        
        guard !subviews.isEmpty else { return .zero }
        
        let maxSize = self.maxSize(subviews: subviews)
        let spacings = self.spacings(subviews: subviews)
        
        return CGSize(width: maxSize.width * CGFloat(subviews.count) + spacings.reduce(0, +),
                      height: maxSize.height)
    }
    
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        
        guard !subviews.isEmpty else { return }
        
        let maxSize = self.maxSize(subviews: subviews)
        let spacings = self.spacings(subviews: subviews)
        
        let proposal = ProposedViewSize(maxSize)
        var x = bounds.minX + maxSize.width / 2
        
        for (subview, spacing) in zip(subviews, spacings) {
            subview.place(at: CGPoint(x: x, y: bounds.midY), anchor: .center, proposal: proposal)
            x += maxSize.width + spacing
        }
    }
    
    
    private func maxSize(subviews: Subviews) -> CGSize {
        
        subviews
            .map { $0.sizeThatFits(.unspecified) }
            .reduce(.zero) { currentMax, subviewSize in
                CGSize(width: max(currentMax.width, subviewSize.width),
                       height: max(currentMax.height, subviewSize.height))
            }
    }
    
    
    private func spacings(subviews: Subviews) -> [CGFloat] {
        
        subviews.indices.map { index in
            guard index < subviews.count - 1 else { return 0 }
            
            return subviews[index].spacing
                .distance(to: subviews[index + 1].spacing, along: .horizontal)
        }
    }
}


// MARK: - Preview

#Preview {
    HStack {
        Spacer()
        SubmitButtonGroup(action: {}, cancelAction: {})
    }
    .padding()
    .frame(width: 200)
}
