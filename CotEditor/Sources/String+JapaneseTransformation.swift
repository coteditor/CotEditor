//
//  String+JapaneseTransform.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2014-07-31.
//
//  ---------------------------------------------------------------------------
//
//  © 2014-2018 1024jp
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

import Foundation

extension String {
    
    // MARK: Public Properties
    
    /// transform half-width roman to full-width
    var fullWidthRoman: String {
        
        return self.unicodeScalars.lazy
            .map { scalar -> UnicodeScalar in
                guard CharacterSet.fullWidthAvailables.contains(scalar) else { return scalar }
                
                return UnicodeScalar(scalar.value + UnicodeScalar.characterWidthDistance)!
            }
            .map { String($0) }
            .joined()
    }
    
    
    /// transform full-width roman to half-width
    var halfWidthRoman: String {
        
        return self.unicodeScalars.lazy
            .map { scalar -> UnicodeScalar in
                guard CharacterSet.fullWidths.contains(scalar) else { return scalar }
                
                return UnicodeScalar(scalar.value - UnicodeScalar.characterWidthDistance)!
            }
            .map { String($0) }
            .joined()
    }
    
}


// MARK: - Private Extensions

private extension CharacterSet {
    
    static let fullWidths = CharacterSet(charactersIn: "！"..."～")
    static let fullWidthAvailables = CharacterSet(charactersIn: "!"..."~")
}


private extension UnicodeScalar {
    
    static let characterWidthDistance = UnicodeScalar("！").value - UnicodeScalar("!").value
}
