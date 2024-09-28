//
//  Binding.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2023-09-03.
//
//  ---------------------------------------------------------------------------
//
//  © 2023-2024 1024jp
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

// MARK: OptionSet

extension Binding where Self: Sendable, Value: OptionSet, Value.Element: Sendable {
    
    /// Enables binding to an option using Bool.
    ///
    /// - Parameter options: The option to bind.
    /// - Returns: A `Binding<Bool>` struct.
    func bind(_ options: Value.Element) -> Binding<Bool> {
        
        .init(
            get: {
                self.wrappedValue.contains(options)
            },
            set: { newValue in
                if newValue {
                    self.wrappedValue.insert(options)
                } else {
                    self.wrappedValue.remove(options)
                }
            }
        )
    }
}


// MARK: Optional Binding

func ?? <T: Sendable>(lhs: Binding<T?>, rhs: T) -> Binding<T> {
    
    Binding(
        get: { lhs.wrappedValue ?? rhs },
        set: { lhs.wrappedValue = $0 }
    )
}


func ?? (lhs: Binding<String?>, rhs: String) -> Binding<String> {
    
    Binding(
        get: { lhs.wrappedValue ?? rhs },
        set: { lhs.wrappedValue = $0.isEmpty ? nil : $0 }
    )
}
