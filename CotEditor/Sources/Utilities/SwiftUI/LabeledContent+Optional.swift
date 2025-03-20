//
//  LabeledContent+Optional.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2025-01-07.
//
//  ---------------------------------------------------------------------------
//
//  © 2024-2025 1024jp
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

extension LabeledContent where Label == Text, Content == _OptionalContent {
    
    /// Creates a labeled informational view showing “–” if the value is `nil`.
    ///
    /// - Parameters:
    ///   - title: A string that describes the purpose of the view.
    ///   - value: The optional value being labeled.
    init(_ title: some StringProtocol, optional value: String?) {
        
        self.init(title) {
            _OptionalContent(value: value)
        }
    }
}


struct _OptionalContent: View {
    
    var value: String?
    
    
    var body: some View {
        
        if let value {
            Text(value)
                .textSelection(.enabled)
        } else {
            Text.none
        }
    }
}


extension Text {
    
    static var none: Text {
        
        Text(verbatim: "–")
            .accessibilityLabel(String(localized: "None", comment: "accessibility label for “–”"))
            .foregroundStyle(.tertiary)
    }
}


// MARK: - Preview

#Preview {
    Form {
        LabeledContent("Value:", optional: 1024.formatted())
        LabeledContent("None:", optional: nil)
    }
    .formStyle(.columns)
    .scenePadding()
}
