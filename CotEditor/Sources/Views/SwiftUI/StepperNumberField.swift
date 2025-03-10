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

struct StepperNumberField: View {
    
    @Environment(\.layoutDirection) private var layoutDirection
    
    @Binding private var value: Int
    private var defaultValue: Int?
    private var bounds: ClosedRange<Int>
    private var step: Int.Stride
    private var promptText: String?
    
    private var fieldWidth: CGFloat? = 32
    
    
    /// Creates a text field editing numeric value with a stepper.
    ///
    /// - Parameters:
    ///   - value: The underlying value to edit.
    ///   - defaultValue: The default value when the field is empty.
    ///   - bounds: A closed range that describes the upper and lower bounds permitted by the stepper.
    ///   - step: The amount to increment or decrement value each time the user clicks or taps the stepper.
    ///   - prompt: A Text which provides users with guidance on what to type into the text field.
    init(value: Binding<Int>, default defaultValue: Int? = nil, in bounds: ClosedRange<Int>, step: Int.Stride = 1, prompt: String? = nil) {
        
        self._value = value
        self.defaultValue = defaultValue
        self.bounds = bounds
        self.step = step
        self.promptText = prompt
    }
    
    
    var body: some View {
        
        HStack(spacing: 4) {
            TextField(value: $value, format: .ranged(self.bounds), prompt: self.prompt, label: EmptyView.init)
                .monospacedDigit()
                .multilineTextAlignment(self.layoutDirection == .rightToLeft ? .leading : .trailing)
                .frame(width: self.fieldWidth)
            
            Stepper(value: $value, in: self.bounds, step: self.step, label: EmptyView.init)
                .accessibilityValue(self.value.formatted())
        }
        .labelsHidden()
        .fixedSize()
    }
    
    
    private var prompt: Text? {
        
        if let defaultValue {
            Text(defaultValue, format: .number)
        } else if let promptText {
            Text(promptText)
        } else {
            nil
        }
    }
    
    
    /// Sets the input field width to the specified size.
    ///
    /// - Parameter fieldWidth: The field width.
    func fieldWidth(_ fieldWidth: CGFloat?) -> some View {
        
        var view = self
        view.fieldWidth = fieldWidth
        return view
    }
}


// MARK: - Preview

#Preview {
    @Previewable @State var value = 4
    
    StepperNumberField(value: $value, in: 0...10)
}
