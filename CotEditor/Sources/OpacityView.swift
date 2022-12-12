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
//  © 2022 1024jp
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
        
        self.init(rootView: OpacityView())
        
        self.ensureFrameSize()
        self.rootView.window = window
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        
        // Implementing `init(coder:)` is required for toolbar item menu representation.
        super.init(rootView: OpacityView())
        
        self.ensureFrameSize()
        self.rootView.window = NSDocumentController.shared.currentDocument?.windowControllers.first?.window as? DocumentWindow
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
                .foregroundColor(.secondary)
            
            HStack(alignment: .center) {
                OpacitySample(opacity: 0.2)
                    .help("Transparent")
                    .frame(width: 16, height: 16)
                
                Slider(value: $opacity, in: 0.2...1)
                    .controlSize(.small)
                    .frame(width: 100)
                
                OpacitySample(opacity: 1)
                    .help("Opaque")
                    .frame(width: 16, height: 16)
            }
        }
        .onAppear {
            if let window {
                self.opacity = window.backgroundAlpha
            }
        }
        .onChange(of: self.opacity) { newValue in
            self.window?.backgroundAlpha = newValue
        }
        .padding(10)
    }
}



private struct OpacitySample: View {
    
    let opacity: Double
    var inset: Double = 3
    
    
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
