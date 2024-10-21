//
//  FileEncoding.swift
//  FileEncoding
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2020-08-07.
//
//  ---------------------------------------------------------------------------
//
//  © 2020-2024 1024jp
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

public struct FileEncoding: Equatable, Hashable, Sendable {
    
    public static let utf8 = FileEncoding(encoding: .utf8)
    
    public var encoding: String.Encoding
    public var withUTF8BOM: Bool = false
    
    
    public init(encoding: String.Encoding, withUTF8BOM: Bool = false) {
        
        assert(encoding == .utf8 || !withUTF8BOM)
        
        self.encoding = encoding
        self.withUTF8BOM = withUTF8BOM
    }
    
    
    /// Human-readable encoding name by taking UTF-8 BOM into consideration.
    ///
    /// The `withUTF8BOM` flag is just ignored when `encoding` is other than UTF-8.
    public var localizedName: String {
        
        let localizedName = String.localizedName(of: self.encoding)
        
        return (self.encoding == .utf8 && self.withUTF8BOM)
            ? String(localized: "\(localizedName) with BOM", bundle: .module,
                     comment: "encoding name for UTF-8 with BOM (%@ is the system localized name for UTF-8)")
            : localizedName
    }
}
