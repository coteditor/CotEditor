//
//  ExtendedFileAttributes.swift
//  EditorCore
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-05-04.
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
import FileEncoding

public extension FileAttributeKey {
    
    static let extendedAttributes = FileAttributeKey("NSFileExtendedAttributes")
}


public enum ExtendedFileAttributeName {
    
    public static let encoding = "com.apple.TextEncoding"
    public static let userTags = "com.apple.metadata:_kMDItemUserTags"
    public static let verticalText = "com.coteditor.VerticalText"
    public static let allowLineEndingInconsistency = "com.coteditor.AllowLineEndingInconsistency"
}


public struct ExtendedFileAttributes: Equatable, Sendable {
    
    public var encoding: String.Encoding?
    public var isVerticalText: Bool = false
    public var allowsInconsistentLineEndings: Bool = false
    
    
    public init(dictionary: [FileAttributeKey: Any]) {
        
        let extendedAttributes = dictionary[.extendedAttributes] as? [String: Data]
        self.encoding = extendedAttributes?[ExtendedFileAttributeName.encoding]?.decodingXattrEncoding
        self.isVerticalText = (extendedAttributes?[ExtendedFileAttributeName.verticalText] != nil)
        self.allowsInconsistentLineEndings = (extendedAttributes?[ExtendedFileAttributeName.allowLineEndingInconsistency] != nil)
    }
}
