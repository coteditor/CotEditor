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
//  © 2016-2020 1024jp
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
    
    typealias LineRange = (location: Int, length: Int)
    
    
    // MARK: Public Properties
    
    var completionHandler: ((_ lineRange: LineRange) -> Bool)?
    
    var lineRange: LineRange? {
        
        get {
            let loclen = self.location.components(separatedBy: ":").map { Int($0) }
            
            guard
                let location = loclen[0],
                let length = (loclen.count > 1) ? loclen[1] : 0
                else { return nil }
            
            return (location: location, length: length)
        }
        
        set {
            guard let newValue = newValue else { return assertionFailure() }
            
            self.location = String(newValue.location)
            if newValue.length > 1 {
                self.location += ":" + String(newValue.length)
            }
        }
    }
    
    
    // MARK: Private Properties
    
    @objc private dynamic var location: String = ""
    
    
    
    // MARK: -
    // MARK: Action Messages
    
    /// apply
    @IBAction func apply(_ sender: Any?) {
        
        assert(self.completionHandler != nil)
        
        guard
            self.endEditing(),
            let lineRange = self.lineRange,
            self.completionHandler?(lineRange) ?? false
            else { return NSSound.beep() }
        
        self.dismiss(sender)
    }
    
}
