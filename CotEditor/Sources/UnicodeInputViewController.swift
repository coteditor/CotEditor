//
//  UnicodeInputViewController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2014-05-06.
//
//  ---------------------------------------------------------------------------
//
//  © 2014-2020 1024jp
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

import Cocoa

final class UnicodeInputViewController: NSViewController {
    
    // MARK: Public Properties
    
    var completionHandler: ((_ character: Character) -> Void)?
    
    
    // MARK: Private Properties
    
    private var character: Character?
    
    @objc private dynamic var codePoint: String = ""  { didSet { self.validateCodePoint() } }
    
    @objc private dynamic var pictureString: String?
    @objc private dynamic var unicodeName: String?
    
    
    
    // MARK: -
    // MARK: Action Messages
    
    /// Input Unicode character to the parent text view.
    @IBAction func insertToDocument(_ sender: Any?) {
        
        assert(self.completionHandler != nil)
        
        guard let character = self.character else { return NSSound.beep() }
        
        self.completionHandler?(character)
        self.codePoint = ""
    }
    
    
    
    // MARK: Private Methods
    
    private func validateCodePoint() {
        
        let longChar = UTF32.CodeUnit(codePoint: self.codePoint)
        
        self.character = longChar
            .flatMap { Unicode.Scalar($0) }
            .map { Character($0) }
        
        self.pictureString = (self.character?.isNewline == true) ? " " : self.character.map { String($0) }
        self.unicodeName = longChar?.unicodeName
    }

}



// MARK: Private Extensions

private extension UTF32.CodeUnit {
    
    /// Initialize from a possible Unicode code point representation, such as `U+1F600`, `1f600`, and `0x1F600`.
    init?(codePoint: String) {
        
        guard let range = codePoint.range(of: "(?<=^(U\\+|0x|\\\\u)?)[0-9a-f]{1,5}$",
                                          options: [.regularExpression, .caseInsensitive]) else { return nil }
        let hexString = codePoint[range]
        
        self.init(hexString, radix: 16)
    }
    
}
