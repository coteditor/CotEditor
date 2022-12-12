//
//  StepperNumberField.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2023-01-18.
//
//  ---------------------------------------------------------------------------
//
//  © 2023 1024jp
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

struct StepperNumberField: View {
    
    @Binding private var value: Int
    private var bounds: ClosedRange<Int>
    private var step: Int.Stride
    private var prompt: Text?
    
    
    /// Create a text field editing numerical value with a stepper.
    ///
    /// - Parameters:
    ///   - value: The underlying value to edit.
    ///   - bounds: A closed range that describes the upper and lower bounds permitted by the stepper.
    ///   - step: The amount to increment or decrement value each time the user clicks or taps the stepper.
    ///   - prompt: A Text which provides users with guidance on what to type into the text field.
    init(value: Binding<Int>, in bounds: ClosedRange<Int>, step: Int.Stride = 1, prompt: Text? = nil) {
        
        self._value = value
        self.bounds = bounds
        self.step = step
        self.prompt = prompt
    }
    
    
    var body: some View {
        
        HStack(spacing: 4) {
            TextField("", value: $value, format: .ranged(self.bounds), prompt: self.prompt)
                .monospacedDigit()
                .multilineTextAlignment(.trailing)
                .frame(width: 32)
            Stepper("", value: $value, in: self.bounds, step: self.step)
        }
        .labelsHidden()
        .fixedSize()
    }
}



// MARK: - Preview

struct StepperNumberField_Previews: PreviewProvider {
    
    static var previews: some View {
        
        StepperNumberField(value: .constant(4), in: 0...10)
    }
}
