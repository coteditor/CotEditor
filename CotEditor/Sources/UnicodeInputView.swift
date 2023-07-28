//
//  UnicodeInputView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2014-05-06.
//
//  ---------------------------------------------------------------------------
//
//  © 2014-2023 1024jp
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

struct UnicodeInputView: View {
    
    weak var parent: NSHostingController<Self>?
    
    let completionHandler: (_ character: Character) -> Void
    
    @State private var codePoint: String = ""
    
    
    // MARK: View
    
    var body: some View {
        
        VStack(alignment: .leading) {
            HStack(alignment: .center) {
                Text((self.character?.isNewline == true) ? " " : self.character.map(String.init) ?? "⬚")
                    .font(.system(size: 26))
                    .frame(minWidth: 30, minHeight: 30)
                
                Text(self.unicodeName ?? "Invalid code")
                    .help(self.unicodeName ?? "")
                    .controlSize(.small)
                    .textSelection(.enabled)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundColor(self.unicodeName != nil ? .label : .secondaryLabel)
            
            ZStack(alignment: .leadingFirstTextBaseline) {
                InsetTextField(text: $codePoint, prompt: "U+1F600")
                    .onSubmit(self.submit)
                    .inset(.leading, 18)
                    .monospacedDigit()
                
                Menu("") {
                    let scalars = UserDefaults.standard[.unicodeHistory]
                        .compactMap(UTF32.CodeUnit.init(codePoint:))
                        .compactMap(UnicodeScalar.init)
                    
                    Section("Recents") {
                        ForEach(scalars, id: \.self) { scalar in
                            Button {
                                self.codePoint = scalar.codePoint
                            } label: {
                                Text(scalar.codePoint.padding(toLength: 9, withPad: " ", startingAt: 0))
                                    .monospacedDigit() +
                                Text(scalar.name ?? "–")
                                    .font(.system(size: NSFont.smallSystemFontSize))
                                    .foregroundColor(.secondaryLabel)
                            }
                        }
                    }
                    
                    if !scalars.isEmpty {
                        Button("Clear Recents", role: .destructive, action: self.clearRecents)
                    }
                }
                .menuStyle(.borderlessButton)
                .frame(width: 16)
            }
        }
        .padding(10)
        .frame(width: 200)
    }
    
    
    // MARK: Private Methods
    
    private var character: Character? {
        
        UTF32.CodeUnit(codePoint: self.codePoint)
            .flatMap(Unicode.Scalar.init)
            .map(Character.init)
    }
    
    
    private var pictureString: String? {
        
        (self.character?.isNewline == true) ? " " : self.character.map(String.init) ?? ""
    }
    
    
    private var unicodeName: String? {
        
        UTF32.CodeUnit(codePoint: self.codePoint)?.unicodeName
    }
    
    
    /// Input Unicode character to the parent text view.
    private func submit() {
        
        guard let character = self.character else { return NSSound.beep() }
        
        self.completionHandler(character)
        self.codePoint = ""
        
        if let codePoint = character.unicodeScalars.first?.codePoint {
            UserDefaults.standard[.unicodeHistory].appendUnique(codePoint, maximum: 10)
        }
    }
    
    
    private func clearRecents() {
        
        UserDefaults.standard[.unicodeHistory].removeAll()
    }
}



// MARK: Private Extensions

private extension UTF32.CodeUnit {
    
    /// Initialize from a possible Unicode code point representation, such as `U+1F600`, `1f600`, and `0x1F600`.
    init?(codePoint: String) {
        
        guard let hexString = codePoint.wholeMatch(of: /(U\+|0x|\\u)?(?<number>[0-9a-f]{1,5})/.ignoresCase())?.number else { return nil }
        
        self.init(hexString, radix: 16)
    }
}



// MARK: - Preview

private extension UnicodeInputView {
    
    /// Initializer for preview.
    init(codePoint: String) {
        
        self._codePoint = State(initialValue: codePoint)
        self.completionHandler = { _ in }
    }
}


#Preview("Empty") {
    UnicodeInputView(codePoint: "")
}

#Preview("𓆏") {
    UnicodeInputView(codePoint: "U+1318F")
}
