//
//  OpacityView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2022-12-11.
//
//  ---------------------------------------------------------------------------
//
//  © 2022-2023 1024jp
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

@MainActor final class OpacityHostingView: NSHostingView<OpacityView> {
    
    convenience init(window: DocumentWindow?) {
        
        assert(window != nil)
        
        self.init(rootView: OpacityView(window: window))
        
        self.ensureFrameSize()
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        
        // Implementing `init(coder:)` is required for toolbar item menu representation.
        
        let window = NSDocumentController.shared.currentDocument?.windowControllers.first?.window as? DocumentWindow
        assert(window != nil)
        
        super.init(rootView: OpacityView(window: window))
        
        self.ensureFrameSize()
    }
    
    
    @MainActor required init(rootView: OpacityView) {
        
        super.init(rootView: rootView)
    }
}



struct OpacityView: View {
    
    weak var window: DocumentWindow?
    
    @State private var opacity: Double = 1
    
    
    var body: some View {
        
        VStack(alignment: .leading) {
            Text("Editor’s Opacity")
                .fontWeight(.semibold)
                .foregroundColor(.secondaryLabel)
                .labelsHidden()
            
            OpacitySlider(value: $opacity)
                .onChange(of: self.opacity) { newValue in
                    self.window?.backgroundAlpha = newValue
                }
                .controlSize(.small)
                .frame(width: 160)
        }
        .onAppear {
            if let window {
                self.opacity = window.backgroundAlpha
            }
        }
        .padding(10)
    }
}



private struct OpacitySlider: View {
    
    @Binding private var value: Double
    
    private let bounds: ClosedRange<Double>
    private let label: LocalizedStringKey?
    
    
    init(_ label: LocalizedStringKey? = nil, value: Binding<Double>, in bounds: ClosedRange<Double> = 0.2...1) {
        
        self._value = value
        self.bounds = bounds
        self.label = label
    }
    
    
    var body: some View {
        
        Slider(value: $value, in: self.bounds) {
            if let label {
                Text(label)
            } else {
                EmptyView()
            }
        } minimumValueLabel: {
            OpacitySample(opacity: self.bounds.lowerBound)
                .help("Transparent")
                .frame(width: 16, height: 16)
        } maximumValueLabel: {
            OpacitySample(opacity: self.bounds.upperBound)
                .help("Opaque")
                .frame(width: 16, height: 16)
        }
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
                    .stroke(.primary.opacity(0.25), lineWidth: 1)
            }
        }
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

struct OpacityView_Previews: PreviewProvider {
    
    static var previews: some View {
        
        OpacityView()
        
        OpacitySample(opacity: 0.5)
            .frame(width: 16, height: 16)
    }
}
