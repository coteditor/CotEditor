//
//  CustomSurroundStringViewController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2017-03-19.
//
//  ---------------------------------------------------------------------------
//
//  © 2017-2022 1024jp
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

final class CustomSurroundStringViewController: NSViewController {
    
    // MARK: Private Properties
    
    private let completionHandler: (_ pair: Pair<String>) -> Void
    
    @objc private dynamic var beginString: String
    @objc private dynamic var endString: String
    
    @IBOutlet private weak var endStringField: NSTextField?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    /// Initialize view from a storyboard with given values.
    ///
    /// - Parameters:
    ///   - coder: The coder to instantiate the view from a storyboard.
    ///   - pair: A pair of strings to fill as default value.
    ///   - completionHandler: The callback method to perform when the command was accepted.
    init?(coder: NSCoder, pair: Pair<String>?, completionHandler: @escaping (_ pair: Pair<String>) -> Void) {
        
        self.completionHandler = completionHandler
        self.beginString = pair?.begin ?? UserDefaults.standard[.beginCustomSurroundString] ?? ""
        self.endString = pair?.end ?? UserDefaults.standard[.endCustomSurroundString] ?? ""
        
        super.init(coder: coder)
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: Action Messages
    
    /// apply
    @IBAction func apply(_ sender: Any?) {
        
        guard
            self.endEditing(),
            !self.beginString.isEmpty
        else { return NSSound.beep() }
        
        // use beginString also for end delimiter if endString is empty
        let endString = self.endString.isEmpty ? self.beginString : self.endString
        
        self.completionHandler(Pair(self.beginString, endString))
        
        // store last used string pair
        UserDefaults.standard[.beginCustomSurroundString] = self.beginString
        UserDefaults.standard[.endCustomSurroundString] = self.endString
        
        self.dismiss(sender)
    }
    
}



extension CustomSurroundStringViewController: NSTextFieldDelegate {
    
    /// keep setting beginString to the placeholder of endStringField
    func controlTextDidChange(_ obj: Notification) {
        
        guard let beginStringField = obj.object as? NSTextField else { return assertionFailure() }
        
        self.endStringField?.placeholderString = beginStringField.stringValue
    }
    
}
