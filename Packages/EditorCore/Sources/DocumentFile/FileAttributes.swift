//
//  FileAttributes.swift
//  DocumentFile
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-03-05.
//
//  ---------------------------------------------------------------------------
//
//  © 2018-2026 1024jp
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

public import Foundation

public struct FileAttributes: Equatable, Sendable {
    
    public var creationDate: Date?
    public var modificationDate: Date?
    public var size: Int64
    public var permissions: FilePermissions
    public var owner: String?
    public var tags: [FinderTag] = []
    
    
    public init(creationDate: Date? = nil, modificationDate: Date? = nil, size: Int64, permissions: FilePermissions, owner: String? = nil, tags: [FinderTag]) {
        
        self.creationDate = creationDate
        self.modificationDate = modificationDate
        self.size = size
        self.permissions = permissions
        self.owner = owner
        self.tags = tags
    }
}


public extension FileAttributes {
    
    init(dictionary: [FileAttributeKey: Any]) {
        
        self.creationDate = dictionary[.creationDate] as? Date
        self.modificationDate = dictionary[.modificationDate] as? Date
        self.size = dictionary[.size] as? Int64 ?? 0
        self.permissions = FilePermissions(mask: dictionary[.posixPermissions] as? Int16 ?? 0)
        self.owner = dictionary[.ownerAccountName] as? String
        self.tags = (dictionary[.extendedAttributes] as? [String: Data])?[ExtendedFileAttributeName.userTags].flatMap(FinderTag.tags(data:)) ?? []
    }
}
