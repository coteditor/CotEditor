//
//  OpacitySlider.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-02-18.
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

import SwiftUI

struct OpacitySlider: View {
    
    @Binding var value: Double
    
    var bounds: ClosedRange<Double> = 0.2...1
    var step: Double?
    
    
    var body: some View {
        
        if let step {
            Slider(value: $value, in: self.bounds, step: step) {
                EmptyView()
            } minimumValueLabel: {
                OpacitySample(opacity: self.bounds.lowerBound)
                    .help(self.minimumHelp)
            } maximumValueLabel: {
                OpacitySample(opacity: self.bounds.upperBound)
                    .help(self.maximumHelp)
            }
        } else {
            Slider(value: $value, in: self.bounds) {
                EmptyView()
            } minimumValueLabel: {
                OpacitySample(opacity: self.bounds.lowerBound)
                    .help(self.minimumHelp)
            } maximumValueLabel: {
                OpacitySample(opacity: self.bounds.upperBound)
                    .help(self.maximumHelp)
            }
        }
    }
    
    
    private var minimumHelp: String {
        
        String(localized: "Transparent", table: "OpacitySlider", comment: "tooltip for min label in opacity slider")
    }
    
    
    private var maximumHelp: String {
        
        String(localized: "Opaque", table: "OpacitySlider", comment: "tooltip for max label in opacity slider")
    }
}


private struct OpacitySample: View {
    
    let opacity: Double
    
    private let inset: Double = 3
    
    
    var body: some View {
        
        GeometryReader { geometry in
            let radius = geometry.size.height / 4
            
            ZStack {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(.background)
                
                Triangle()
                    .fill(.primary)
                    .opacity(1 - self.opacity)
                    .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .inset(by: self.inset))
                
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .inset(by: 0.5)
                    .stroke(.tertiary, lineWidth: 1)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(height: 16)
    }
    
    
    private struct Triangle: Shape {
        
        func path(in rect: CGRect) -> Path {
            
            Path { path in
                path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
                path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
                path.closeSubpath()
            }
        }
    }
}



// MARK: - Preview

@available(macOS 14, *)
#Preview(traits: .fixedLayout(width: 200, height: 50)) {
    
    VStack {
        OpacitySlider(value: .constant(0.6))
        OpacitySlider(value: .constant(0.6), step: 0.2)
    }
    .padding()
}

#Preview("OpacitySample") {
    OpacitySample(opacity: 0.5)
        .frame(width: 16, height: 16)
}
