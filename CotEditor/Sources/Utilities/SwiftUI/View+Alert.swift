//
//  View+Alert.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2023-11-12.
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

extension View {
    
    /// Presents an alert with a message when an error is present.
    ///
    /// - Parameters:
    ///   - error: An optional Error that is used to generate the alert.
    ///   - buttonTitle: The title for the button in the alert panel, or `nil` for the default "OK."
    func alert(error: Binding<(some Error)?>, buttonTitle: String? = nil) -> some View {
        
        let localizedError = LocalizedAlertError(error.wrappedValue)
        
        return self.alert(isPresented: .constant(localizedError != nil), error: localizedError) { _ in
            Button(buttonTitle ?? String(localized: "OK")) {
                error.wrappedValue = nil
            }
        } message: { error in
            Text(error.recoverySuggestion ?? "")
        }
    }
}


// MARK: Private Structs

private struct LocalizedAlertError: LocalizedError {
    
    private var underlyingError: any LocalizedError
    
    
    /// Creates an existential error confirms to `LocalizedError` protocol from a general `Swift.Error`.
    init?(_ error: (some Error)?) {
        
        guard let localizedError = error as? any LocalizedError else { return nil }
        
        self.underlyingError = localizedError
    }
    
    
    var errorDescription: String? {
        
        self.underlyingError.errorDescription
    }
    
    
    var recoverySuggestion: String? {
        
        self.underlyingError.recoverySuggestion
    }
}
