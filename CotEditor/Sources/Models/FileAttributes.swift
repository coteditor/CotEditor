//
//  FileAttributes.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-03-05.
//
//  ---------------------------------------------------------------------------
//
//  © 2018-2025 1024jp
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
import FilePermissions

extension FileAttributeKey {
    
    static let extendedAttributes = FileAttributeKey("NSFileExtendedAttributes")
}


enum FileExtendedAttributeName {
    
    static let encoding = "com.apple.TextEncoding"
    static let userTags = "com.apple.metadata:_kMDItemUserTags"
    static let verticalText = "com.coteditor.VerticalText"
    static let allowLineEndingInconsistency = "com.coteditor.AllowLineEndingInconsistency"
}


struct FileAttributes: Equatable {
    
    var creationDate: Date?
    var modificationDate: Date?
    var size: Int64
    var permissions: FilePermissions
    var owner: String?
    var tags: [FinderTag] = []
}


extension FileAttributes {
    
    init(dictionary: [FileAttributeKey: Any]) {
        
        self.creationDate = dictionary[.creationDate] as? Date
        self.modificationDate = dictionary[.modificationDate] as? Date
        self.size = dictionary[.size] as? Int64 ?? 0
        self.permissions = FilePermissions(mask: dictionary[.posixPermissions] as? Int16 ?? 0)
        self.owner = dictionary[.ownerAccountName] as? String
        self.tags = (dictionary[.extendedAttributes] as? [String: Data])?[FileExtendedAttributeName.userTags].flatMap(FinderTag.tags(data:)) ?? []
    }
}


struct ExtendedFileAttributes {
    
    var encoding: String.Encoding?
    var isVerticalText: Bool = false
    var allowsInconsistentLineEndings: Bool = false
    
    
    init(dictionary: [FileAttributeKey: Any]) {
        
        let extendedAttributes = dictionary[.extendedAttributes] as? [String: Data]
        self.encoding = extendedAttributes?[FileExtendedAttributeName.encoding]?.decodingXattrEncoding
        self.isVerticalText = (extendedAttributes?[FileExtendedAttributeName.verticalText] != nil)
        self.allowsInconsistentLineEndings = (extendedAttributes?[FileExtendedAttributeName.allowLineEndingInconsistency] != nil)
    }
}
