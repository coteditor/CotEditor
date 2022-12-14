//
//  FileEncoding.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2020-08-07.
//
//  ---------------------------------------------------------------------------
//
//  © 2020-2022 1024jp
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

struct FileEncoding: Equatable {
    
    var encoding: String.Encoding
    var withUTF8BOM: Bool = false
    
    
    /// Human-readable encoding name by taking UTF-8 BOM into consideration.
    ///
    /// The `withUTF8BOM` flag is just ignored when `encoding` is other than UTF-8.
    var localizedName: String {
        
        let localizedName = String.localizedName(of: self.encoding)
        
        return (self.encoding == .utf8 && self.withUTF8BOM)
            ? String(localized: "\(localizedName) with BOM", comment: "Unicode (UTF-8) with BOM")
            : localizedName
    }
}


extension FileEncoding {
    
    init(tag: Int) {
        
        self.encoding = String.Encoding(rawValue: UInt(abs(tag)))
        self.withUTF8BOM = (self.encoding == .utf8) && (tag < 0)
    }
    
    
    var tag: Int {
        
        (self.withUTF8BOM ? -1 : 1) * Int(self.encoding.rawValue)
    }
}
