//
//  GoToLineViewController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-06-07.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2022 1024jp
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

final class GoToLineViewController: NSViewController {
    
    // MARK: Private Properties
    
    private let completionHandler: (_ lineRange: FuzzyRange) -> Bool
    
    @objc private dynamic var location: String
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    /// Initialize view from a storyboard with given values.
    ///
    /// - Parameters:
    ///   - coder: The coder to instantiate the view from a storyboard.
    ///   - lineRange: The current line range.
    ///   - completionHandler: The callback method to perform when the command was accepted.
    init?(coder: NSCoder, lineRange: FuzzyRange, completionHandler: @escaping (_ lineRange: FuzzyRange) -> Bool) {
        
        self.completionHandler = completionHandler
        self.location = lineRange.string
        
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
            let lineRange = FuzzyRange(string: self.location),
            self.completionHandler(lineRange)
        else { return NSSound.beep() }
        
        self.dismiss(sender)
    }
    
}
