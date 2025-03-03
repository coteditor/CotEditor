//
//  FontSizeStepper.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2025-03-03.
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

struct FontSizeStepper: View {
    
    private var label: String
    @Binding private var font: NSFont
    
    
    private var fontSize: Binding<Double> {
        
        Binding(get: { self.font.pointSize },
                set: { self.font = self.font.withSize($0) })
    }
    
    
    init(_ label: String, font: Binding<NSFont>) {
        
        self.label = label
        self._font = font
    }
    
    
    var body: some View {
        
        Stepper(self.label, value: self.fontSize, in: 1...100, step: 1)
            .labelsHidden()
    }
}
