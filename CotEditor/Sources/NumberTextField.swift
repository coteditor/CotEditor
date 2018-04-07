//
//  NumberTextField.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-03-23.
//
//  ---------------------------------------------------------------------------
//
//  © 2018 1024jp
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

final class NumberTextField: NSTextField {
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        if let monospacedDigit = self.font?.monospacedDigit {
            self.font = monospacedDigit
        }
    }
    
}



private extension NSFont {
    
    var monospacedDigit: NSFont? {
        
        let monospaceSetting: [NSFontDescriptor.FeatureKey: Any] = [.typeIdentifier: kNumberSpacingType,
                                                                    .selectorIdentifier: kMonospacedNumbersSelector]
            .mapValues { $0 as AnyObject }
        let fontDescriptor = self.fontDescriptor.addingAttributes([.featureSettings: [monospaceSetting]])
        
        return NSFont(descriptor: fontDescriptor, size: self.pointSize)
    }
    
}
