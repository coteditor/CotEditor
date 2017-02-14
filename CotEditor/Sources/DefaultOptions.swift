/*
 
 DefaultOptions.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2017-02-14.
 
 ------------------------------------------------------------------------------
 
 © 2017 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 https://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import AppKit

enum DocumentConflictOption: Int {
    
    case ignore
    case notify
    case revert
}


@objc enum PrintColorMode: Int {
    
    case blackWhite
    case sameAsDocument
}


@objc enum PrintLineNmuberMode: Int {
    
    case no
    case sameAsDocument
    case yes
}


@objc enum PrintInvisiblesMode: Int {
    
    case no
    case sameAsDocument
    case all
}


@objc enum PrintInfoType: Int {
    
    case none
    case syntaxName
    case documentName
    case filePath
    case printDate
    case pageNumber
    
    
    init(_ rawValue: Int?) {
        
        self = PrintInfoType(rawValue: rawValue ?? 0) ?? .none
    }
}


@objc enum AlignmentType: Int {
    
    case left
    case center
    case right
    
    
    init(_ rawValue: Int?) {
        
        self = AlignmentType(rawValue: rawValue ?? 0) ?? .right
    }
    
    
    var textAlignment: NSTextAlignment {
        
        switch self {
        case .left:
            return .left
        case .center:
            return .center
        case .right:
            return .right
        }
    }
}
